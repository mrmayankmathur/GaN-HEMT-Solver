from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import matlab.engine
import uvicorn

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("🚀 Starting MATLAB Engine...")
eng = matlab.engine.start_matlab()

# MATLAB Project Path
project_path = r'/Users/mayankmathur/Desktop/Mayanks Projects/hemt-solver-ui/multi_layer_ganquila'
eng.addpath(project_path, nargout=0)
print(f"✅ Path Linked: {project_path}")

# Layer class
class LayerInput(BaseModel):
    material: str
    alFraction: float
    thickness: float
    ndVal: float

class SimulationRequest(BaseModel):
    layers: List[LayerInput]
    pinningPotential: float = 1.7


@app.post("/simulate")
async def simulate(req: SimulationRequest):
    try:
        formatted = [
            {
                "Al_x": float(l.alFraction),
                "thickness": float(l.thickness * 10),
                "Nd_val": float(l.ndVal),
                "N_trap": 0.0
            } for l in req.layers
        ]

        # Unpack 6 variables (z, ec, ev, n, ns, slope) from MATLAB function
        z, ec, ev, n, ns, slope = eng.Run_GaN_sim(formatted, req.pinningPotential, nargout=6)

        def to_list(ml_array):
            try:
                return list(ml_array[0])
            except:
                return list(ml_array)

        return {
            "z": to_list(z),
            "ec": to_list(ec),
            "ev": to_list(ev),
            "n": to_list(n),
            "ns": float(ns),
            "slope": float(slope)
        }
    except Exception as e:
        print(f"❌ Backend Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)