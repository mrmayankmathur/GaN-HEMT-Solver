from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any
import os
import uvicorn
import uuid
import traceback
import time

# Use oct2py instead of matlab.engine
from oct2py import octave

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("🚀 Starting GNU Octave Engine...")
# Link to the MATLAB (.m) folder dynamically
project_path = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "multi_layer_ganquila")
)

try:
    octave.addpath(project_path)
    print(f"✅ Octave Path Linked: {project_path}")
except Exception as e:
    print(
        f"⚠️ Warning: Could not link path {project_path}. Make sure it exists! Error: {e}"
    )


# --- In-memory job store ---
# Each job: { "status": "pending"|"complete"|"error", "result": {...}|None, "error": str|None }
jobs: Dict[str, Dict[str, Any]] = {}


# Layer class
class LayerInput(BaseModel):
    material: str
    alFraction: float
    thickness: float
    ndVal: float


def to_list(arr):
    """Convert oct2py numpy arrays to flat Python lists."""
    if hasattr(arr, "tolist"):
        val = arr.tolist()
        # If it's a 2D array like [[1, 2, 3]], flatten to [1, 2, 3]
        if isinstance(val, list) and len(val) == 1 and isinstance(val[0], list):
            return val[0]
        return val
    try:
        return list(arr[0])
    except Exception:
        return list(arr)


class SimulationRequest(BaseModel):
    layers: List[LayerInput]
    pinningPotential: float = 1.7
    gridSpacing: float = 2.5
    maxIterations: int = 100


class ConvergenceRequest(BaseModel):
    layers: List[LayerInput]
    pinningPotential: float = 1.7
    maxIterations: int = 100
    gridSpacings: List[float]        # Angstroms, e.g. [5, 4, 3, 2.5, 2, 1.5, 1]
    tolerance: float = 1.0           # percent, used by the frontend for flagging


# Subbands solved per run — kept in sync with Run_GaN_sim.m (num_subbands = 10)
NUM_SUBBANDS = 10

def _run_simulation(job_id: str, formatted: list, phi_b: float, grid_spacing: float, max_iter: int):
    """
    Run the Octave simulation synchronously.
    FastAPI's BackgroundTasks runs sync functions in a thread pool via anyio,
    so this won't block the event loop and HTTP responses keep flowing.
    We reuse the global `octave` instance (created at module import) instead of
    spawning a new Oct2Py — this avoids crashes from pexpect/signal handler
    conflicts in threads.
    """
    try:
        print(f"🔬 [{job_id}] Simulation started...")

        # Use the global octave instance — safe because we run one sim at a time
        z, ec, ev, n, ns, slope, iterations_used = octave.Run_GaN_sim(formatted, phi_b, grid_spacing, max_iter, nout=7)

        result = {
            "z": to_list(z),
            "ec": to_list(ec),
            "ev": to_list(ev),
            "n": to_list(n),
            "ns": float(ns),
            "slope": float(slope) if slope is not None else 0.0,
            "iterations_used": int(iterations_used) if iterations_used is not None else max_iter,
        }
        jobs[job_id] = {"status": "complete", "result": result, "error": None}
        print(f"✅ [{job_id}] Simulation complete!")

    except Exception as e:
        error_msg = f"{e}\n{traceback.format_exc()}"
        print(f"❌ [{job_id}] Simulation failed: {error_msg}")
        jobs[job_id] = {"status": "error", "result": None, "error": str(e)}


def _estimate_memory_mb(nodes: int) -> float:
    """
    Rough memory estimate (MB) for a single solve, derived from node count.
    This is an ESTIMATE, not the true process RSS: a warm, shared Octave
    instance can't report a meaningful per-run footprint. We size it from the
    dominant dense allocation (eigenvectors: nodes x num_subbands doubles)
    plus the sparse Poisson/Schrodinger operators (~O(nodes) nonzeros).
    """
    eigvecs = nodes * NUM_SUBBANDS * 8          # dense psi matrix
    sparse_ops = nodes * 5 * 8                   # tridiagonal-ish operators
    return round((eigvecs + sparse_ops) / 1e6, 4)


