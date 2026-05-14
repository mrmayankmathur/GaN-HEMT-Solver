from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import os
import uvicorn
import numpy as np

# Use oct2py instead of matlab.engine
from oct2py import octave

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    # Allow all origins for easier cloud deployment, or specify your frontend's Vercel URL here later
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("🚀 Starting GNU Octave Engine...")
# Link to the MATLAB (.m) folder dynamically
# This resolves to ../multi_layer_ganquila relative to this file
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


# Layer class
class LayerInput(BaseModel):
    material: str
    alFraction: float
    thickness: float
    ndVal: float


@app.post("/simulate")
async def simulate(layers: List[LayerInput]):
    try:
        formatted = [
            {
                "Al_x": float(l.alFraction),
                "thickness": float(l.thickness * 10),
                "Nd_val": float(l.ndVal),
                "N_trap": 0.0,
            }
            for l in layers
        ]

        # Call the Octave/MATLAB function
        # Note: oct2py uses 'nout' instead of 'nargout'
        z, ec, ev, n, ns = octave.Run_GaN_sim(formatted, nout=5)

        # oct2py returns numpy arrays, we convert them to flat lists
        def to_list(arr):
            if hasattr(arr, "tolist"):
                val = arr.tolist()
                # If it's a 2D array like [[1, 2, 3]], flatten to [1, 2, 3]
                if isinstance(val, list) and len(val) == 1 and isinstance(val[0], list):
                    return val[0]
                return val
            try:
                return list(arr[0])
            except:
                return list(arr)

        return {
            "z": to_list(z),
            "ec": to_list(ec),
            "ev": to_list(ev),
            "n": to_list(n),
            "ns": float(ns),
        }
    except Exception as e:
        print(f"❌ Backend Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8001))
    uvicorn.run(app, host="0.0.0.0", port=port)
