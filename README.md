# GaN HEMT Solver 

A comprehensive and visually rich web application built to simulate, visualize, and analyze the electrostatic and quantum-mechanical behaviors of **AlGaN/GaN High Electron Mobility Transistors (HEMTs)**.

This solver computes the **Self-Consistent Schrödinger-Poisson equation** across any defined epitaxial layer stack to output precise Energy Band Diagrams (EBD), 2D Electron Gas (2DEG) densities, and layer internal electric fields.

---

title: GaN HEMT Simulation App
emoji: ⚡
colorFrom: blue
colorTo: indigo
sdk: docker
pinned: false
---

## Features

- **Interactive Layer Stack Editor**: Define any stack of epitaxial layers including materials (GaN, AlGaN, AlN), thicknesses, aluminum fractions, and doping concentrations.
- **Solver Controls**: Take control over physical grid spacing, subbands count, convergence iterations, and pinning potentials.
- **Accurate Numerics**: Fully supports built-in strain/piezoelectric calculation and multi-junction polarization spikes logic behind-the-scenes.
- **Rich Data Visualizations**: Fast, interactive graphs constructed over Plotly that plot energy profiles (Ec, Ev, Ef) and density curves.
- **Local Metrics Computation**: Select a localized region across the rendered chart using intuitive slider markers/text overlays to immediately read the isolated Sheet Density and Average Field slope for that region dynamically.
- **Flexible UI/UX**: Includes Light/Dark theme switching, tabbed sliding chart views (via Framer Motion), discrete chart Pop-outs for maximum real estate, and rapid CSV/PNG exporting functionality!

---

## Architecture & Tech Stack

This solver is built on a heavily decoupled Full-Stack architecture allowing complex computational numerical methods to bind frictionlessly to the modern web.

### **Frontend** (UI/UX Environment)
The visualization client built for the browser. Keeps local states completely decoupled from back-end logic.
* **React 19 + TypeScript**: For strict-typed component management.
* **Vite**: Ultra-fast build execution and development serving.
* **Zustand**: Stores temporary state inputs and simulation outputs (`ec`, `n`, `z`), bound tightly wrapping `localStorage` persistence.
* **TailwindCSS**: Pure utility classes handling all responsiveness, glass-morphism, and color profiles.
* **Framer Motion**: Smooth DOM layout transitions without heavy rendering jitter.
* **Plotly / react-plotly.js**: Handles fast rendering for 1D graph mappings and interactions.

### **Backend** (API & Simulation Execution)
Responsible for passing layout topologies from the browser into numerical simulation instances asynchronously.
* **Python + FastAPI**: Asynchronous REST service exposing `/simulate` and polling bounds to the frontend without blocking main threads.
* **oct2py**: Maps and bridges Python dictionaries/data arrays strictly to a native GNU Octave engine environment.
* **GNU Octave (`Run_GaN_sim.m`)**: The mathematical workhorse of the application. It natively translates physical parameters (piezoelectric tensors, effective mass loops, trapezoidal densities) executing standard `1D Schrödinger-Poisson` finite difference loops iteratively.

---

## Running Locally

You'll need `Node.js`, `Python 3.10+`, and `GNU Octave` installed on your host machine to run this project natively.

### 1. Setup Backend
Open a terminal in the root directory and build the Python backend:

```bash
# Navigate to the backend directory
cd backend_hf

# Setup a virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies (FastAPI, oct2py, uvicorn)
pip install -r requirements.txt

# Start the python API server (Defaults to Port 8001)
uvicorn main:app --reload --port 8001
```

### 2. Setup Frontend
In a new terminal window, boot up the React application:

```bash
# Navigate to the frontend directory
cd frontend

# Install package dependencies
npm install

# Start the Vite development server
npm run dev
```

The application will be accessible at your specific `localhost` port (usually `http://localhost:5173`) in your browser. Changing any data will transparently trigger REST calls communicating directly back to the Python-Octave bridge.

---

> *This README provides general setup guidelines. Specific device parameters and modeling constants inherent to proprietary analysis loops are securely contained and managed natively within the private module functions.*
