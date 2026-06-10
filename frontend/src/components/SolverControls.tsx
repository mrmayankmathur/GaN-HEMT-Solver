import React from "react";
import { useSimulationStore } from "../store/useSimulationStore";
import { Play } from "lucide-react";

export const SolverControls: React.FC = () => {
  const store = useSimulationStore();
  const { runSimulation, results } = useSimulationStore();

  return (
    <div className="px-6 py-4 flex flex-col gap-5 border-t border-slate-200/50 dark:border-gray-800/50 bg-white/30 dark:bg-[#121212]/30 mt-auto">
      <div className="text-xs font-bold text-slate-500 dark:text-gray-500 uppercase tracking-widest border-b border-transparent pb-1">
        Simulation Parameters
      </div>

      <div className="grid grid-cols-2 gap-4 text-xs">
        <div className="flex flex-col gap-1.5 focus-within:-translate-y-0.5 transition-transform duration-300">
          <label className="font-semibold text-[10px] tracking-wider uppercase text-slate-500 dark:text-gray-400 pl-1">
            Grid Spacing (Å)
          </label>
          <input
            type="number"
            step="0.5"
            value={store.gridSpacing}
            onChange={(e) => store.setGridSpacing(parseFloat(e.target.value))}
            className="p-2 border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30 transition-all shadow-sm font-mono cursor-text"
          />
        </div>
        <div className="flex flex-col gap-1.5 focus-within:-translate-y-0.5 transition-transform duration-300">
          <label className="font-semibold text-[10px] tracking-wider uppercase text-slate-500 dark:text-gray-400 pl-1">
            Max Subbands
          </label>
          <input
            type="number"
            value={store.numSubbands}
            className="p-2 border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30 transition-all shadow-sm font-mono"
            readOnly
          />
        </div>
        <div className="flex flex-col gap-1.5 focus-within:-translate-y-0.5 transition-transform duration-300">
          <label className="font-semibold text-[10px] tracking-wider uppercase text-slate-500 dark:text-gray-400 pl-1">
            Iterations
          </label>
          <input
            type="number"
            step="10"
            value={store.maxIterations}
            onChange={(e) => store.setMaxIterations(parseInt(e.target.value))}
            className="p-2 border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30 transition-all shadow-sm font-mono cursor-text"
          />
        </div>
        <div className="flex flex-col gap-1.5 focus-within:-translate-y-0.5 transition-transform duration-300">
          <label className="font-semibold text-[10px] tracking-wider text-slate-500 dark:text-gray-400 pl-1">
            Surface Potential (eV)
          </label>
          <input
            type="number"
            step="0.1"
            value={store.pinningPotential}
            onChange={(e) =>
              store.setPinningPotential(parseFloat(e.target.value))
            }
            className="p-2 border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30 transition-all shadow-sm font-mono cursor-text"
          />
        </div>
      </div>

      <button
        onClick={runSimulation}
        disabled={results?.isRunning}
        className="mt-2 w-full group relative overflow-hidden bg-blue-600 hover:bg-blue-700 text-white p-px rounded-lg text-xs font-bold flex justify-center items-center gap-2 transition-all duration-300 shadow-md hover:shadow-lg hover:-translate-y-0.5 active:scale-[0.98]"
      >
        {results?.isRunning ? (
          <span className="w-full bg-slate-800 hover:bg-slate-700 text-white py-2 rounded-lg transition-colors flex items-center justify-center gap-2 animate-pulse">
            Solving...
          </span>
        ) : (
          <div className="w-full bg-slate-800 hover:bg-slate-700 text-white py-2 rounded-lg transition-colors flex items-center justify-center gap-2 hover:cursor-pointer">
            <Play
              size={14}
              fill="currentColor"
              className="group-hover:scale-110 transition-transform"
            />{" "}
            Initialize 1D Solver
          </div>
        )}
      </button>
    </div>
  );
};
