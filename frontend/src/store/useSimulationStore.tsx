import { create } from "zustand";

export interface SimulationResult {
  z: number[];
  ec: number[];
  ev: number[];
  n: number[];
  ns: number;
  slope: number;
  isRunning: boolean;
}

export interface Layer {
  id: string;
  name: string;
  material: string;
  alFraction: number;
  thickness: number; // nm
  ndVal: number; // cm^-3
  naVal: number; // cm^-3
}

interface SimulationState {
  theme: "light" | "dark";
  layers: Layer[];
  selectedLayerId: string;
  results: SimulationResult | null;

  // Solver Controls
  gridSpacing: number;
  numSubbands: number;
  dampingFactor: number;
  maxIterations: number;
  pinningPotential: number;

  // Actions
  toggleTheme: () => void;
  setSelectedLayer: (id: string) => void;
  updateLayer: (id: string, updates: Partial<Layer>) => void;
  addLayer: () => void;
  removeLayer: (id: string) => void;
  runSimulation: () => Promise<void>;
  setPinningPotential: (val: number) => void;
}

const initialLayers: Layer[] = [
  {
    id: "1",
    name: "GaN cap",
    material: "GaN",
    alFraction: 0,
    thickness: 3,
    ndVal: 1e15,
    naVal: 0,
  },
  {
    id: "2",
    name: "AlGaN barrier",
    material: "AlGaN",
    alFraction: 0.25,
    thickness: 25,
    ndVal: 1e15,
    naVal: 0,
  },
  {
    id: "3",
    name: "AlN interlayer",
    material: "AlN",
    alFraction: 1.0,
    thickness: 1,
    ndVal: 1e15,
    naVal: 0,
  },
  {
    id: "4",
    name: "GaN buffer",
    material: "GaN",
    alFraction: 0,
    thickness: 100,
    ndVal: 1e15,
    naVal: 0,
  },
];

export const useSimulationStore = create<SimulationState>((set, get) => ({
  theme: "dark",
  layers: initialLayers,
  selectedLayerId: "2",
  results: null,

  gridSpacing: 2.5,
  numSubbands: 10,
  dampingFactor: 0.1,
  maxIterations: 100,
  pinningPotential: 1.7,

  toggleTheme: () =>
    set((state) => ({ theme: state.theme === "light" ? "dark" : "light" })),

  setPinningPotential: (val: number) => set({ pinningPotential: val }),

  setSelectedLayer: (id) => set({ selectedLayerId: id }),

  updateLayer: (id, updates) =>
    set((state) => ({
      layers: state.layers.map((l) => (l.id === id ? { ...l, ...updates } : l)),
    })),

  addLayer: () =>
    set((state) => {
      const newId = Math.random().toString(36).substr(2, 9);
      return {
        layers: [
          ...state.layers,
          {
            id: newId,
            name: "New Layer",
            material: "GaN",
            alFraction: 0,
            thickness: 10,
            ndVal: 1e15,
            naVal: 0,
          },
        ],
      };
    }),

  removeLayer: (id) =>
    set((state) => ({ layers: state.layers.filter((l) => l.id !== id) })),

  runSimulation: async () => {
    set((state) => ({
      results: state.results
        ? { ...state.results, isRunning: true }
        : { z: [], ec: [], ev: [], n: [], ns: 0, slope: 0, isRunning: true },
    }));

    try {
      const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8001";
      console.log("📡 Simulation API URL:", API_URL);

      // Step 1: Start the simulation — returns a job_id immediately
      const startResponse = await fetch(`${API_URL}/simulate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          layers: get().layers,
          pinningPotential: get().pinningPotential,
        }),
      });

      if (!startResponse.ok) {
        const errBody = await startResponse.text().catch(() => "");
        throw new Error(
          `Server responded with ${startResponse.status}: ${errBody}`,
        );
      }

      const { job_id } = await startResponse.json();
      console.log(`📋 Job started: ${job_id}`);

      // Step 2: Poll for results every 3 seconds
      const POLL_INTERVAL = 3000;
      const MAX_POLLS = 200; // ~10 minutes max wait

      for (let i = 0; i < MAX_POLLS; i++) {
        await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL));

        const pollResponse = await fetch(`${API_URL}/result/${job_id}`);

        if (!pollResponse.ok) {
          if (pollResponse.status === 404) {
            throw new Error("Job not found on server. It may have expired.");
          }
          const errBody = await pollResponse.text().catch(() => "");
          throw new Error(`Server error ${pollResponse.status}: ${errBody}`);
        }

        const data = await pollResponse.json();

        if (data.status === "pending") {
          console.log(`⏳ Poll ${i + 1}: still running...`);
          continue;
        }

        // Simulation complete!
        console.log("✅ Simulation complete!");
        set({
          results: {
            z: data.z,
            ec: data.ec,
            ev: data.ev,
            n: data.n,
            ns: data.ns,
            slope: data.slope,
            isRunning: false,
          },
        });
        return;
      }

      throw new Error(
        "Simulation timed out after 10 minutes. Please try again.",
      );
    } catch (error: unknown) {
      const msg =
        error instanceof Error ? error.message : "Unknown error occurred";
      console.error("❌ Simulation failed:", msg);
      alert(`Simulation failed: ${msg}`);
      set({ results: null });
    }
  },
}));
