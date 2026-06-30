import { create } from "zustand";
import { persist } from "zustand/middleware";

export interface SimulationResult {
  z: number[];
  ec: number[];
  ev: number[];
  n: number[];
  ns: number;
  slope: number;
  iterations_used: number;
  final_abs_err: number;
  final_rel_err: number;
  converged: boolean;
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

// One solve in a convergence sweep (a single grid spacing).
export interface ConvergenceRun {
  gridSpacing: number; // Å
  nodes: number;
  ns: number; // sheet density cm^-2
  field: number; // average field V/cm
  iterations: number;
  final_abs_err: number;
  final_rel_err: number;
  converged: boolean;
  runtime: number; // seconds
  memoryMb: number; // estimated
  z: number[];
  ec: number[];
  ev: number[];
  n: number[];
}

export interface ConvergenceState {
  runs: ConvergenceRun[];
  isRunning: boolean;
  progress: number;
  total: number;
}

interface SimulationState {
  theme: "light" | "dark";
  layers: Layer[];
  selectedLayerId: string;
  results: SimulationResult | null;

  // Region Selection Mode
  isRegionSelectionMode: boolean;
  ebdLimits: [number, number] | null;
  densityLimits: [number, number] | null;

  // Solver Controls
  gridSpacing: number;
  numSubbands: number;
  dampingFactor: number;
  maxIterations: number;
  pinningPotential: number;
  absTolerance: number;
  relTolerance: number;

  // Convergence Study
  convergence: ConvergenceState | null;
  convergenceGridSpacings: number[];
  convergenceTolerance: number; // percent