def _run_convergence(job_id: str, formatted: list, phi_b: float, grid_spacings: list, max_iter: int):
    """
    Mesh / grid-independence sweep: run Run_GaN_sim once per grid spacing,
    coarse -> fine, recording per-mesh metrics and curves. Reuses the global
    warm `octave` instance (one solve at a time), and updates `progress` so the
    frontend can render a live progress bar.
    """
    # Coarse -> fine so the convergence chart reads left (coarse) to right (fine)
    spacings = sorted(grid_spacings, reverse=True)
    jobs[job_id] = {
        "status": "pending",
        "runs": [],
        "progress": 0,
        "total": len(spacings),
        "error": None,
    }

    try:
        print(f"📐 [{job_id}] Convergence study started for spacings {spacings}...")

        for dz in spacings:
            t0 = time.perf_counter()
            z, ec, ev, n, ns, slope, iterations_used = octave.Run_GaN_sim(
                formatted, phi_b, float(dz), max_iter, nout=7
            )
            runtime = time.perf_counter() - t0

            z_list = to_list(z)
            nodes = len(z_list)

            jobs[job_id]["runs"].append({
                "gridSpacing": float(dz),
                "nodes": nodes,
                "ns": float(ns),
                "field": float(slope) if slope is not None else 0.0,
                "iterations": int(iterations_used) if iterations_used is not None else max_iter,
                "runtime": round(runtime, 4),
                "memoryMb": _estimate_memory_mb(nodes),
                "z": z_list,
                "ec": to_list(ec),
                "ev": to_list(ev),
                "n": to_list(n),
            })
            jobs[job_id]["progress"] += 1
            print(f"   [{job_id}] dz={dz} Å → {nodes} nodes, ns={float(ns):.3e}, {runtime:.2f}s "
                  f"({jobs[job_id]['progress']}/{jobs[job_id]['total']})")

        jobs[job_id]["status"] = "complete"
        print(f"✅ [{job_id}] Convergence study complete!")

    except Exception as e:
        error_msg = f"{e}\n{traceback.format_exc()}"
        print(f"❌ [{job_id}] Convergence study failed: {error_msg}")
        jobs[job_id] = {"status": "error", "runs": None, "error": str(e)}


@app.post("/simulate")
def simulate(req: SimulationRequest, background_tasks: BackgroundTasks):
    """Start simulation as a background task and return a job ID immediately."""
    formatted = [
        {
            "Al_x": float(l.alFraction),
            "thickness": float(l.thickness * 10),
            "Nd_val": float(l.ndVal),
            "N_trap": 0.0,
        }
        for l in req.layers
    ]

    job_id = str(uuid.uuid4())
    jobs[job_id] = {"status": "pending", "result": None, "error": None}

    # FastAPI BackgroundTasks runs sync functions in a thread pool automatically
    background_tasks.add_task(_run_simulation, job_id, formatted, req.pinningPotential, req.gridSpacing, req.maxIterations)

    print(f"📋 Job {job_id} queued, active jobs: {list(jobs.keys())}")
    return {"job_id": job_id}


@app.get("/result/{job_id}")
def get_result(job_id: str):
    """Poll this endpoint to check if the simulation is done."""
    print(f"🔍 Polling job {job_id}, active jobs: {list(jobs.keys())}")

    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")

    job = jobs[job_id]

    if job["status"] == "pending":
        return {"status": "pending"}
    elif job["status"] == "complete":
        # Clean up the job from memory after returning results
        result = job["result"]
        del jobs[job_id]
        return {"status": "complete", **result}
    else:
        error_msg = job["error"]
        del jobs[job_id]
        raise HTTPException(status_code=500, detail=error_msg)


@app.post("/convergence")
def convergence(req: ConvergenceRequest, background_tasks: BackgroundTasks):
    """Start a grid-spacing sweep as a background task and return a job ID."""
    formatted = [
        {
            "Al_x": float(l.alFraction),
            "thickness": float(l.thickness * 10),
            "Nd_val": float(l.ndVal),
            "N_trap": 0.0,
        }
        for l in req.layers
    ]

    job_id = str(uuid.uuid4())
    jobs[job_id] = {"status": "pending", "runs": [], "progress": 0, "total": len(req.gridSpacings), "error": None}

    background_tasks.add_task(
        _run_convergence, job_id, formatted, req.pinningPotential, req.gridSpacings, req.maxIterations
    )

    print(f"📋 Convergence job {job_id} queued ({len(req.gridSpacings)} meshes)")
    return {"job_id": job_id}


@app.get("/convergence_result/{job_id}")
def get_convergence_result(job_id: str):
    """Poll this endpoint to track sweep progress and retrieve results when done."""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")

    job = jobs[job_id]

    if job["status"] == "pending":
        return {"status": "pending", "progress": job.get("progress", 0), "total": job.get("total", 0)}
    elif job["status"] == "complete":
        runs = job["runs"]
        del jobs[job_id]
        return {"status": "complete", "runs": runs}
    else:
        error_msg = job["error"]
        del jobs[job_id]
        raise HTTPException(status_code=500, detail=error_msg)


@app.get("/health")
def health():
    """Health check — also shows active job count for debugging."""
    return {"status": "ok", "active_jobs": len(jobs)}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8001))
    uvicorn.run(app, host="0.0.0.0", port=port)
