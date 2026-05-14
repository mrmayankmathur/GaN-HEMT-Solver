import React from "react";
import { useSimulationStore } from "../store/useSimulationStore";
import { Plus, Minus, Menu } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

export const LayerStackEditor: React.FC = () => {
  const {
    layers,
    selectedLayerId,
    setSelectedLayer,
    updateLayer,
    addLayer,
    removeLayer,
  } = useSimulationStore();
  const selectedLayer =
    layers.find((l) => l.id === selectedLayerId) || layers[0];

  const getLayerColor = (material: string) => {
    if (material === "AlN")
      return "bg-teal-50 dark:bg-teal-900/20 border-teal-200/50 dark:border-teal-700/30 text-teal-800 dark:text-teal-300";
    if (material === "AlGaN")
      return "bg-indigo-50 dark:bg-indigo-900/20 border-indigo-200/50 dark:border-indigo-700/30 text-indigo-800 dark:text-indigo-300";
    return "bg-[#F5F5F5] dark:bg-gray-800/30 border-slate-300/50 dark:border-gray-700 text-slate-700 dark:text-gray-300"; // GaN
  };

  return (
    <div className="p-6 flex flex-col gap-6">
      <div className="flex justify-between items-center text-xs font-bold text-slate-500 dark:text-gray-400 uppercase tracking-widest border-b border-slate-200/50 dark:border-gray-800/50 pb-3">
        Epitaxial Stack
        <div className="flex gap-1">
          <button
            onClick={addLayer}
            className="p-1.5 hover:bg-slate-100 dark:hover:bg-gray-800 rounded-full text-slate-500 dark:text-gray-400 transition-all hover:scale-110 active:scale-95"
          >
            <Plus size={14} />
          </button>
        </div>
      </div>

      {/* Compact Interactive List UI */}
      <div className="flex flex-col mt-2">
        <AnimatePresence initial={false}>
          {layers.map((layer) => (
            <motion.div
              key={layer.id}
              initial={{
                opacity: 0,
                scale: 0.8,
                y: -20,
                height: 0,
                marginBottom: 0,
              }}
              animate={{
                opacity: 1,
                scale: 1,
                y: 0,
                height: "auto",
                marginBottom: 10,
              }}
              exit={{
                opacity: 0,
                scale: 0.8,
                x: -30,
                height: 0,
                marginBottom: 0,
              }}
              transition={{ type: "spring", bounce: 0.35, duration: 0.5 }}
              layout
            >
              <div
                onClick={() => setSelectedLayer(layer.id)}
                className={`group flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-colors duration-300 hover:shadow-sm ${
                  selectedLayerId === layer.id
                    ? "border-blue-500 ring-2 ring-blue-500/20 shadow-md dark:border-blue-500 dark:bg-blue-500/10"
                    : "hover:border-slate-300 dark:hover:border-gray-600 border-slate-200 dark:border-gray-800"
                } ${getLayerColor(layer.material)}`}
              >
                <Menu
                  size={14}
                  className={`shrink-0 transition-colors ${
                    selectedLayerId === layer.id
                      ? "text-blue-500"
                      : "text-slate-400 dark:text-gray-500 group-hover:text-slate-600 dark:group-hover:text-gray-300"
                  }`}
                />
                <div className="flex-1 flex flex-col">
                  <span className="text-xs font-bold tracking-wide">
                    {layer.material}{" "}
                    <span className="opacity-60 text-[10px] ml-1 font-normal">
                      ({layer.name})
                    </span>
                  </span>
                  <span className="text-[10px] opacity-80 mt-0.5 tracking-wider font-mono">
                    {layer.thickness} nm
                    {layer.alFraction > 0 ? (
                      <span className="mx-1">
                        • Al: {(layer.alFraction * 100).toFixed(0)}%
                      </span>
                    ) : (
                      <span className="mx-1">•</span>
                    )}
                    Nd: {layer.ndVal.toExponential(1)}
                  </span>
                </div>
                {layers.length > 1 && (
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      removeLayer(layer.id);
                    }}
                    className={`p-1.5 rounded-full transition-all duration-300 hover:bg-red-100 dark:hover:bg-red-500/20 hover:text-red-600 dark:hover:text-red-400 active:scale-95 ${
                      selectedLayerId === layer.id
                        ? "opacity-100"
                        : "opacity-0 group-hover:opacity-100 text-slate-400"
                    }`}
                  >
                    <Minus size={14} />
                  </button>
                )}
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Properties Editor */}
      <div className="flex flex-col gap-4 bg-white/60 dark:bg-[#161618] p-5 rounded-2xl border border-slate-200/50 dark:border-gray-800/50 shadow-sm animate-scale-in">
        <div className="text-[11px] font-bold text-slate-500 dark:text-gray-500 uppercase tracking-widest border-b border-slate-200/50 dark:border-gray-800/50 pb-2">
          Active Controls
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="flex flex-col gap-1.5 focus-within:-translate-y-0.5 transition-transform duration-300">
            <label className="text-[10px] uppercase font-bold tracking-wider text-slate-500 dark:text-gray-400 pl-1">
              Material
            </label>
            <select
              className="text-xs font-medium p-2 border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500 transition-all shadow-sm"
              value={selectedLayer.material}
              onChange={(e) =>
                updateLayer(selectedLayer.id, { material: e.target.value })
              }
            >
              <option value="GaN">GaN</option>
              <option value="AlGaN">AlGaN</option>
              <option value="AlN">AlN</option>
            </select>
          </div>

          <div className="flex flex-col gap-1.5 focus-within:-translate-y-0.5 transition-transform duration-300">
            <label className="text-[10px] uppercase font-bold tracking-wider text-slate-500 dark:text-gray-400 pl-1">
              Thickness (nm)
            </label>
            <input
              type="number"
              className="text-xs p-2 border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500 transition-all font-mono shadow-sm"
              value={selectedLayer.thickness}
              onChange={(e) =>
                updateLayer(selectedLayer.id, {
                  thickness: Number(e.target.value),
                })
              }
            />
          </div>

          <div className="flex flex-col gap-1.5 focus-within:-translate-y-0.5 transition-transform duration-300">
            <label className="text-[10px] uppercase font-bold tracking-wider text-slate-500 dark:text-gray-400 pl-1 flex items-center justify-between">
              Al Comp
              <span className="text-blue-500 normal-case">
                {selectedLayer.alFraction.toFixed(2)}
              </span>
            </label>
            <input
              type="range"
              min="0"
              max="1"
              step="0.01"
              disabled={selectedLayer.material !== "AlGaN"}
              className="w-full h-2 bg-slate-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-blue-500 mt-2 disabled:opacity-30 disabled:cursor-not-allowed transition-all"
              value={selectedLayer.alFraction}
              onChange={(e) =>
                updateLayer(selectedLayer.id, {
                  alFraction: Number(e.target.value),
                })
              }
            />
          </div>

          <div className="flex flex-col gap-1.5 focus-within:-translate-y-0.5 transition-transform duration-300">
            <label className="text-[10px] uppercase font-bold tracking-wider text-slate-500 dark:text-gray-400 pl-1">
              Nd [cm⁻³]
            </label>
            <input
              type="text"
              className="text-xs p-2 border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500 transition-all font-mono shadow-sm"
              value={selectedLayer.ndVal.toExponential(1)}
              onChange={(e) =>
                updateLayer(selectedLayer.id, { ndVal: Number(e.target.value) })
              }
            />
          </div>
        </div>
      </div>
    </div>
  );
};