  // Actions
  toggleTheme: () => void;
  setSelectedLayer: (id: string) => void;
  updateLayer: (id: string, updates: Partial<Layer>) => void;
  addLayer: () => void;
  removeLayer: (id: string) => void;
  runSimulation: () => Promise<void>;
  setPinningPotential: (val: number) => void;
  setGridSpacing: (val: number) => void;
  setMaxIterations: (val: number) => void;
  setAbsTolerance: (val: number) => void;
  setRelTolerance: (val: number) => void;
  setIsRegionSelectionMode: (val: boolean) => void;
  setEbdLimits: (limits: [number, number] | null) => void;
  setDensityLimits: (limits: [number, number] | null) => void;
  setConvergenceGridSpacings: (vals: number[]) => void;
  setConvergenceTolerance: (val: number) => void;
  runConvergenceStudy: () => Promise<void>;
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

export const useSimulationStore = create<SimulationState>()(
  persist(
    (set, get) => ({
      theme: "dark",
      layers: initialLayers,
      selectedLayerId: "2",
      results: null,

      isRegionSelectionMode: false,
      ebdLimits: null,
      densityLimits: null,

      gridSpacing: 2.5,
      numSubbands: 10,
      dampingFactor: 0.1,
      maxIterations: 100,
      pinningPotential: 1.7,
      absTolerance: 1e-6,
      relTolerance: 1e-4,

      convergence: null,
      convergenceGridSpacings: [5, 4, 3, 2.5, 2, 1.5, 1],
      convergenceTolerance: 1.0,

      toggleTheme: () =>
        set((state) => ({ theme: state.theme === "light" ? "dark" : "light" })),

      setPinningPotential: (val: number) => set({ pinningPotential: val }),
      setGridSpacing: (val: number) => set({ gridSpacing: val }),
      setMaxIterations: (val: number) => set({ maxIterations: val }),
      setAbsTolerance: (val: number) => set({ absTolerance: val }),
      setRelTolerance: (val: number) => set({ relTolerance: val }),

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

      setIsRegionSelectionMode: (val) => set({ isRegionSelectionMode: val }),

      setEbdLimits: (limits) => set({ ebdLimits: limits }),
      setDensityLimits: (limits) => set({ densityLimits: limits }),

      runSimulation: async () => {
        set((state) => ({
          results: state.results
            ? { ...state.results, isRunning: true }
            : { z: [], ec: [], ev: [], n: [], ns: 0, slope: 0, iterations_used: 0, final_abs_err: 0, final_rel_err: 0, converged: false, isRunning: true },
          isRegionSelectionMode: false,
          ebdLimits: null,
          densityLimits: null,
        }));

        try {
          const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8001";
          console.log("📡 Simulation API URL:", API_URL);

          const startResponse = await fetch(`${API_URL}/simulate`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              layers: get().layers,
              pinningPotential: get().pinningPotential,
              gridSpacing: get().gridSpacing,
              maxIterations: get().maxIterations,
              absTolerance: get().absTolerance,
              relTolerance: get().relTolerance,
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

            console.log("✅ Simulation complete!");

            let initialRegion: [number, number] | null = null;
            if (data.z && data.z.length > 0) {
               initialRegion = [0, data.z[data.z.length - 1]];
            }

            set({
              results: {
                z: data.z,
                ec: data.ec,
                ev: data.ev,
                n: data.n,
                ns: data.ns,
                slope: data.slope,
                iterations_used: data.iterations_used,
                final_abs_err: data.final_abs_err,
                final_rel_err: data.final_rel_err,
                converged: data.converged,
                isRunning: false,
              },
              ebdLimits: initialRegion ? [...initialRegion] as [number, number] : null,
              densityLimits: initialRegion ? [...initialRegion] as [number, number] : null
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

      setConvergenceGridSpacings: (vals) =>
        set({ convergenceGridSpacings: vals }),
      setConvergenceTolerance: (val) => set({ convergenceTolerance: val }),

      runConvergenceStudy: async () => {
        const spacings = get().convergenceGridSpacings;
        if (!spacings || spacings.length === 0) {
          alert("Add at least one grid spacing to run a convergence study.");
          return;
        }

        set({
          convergence: {
            runs: [],
            isRunning: true,
            progress: 0,
            total: spacings.length,
          },
        });

        try {
          const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8001";
          console.log("📡 Convergence API URL:", API_URL);

          const startResponse = await fetch(`${API_URL}/convergence`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              layers: get().layers,
              pinningPotential: get().pinningPotential,
              maxIterations: get().maxIterations,
              gridSpacings: spacings,
              tolerance: get().convergenceTolerance,
              absTolerance: get().absTolerance,
              relTolerance: get().relTolerance,
            }),
          });

          if (!startResponse.ok) {
            const errBody = await startResponse.text().catch(() => "");
            throw new Error(
              `Server responded with ${startResponse.status}: ${errBody}`,
            );
          }

          const { job_id } = await startResponse.json();
          console.log(`📋 Convergence job started: ${job_id}`);

          const POLL_INTERVAL = 3000;
          const MAX_POLLS = 200; // ~10 minutes max wait

          for (let i = 0; i < MAX_POLLS; i++) {
            await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL));

            const pollResponse = await fetch(
              `${API_URL}/convergence_result/${job_id}`,
            );

            if (!pollResponse.ok) {
              if (pollResponse.status === 404) {
                throw new Error("Job not found on server. It may have expired.");
              }
              const errBody = await pollResponse.text().catch(() => "");
              throw new Error(`Server error ${pollResponse.status}: ${errBody}`);
            }

            const data = await pollResponse.json();

            if (data.status === "pending") {
              // Advance the progress bar as meshes complete server-side
              set((state) => ({
                convergence: state.convergence
                  ? {
                      ...state.convergence,
                      progress: data.progress ?? state.convergence.progress,
                      total: data.total ?? state.convergence.total,
                    }
                  : state.convergence,
              }));
              console.log(`⏳ Convergence ${data.progress}/${data.total}...`);
              continue;
            }

            console.log("✅ Convergence study complete!");
            set({
              convergence: {
                runs: data.runs as ConvergenceRun[],
                isRunning: false,
                progress: data.runs.length,
                total: data.runs.length,
              },
            });
            return;
          }

          throw new Error(
            "Convergence study timed out after 10 minutes. Please try again.",
          );
        } catch (error: unknown) {
          const msg =
            error instanceof Error ? error.message : "Unknown error occurred";
          console.error("❌ Convergence study failed:", msg);
          alert(`Convergence study failed: ${msg}`);
          set({ convergence: null });
        }
      },
    }),
    {
      name: "hemt-simulation-storage",
      // Don't persist heavy/transient convergence run curves to localStorage
      partialize: (state) =>
        Object.fromEntries(
          Object.entries(state).filter(([key]) => key !== "convergence"),
        ) as SimulationState,
    }
  )
);