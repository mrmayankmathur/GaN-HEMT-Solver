import { create } from "zustand";

export interface SimulationResult {
  z: number[];
  ec: number[];
  ev: number[];
  n: number[];
  ns: number;
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
  pinningPotential: 1.0,

  toggleTheme: () =>
    set((state) => ({ theme: state.theme === "light" ? "dark" : "light" })),

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
        : { z: [], ec: [], ev: [], n: [], ns: 0, isRunning: true },
    }));

    try {
      const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8001";
      console.log("📡 Simulation API URL:", API_URL);
      const response = await fetch(`${API_URL}/simulate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(get().layers),
      });

      // Throw an error if the status is 4xx or 5xx
      if (!response.ok) {
        const errBody = await response.text().catch(() => "");
        throw new Error(
          `Server responded with ${response.status}: ${errBody}`
        );
      }

      const data = await response.json();
      set({ results: { ...data, isRunning: false } });
    } catch (error: unknown) {
      const msg =
        error instanceof Error ? error.message : "Unknown error occurred";
      console.error("❌ Simulation failed:", msg);
      alert(`Simulation failed: ${msg}`);
      // Reset results so the UI returns to the "Run simulation" prompt
      set({ results: null });
    }
  },
}));
