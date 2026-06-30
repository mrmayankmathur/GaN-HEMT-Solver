from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Dict, Any
from pathlib import Path
import os
import uvicorn
import uuid
import traceback
import threading
import time

# Use oct2py instead of matlab.engine
from oct2py import octave

app = FastAPI()

# noinspection PyTypeChecker
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("🚀 Starting GNU Octave Engine...")

# Use modern pathlib for type-safe path resolution
project_path = Path(__file__).resolve().parent.parent / "multi_layer_ganquila"

try:
    octave.addpath(str(project_path))
    print(f"✅ Octave Path Linked: {project_path}")
except Exception as init_err:
    print(
        f"⚠️ Warning: Could not link path {project_path}. Make sure it exists! Error: {init_err}"
    )


# --- Thread Safety Locks ---
# Locks Octave engine to prevent concurrent process I/O crashes (Reentrant)
octave_lock = threading.RLock()
# Locks job dictionary to prevent race conditions on progress updates and reads (Reentrant)
jobs_lock = threading.RLock()

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
    absTolerance: float = Field(default=1e-6, gt=0, le=1.0)
    relTolerance: float = Field(default=1e-4, gt=0, le=1.0)


class ConvergenceRequest(BaseModel):
    layers: List[LayerInput]
    pinningPotential: float = 1.7
    maxIterations: int = 100
    gridSpacings: List[float]        # Angstroms, e.g. [5, 4, 3, 2.5, 2, 1.5, 1]
    tolerance: float = 1.0           # percent, used by the frontend for flagging
    absTolerance: float = Field(default=1e-6, gt=0, le=1.0)
    relTolerance: float = Field(default=1e-4, gt=0, le=1.0)


# Subbands solved per run — kept in sync with Run_GaN_sim.m (num_subbands = 10)
NUM_SUBBANDS = 10

def _run_simulation(job_id: str, formatted: list, phi_b: float, grid_spacing: float, max_iter: int, abs_tol: float, rel_tol: float):
    """
    Run the Octave simulation synchronously.
    FastAPI's BackgroundTasks runs sync functions in a thread pool via anyio,
    so this won't block the event loop and HTTP responses keep flowing.
    We reuse the global `octave` instance safely via `octave_lock`.
    """
    try:
        print(f"🔬 [{job_id}] Simulation started...")

        # Guard the shared Octave instance
        with octave_lock:
            z, ec, ev, n, ns, slope, iterations_used, final_abs_err, final_rel_err, converged = octave.Run_GaN_sim(formatted, phi_b, grid_spacing, max_iter, abs_tol, rel_tol, nout=10)

        result = {
            "z": to_list(z),
            "ec": to_list(ec),
            "ev": to_list(ev),
            "n": to_list(n),
            "ns": float(ns),
            "slope": float(slope) if slope is not None else 0.0,
            "iterations_used": int(iterations_used) if iterations_used is not None else max_iter,
            "final_abs_err": float(final_abs_err) if final_abs_err is not None else 0.0,
            "final_rel_err": float(final_rel_err) if final_rel_err is not None else 0.0,
            "converged": bool(converged),
        }

        with jobs_lock:
            if job_id not in jobs:
                print(f"⚠️ [{job_id}] Simulation finished, but job was deleted. Discarding result.")
                return

            job = jobs[job_id]
            job["status"] = "complete"
            job["result"] = result
            job["error"] = None

        print(f"✅ [{job_id}] Simulation complete!")

    except Exception as sim_err:
        error_msg = f"{sim_err}\n{traceback.format_exc()}"
        print(f"❌ [{job_id}] Simulation failed: {error_msg}")
        with jobs_lock:
            if job_id in jobs:
                job = jobs[job_id]
                job["status"] = "error"
                job["result"] = None
                job["error"] = str(sim_err)


def _estimate_memory_mb(nodes: int) -> float:
    """
    Rough memory estimate (MB) for a single solve, derived from node count.
    """
    eigenvectors = nodes * NUM_SUBBANDS * 8          # dense psi matrix
    sparse_ops = nodes * 5 * 8                       # tridiagonal-ish operators
    return round((eigenvectors + sparse_ops) / 1e6, 4)


