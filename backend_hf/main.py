from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any
import os
import uvicorn
import uuid
import traceback

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
        z, ec, ev, n, ns, slope = octave.Run_GaN_sim(formatted, phi_b, grid_spacing, max_iter, nout=6)

        result = {
            "z": to_list(z),
            "ec": to_list(ec),
            "ev": to_list(ev),
            "n": to_list(n),
            "ns": float(ns),
            "slope": float(slope) if slope is not None else 0.0,
        }
        jobs[job_id] = {"status": "complete", "result": result, "error": None}
        print(f"✅ [{job_id}] Simulation complete!")

    except Exception as e:
        error_msg = f"{e}\n{traceback.format_exc()}"
        print(f"❌ [{job_id}] Simulation failed: {error_msg}")
        jobs[job_id] = {"status": "error", "result": None, "error": str(e)}


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


@app.get("/health")
def health():
    """Health check — also shows active job count for debugging."""
    return {"status": "ok", "active_jobs": len(jobs)}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8001))
    uvicorn.run(app, host="0.0.0.0", port=port)