def _run_convergence(job_id: str, formatted: list, phi_b: float, grid_spacings: list, max_iter: int, abs_tol: float, rel_tol: float):
    """
    Mesh / grid-independence sweep: run Run_GaN_sim once per grid spacing.
    Safely utilizes `octave_lock` for the engine and `jobs_lock` for progress updates.
    """
    spacings = sorted(grid_spacings, reverse=True)

    try:
        print(f"📐 [{job_id}] Convergence study started for spacings {spacings}...")

        for dz in spacings:
            # Check if job was cancelled before starting a new heavy mesh
            with jobs_lock:
                if job_id not in jobs:
                    print(f"⚠️ [{job_id}] Convergence job deleted mid-run. Aborting remaining meshes.")
                    return

            t0 = time.perf_counter()

            # Guard the shared Octave instance per iteration
            with octave_lock:
                z, ec, ev, n, ns, slope, iterations_used, final_abs_err, final_rel_err, converged = octave.Run_GaN_sim(
                    formatted, phi_b, float(dz), max_iter, abs_tol, rel_tol, nout=10
                )

            runtime = time.perf_counter() - t0

            z_list = to_list(z)
            nodes = len(z_list)

            # Guard job dictionary mutation
            with jobs_lock:
                if job_id not in jobs:
                    print(f"⚠️ [{job_id}] Convergence job deleted mid-run. Aborting remaining meshes.")
                    return

                job = jobs[job_id]
                job["runs"].append({
                    "gridSpacing": float(dz),
                    "nodes": nodes,
                    "ns": float(ns),
                    "field": float(slope) if slope is not None else 0.0,
                    "iterations": int(iterations_used) if iterations_used is not None else max_iter,
                    "final_abs_err": float(final_abs_err) if final_abs_err is not None else 0.0,
                    "final_rel_err": float(final_rel_err) if final_rel_err is not None else 0.0,
                    "converged": bool(converged),
                    "runtime": round(runtime, 4),
                    "memoryMb": _estimate_memory_mb(nodes),
                    "z": z_list,
                    "ec": to_list(ec),
                    "ev": to_list(ev),
                    "n": to_list(n),
                })
                job["progress"] += 1

                current_progress = job["progress"]
                total_progress = job["total"]

            print(f"   [{job_id}] dz={dz} Å → {nodes} nodes, ns={float(ns):.3e}, {runtime:.2f}s "
                  f"({current_progress}/{total_progress})")

        with jobs_lock:
            if job_id in jobs:
                jobs[job_id]["status"] = "complete"

        print(f"✅ [{job_id}] Convergence study complete!")

    except Exception as conv_err:
        error_msg = f"{conv_err}\n{traceback.format_exc()}"
        print(f"❌ [{job_id}] Convergence study failed: {error_msg}")
        with jobs_lock:
            if job_id in jobs:
                job = jobs[job_id]
                job["status"] = "error"
                job["runs"] = None
                job["error"] = str(conv_err)


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

    with jobs_lock:
        jobs[job_id] = {"status": "pending", "result": None, "error": None}
        active_job_count = len(jobs)

    background_tasks.add_task(_run_simulation, job_id, formatted, req.pinningPotential, req.gridSpacing, req.maxIterations, req.absTolerance, req.relTolerance)

    print(f"📋 Job {job_id} queued, active jobs: {active_job_count}")
    return {"job_id": job_id}


@app.get("/result/{job_id}")
def get_result(job_id: str):
    """Poll this endpoint to check if the simulation is done."""
    response: Dict[str, Any]

    with jobs_lock:
        if job_id not in jobs:
            response = {"status": "not_found"}
        else:
            job = jobs[job_id]
            if job["status"] == "pending":
                response = {"status": "pending"}
            elif job["status"] == "complete":
                result = job["result"]
                del jobs[job_id]
                response = {"status": "complete", **result}
            else:
                error_msg = job["error"]
                del jobs[job_id]
                response = {"status": "error", "detail": error_msg}

    # Handle HTTP Exceptions entirely outside the lock
    if response.get("status") == "not_found":
        raise HTTPException(status_code=404, detail="Job not found")
    if response.get("status") == "error":
        raise HTTPException(status_code=500, detail=response["detail"])

    return response


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

    with jobs_lock:
        jobs[job_id] = {"status": "pending", "runs": [], "progress": 0, "total": len(req.gridSpacings), "error": None}

    background_tasks.add_task(
        _run_convergence, job_id, formatted, req.pinningPotential, req.gridSpacings, req.maxIterations, req.absTolerance, req.relTolerance
    )

    print(f"📋 Convergence job {job_id} queued ({len(req.gridSpacings)} meshes)")
    return {"job_id": job_id}


@app.get("/convergence_result/{job_id}")
def get_convergence_result(job_id: str):
    """Poll this endpoint to track sweep progress and retrieve results when done."""
    response: Dict[str, Any]

    with jobs_lock:
        if job_id not in jobs:
            response = {"status": "not_found"}
        else:
            job = jobs[job_id]
            if job["status"] == "pending":
                response = {"status": "pending", "progress": job.get("progress", 0), "total": job.get("total", 0)}
            elif job["status"] == "complete":
                runs = job["runs"]
                del jobs[job_id]
                response = {"status": "complete", "runs": runs}
            else:
                error_msg = job["error"]
                del jobs[job_id]
                response = {"status": "error", "detail": error_msg}

    # Handle HTTP Exceptions entirely outside the lock
    if response.get("status") == "not_found":
        raise HTTPException(status_code=404, detail="Job not found")
    if response.get("status") == "error":
        raise HTTPException(status_code=500, detail=response["detail"])

    return response


@app.get("/health")
def health():
    """Health check — also shows active job count for debugging."""
    with jobs_lock:
        active_jobs = len(jobs)
    return {"status": "ok", "active_jobs": active_jobs}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8001))
    uvicorn.run(app, host="0.0.0.0", port=port)