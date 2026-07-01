import { useState, useEffect, useMemo, Fragment } from "react";
import { motion, AnimatePresence } from "framer-motion";
import * as LottieModule from "lottie-react";
import animationData from "./assets/loading.json";
import {
  Download,
  Moon,
  Sun,
  Play,
  ChevronDown,
  FileImage,
  FileSpreadsheet,
  FileJson,
  Target,
  RotateCcw,
  ExternalLink,
} from "lucide-react";
import {
  Menu,
  MenuButton,
  MenuItem,
  MenuItems,
  Transition,
} from "@headlessui/react";

import { LayerStackEditor } from "./components/LayerStackEditor";
import { SolverControls } from "./components/SolverControls";
import { BandDiagramChart } from "./components/BandDiagramChart";
import { ElectronConcentrationChart } from "./components/ElectronConcentrationChart";
import { ConvergenceStudy } from "./components/ConvergenceStudy";
import { useSimulationStore } from "./store/useSimulationStore";
import { toPng } from "html-to-image";
import { computeRegionMetrics, formatScientific } from "./utils/mathUtils";

// Import the user-provided logo image
import hemtLogo from "./assets/hemtLogo.png";

function App() {
  const {
    theme,
    toggleTheme,
    results,
    runSimulation,
    isRegionSelectionMode,
    setIsRegionSelectionMode,
    ebdLimits,
    setEbdLimits,
    densityLimits,
    setDensityLimits,
    layers,
    gridSpacing,
    numSubbands,
    dampingFactor,
    maxIterations,
    pinningPotential,
    absTolerance,
    relTolerance,
  } = useSimulationStore();

  const Lottie = (
    LottieModule as unknown as {
      default: {
        default: React.ComponentType<{
          animationData: object;
          loop?: boolean;
        }>;
      };
    }
  ).default.default;

  const [activeTab, setActiveTab] = useState<"ebd" | "density" | "convergence">("ebd");
  const [isCapturing, setIsCapturing] = useState(false);
  const [ebdMetrics, setEbdMetrics] = useState<{
    slope: number;
    ns: number;
  } | null>(null);
  const [densityMetrics, setDensityMetrics] = useState<{
    slope: number;
    ns: number;
  } | null>(null);
  const [direction, setDirection] = useState(1);

  const handleTabChange = (newTab: Tab) => {
    // Prevent re-triggering if clicking the active tab
    if (newTab === activeTab) return;

    const currentIndex = tabOrder.indexOf(activeTab);
    const newIndex = tabOrder.indexOf(newTab);

    // If the new index is higher, we move right (1). If lower, we move left (-1).
    setDirection(newIndex > currentIndex ? 1 : -1);
    setActiveTab(newTab);
  };

  const viewMode = useMemo(() => {
    return new URLSearchParams(window.location.search).get("view");
  }, []);

  useEffect(() => {
    if (isRegionSelectionMode && ebdLimits && results) {
      setEbdMetrics(computeRegionMetrics(results, ebdLimits));
    } else {
      setEbdMetrics(null);
    }
  }, [isRegionSelectionMode, ebdLimits, results]);

  useEffect(() => {
    if (isRegionSelectionMode && densityLimits && results) {
      setDensityMetrics(computeRegionMetrics(results, densityLimits));
    } else {
      setDensityMetrics(null);
    }
  }, [isRegionSelectionMode, densityLimits, results]);

  // --- IMAGE EXPORT FUNCTION ---
  const handleExportPNG = async () => {
    if (!results || !results.z || results.z.length === 0) {
      alert("No simulation data available. Please run the simulation first.");
      return;
    }

    const chartContainer = document.getElementById("charts-export-area");

    if (chartContainer) {
      setIsCapturing(true);

      try {
        console.log("Starting image capture...");
        const dataUrl = await toPng(chartContainer, {
          backgroundColor: theme === "dark" ? "#0c0c0e" : "#f0f2eb",
          pixelRatio: 2,
          cacheBust: true,
        });

        const response = await fetch(dataUrl);
        const blob = await response.blob();
        const blobUrl = URL.createObjectURL(blob);

        const imgLink = document.createElement("a");
        imgLink.href = blobUrl;
        imgLink.download = "HEMT_Band_Diagram.png";

        document.body.appendChild(imgLink);
        imgLink.click();
        document.body.removeChild(imgLink);
        URL.revokeObjectURL(blobUrl);
      } catch (error) {
        console.error("❌ Error capturing image:", error);
        alert("Failed to export image. Please check the browser console.");
      } finally {
        setIsCapturing(false);
      }
    }
  };

  const handleExportCSV = () => {
    if (!results || !results.z || results.z.length === 0) {
      alert("No simulation data available. Please run the simulation first.");
      return;
    }

    // Export CSV
    let csvContent = "z(nm),Ec(eV),Ev(eV),Ef(eV),n(cm^-3)\n";
    for (let i = 0; i < results.z.length; i++) {
      csvContent += `${results.z[i]},${results.ec[i]},${results.ev[i]},0,${results.n[i]}\n`;
    }

    const csvBlob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const csvUrl = URL.createObjectURL(csvBlob);
    const csvLink = document.createElement("a");
    csvLink.href = csvUrl;
    csvLink.download = "HEMT_Simulation_Data.csv";

    document.body.appendChild(csvLink);
    csvLink.click();
    document.body.removeChild(csvLink);
    URL.revokeObjectURL(csvUrl);
  };

  const handleExportJSON = () => {
    const config = {
      layers: layers.map(l => ({
        id: l.id,
        name: l.name,
        material: l.material,
        alFraction: l.alFraction,
        thickness: `${l.thickness} nm`,
        ndVal: `${l.ndVal} cm^-3`,
        naVal: `${l.naVal} cm^-3`
      })),
      solverParameters: {
        gridSpacing: `${gridSpacing} Å`,
        numSubbands,
        dampingFactor,
        maxIterations,
        pinningPotential: `${pinningPotential} eV`,
        absTolerance: `${absTolerance} V`,
        relTolerance: relTolerance
      }
    };

    const jsonContent = JSON.stringify(config, null, 2);
    const jsonBlob = new Blob([jsonContent], { type: "application/json;charset=utf-8;" });
    const jsonUrl = URL.createObjectURL(jsonBlob);
    const jsonLink = document.createElement("a");
    jsonLink.href = jsonUrl;
    jsonLink.download = "HEMT_Simulation_Config.json";

    document.body.appendChild(jsonLink);
    jsonLink.click();
    document.body.removeChild(jsonLink);
    URL.revokeObjectURL(jsonUrl);
  };

  const handleEbdInputChange = (index: 0 | 1, val: string) => {
    const num = parseFloat(val);
    if (ebdLimits && !isNaN(num)) {
      const newLimits = [...ebdLimits] as [number, number];
      newLimits[index] = num;
      setEbdLimits(newLimits);
    }
  };

  const handleDensityInputChange = (index: 0 | 1, val: string) => {
    const num = parseFloat(val);
    if (densityLimits && !isNaN(num)) {
      const newLimits = [...densityLimits] as [number, number];
      newLimits[index] = num;
      setDensityLimits(newLimits);
    }
  };

  const popOutChart = (chartId: "ebd" | "density") => {
    window.open(`${window.location.pathname}?view=${chartId}`, "_blank");
  };

  const displayNs =
    isRegionSelectionMode && densityMetrics ? densityMetrics.ns : results?.ns;
  const displaySlope =
    isRegionSelectionMode && ebdMetrics ? ebdMetrics.slope : results?.slope;

  const renderEBDChart = () => (
    <div className="flex flex-col h-full w-full">
      <div className="px-6 py-2.5 border-b border-slate-100 dark:border-gray-800/50 text-xs font-bold text-slate-500 dark:text-gray-400 tracking-widest flex items-center justify-between">
        <div className="flex items-center gap-4">
          <span className="text-xs font-bold text-slate-500 dark:text-gray-400 uppercase tracking-widest flex items-center gap-2">
            Energy Band Diagram (EBD)
            {!viewMode && (
              <button
                onClick={() => popOutChart("ebd")}
                className="text-slate-400 hover:text-indigo-500 transition-colors"
                title="Pop out into new tab"
              >
                <ExternalLink size={14} strokeWidth={2.5} />
              </button>
            )}
          </span>
          {isRegionSelectionMode && ebdLimits && (
            <div className="flex items-center gap-2 animate-fadeIn bg-indigo-500/10 rounded-full px-3 py-1 scale-95 border border-indigo-500/30 shadow-inner">
              <span className="text-[10px] text-indigo-500 uppercase font-black tracking-widest">
                Region:
              </span>
              <input
                type="number"
                value={ebdLimits[0].toFixed(2)}
                onChange={(e) => handleEbdInputChange(0, e.target.value)}
                className="w-14 bg-transparent text-slate-700 dark:text-slate-300 font-mono text-xs outline-none border-b border-indigo-500/30 focus:border-indigo-500 transition-colors text-center"
              />
              <span className="text-[10px] text-slate-500 italic">to</span>
              <input
                type="number"
                value={ebdLimits[1].toFixed(2)}
                onChange={(e) => handleEbdInputChange(1, e.target.value)}
                className="w-14 bg-transparent text-slate-700 dark:text-slate-300 font-mono text-xs outline-none border-b border-indigo-500/30 focus:border-indigo-500 transition-colors text-center"
              />
              <span className="text-[10px] text-slate-500">nm</span>
              <button
                onClick={() =>
                  setEbdLimits([0, results?.z[results.z.length - 1] ?? 0])
                }
                className="ml-1 text-slate-400 hover:text-indigo-500 transition-colors"
                title="Reset Region"
              >
                <RotateCcw size={12} strokeWidth={2.5} />
              </button>
            </div>
          )}
        </div>

        {results && !results.isRunning && (
          <div className="min-w-47.5 flex flex-col items-center rounded-2xl px-3 py-1 bg-black/5 dark:bg-white/5 transition-all duration-300">
            <div>
              <span className="text-[10px] uppercase font-bold text-slate-500">
                {isRegionSelectionMode
                  ? "Region Electric Field:"
                  : "Average Electric Field:"}
              </span>
            </div>
            <span className="text-sm font-mono font-bold text-blue-500 transition-all">
              {displaySlope !== undefined
                ? formatScientific(Math.abs(displaySlope))
                : "---"}{" "}
              V/cm
            </span>
          </div>
        )}
      </div>
      <div className="flex-1 p-2 relative overflow-hidden bg-transparent">
        <BandDiagramChart />
      </div>
    </div>
  );

  const renderDensityChart = () => (
    <div className="flex flex-col h-full w-full">
      <div className="px-6 py-2.5 border-b border-slate-100 dark:border-gray-800/50 text-xs font-bold text-slate-500 dark:text-gray-400 tracking-widest flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="uppercase flex items-center gap-2">
            Electron Density n(z)
            {!viewMode && (
              <button
                onClick={() => popOutChart("density")}
                className="text-slate-400 hover:text-indigo-500 transition-colors"
                title="Pop out into new tab"
              >
                <ExternalLink size={14} strokeWidth={2.5} />
              </button>
            )}
          </div>
          {isRegionSelectionMode && densityLimits && (
            <div className="flex items-center gap-2 animate-fadeIn bg-indigo-500/10 rounded-full px-3 py-1 scale-95 border border-indigo-500/30 shadow-inner">
              <span className="text-[10px] text-indigo-500 uppercase font-black tracking-widest">
                Region:
              </span>
              <input
                type="number"
                value={densityLimits[0].toFixed(2)}
                onChange={(e) => handleDensityInputChange(0, e.target.value)}
                className="w-14 bg-transparent text-slate-700 dark:text-slate-300 font-mono text-xs outline-none border-b border-indigo-500/30 focus:border-indigo-500 transition-colors text-center"
              />
              <span className="text-[10px] text-slate-500 italic">to</span>
              <input
                type="number"
                value={densityLimits[1].toFixed(2)}
                onChange={(e) => handleDensityInputChange(1, e.target.value)}
                className="w-14 bg-transparent text-slate-700 dark:text-slate-300 font-mono text-xs outline-none border-b border-indigo-500/30 focus:border-indigo-500 transition-colors text-center"
              />
              <span className="text-[10px] text-slate-500">nm</span>
              <button
                onClick={() =>
                  setDensityLimits([0, results?.z[results.z.length - 1] ?? 0])
                }
                className="ml-1 text-slate-400 hover:text-indigo-500 transition-colors"
                title="Reset Region"
              >
                <RotateCcw size={12} strokeWidth={2.5} />
              </button>
            </div>
          )}
        </div>
        <div className="flex items-center gap-6">
          {results && !results.isRunning && (
            <div className="flex flex-col items-center rounded-2xl px-3 py-1 bg-black/5 dark:bg-white/5 transition-all duration-300">
              <div className="mb-px">
                <span className="text-[10px] uppercase font-bold text-slate-500">
                  {isRegionSelectionMode
                    ? "Region Density:"
                    : "Sheet Density (ns):"}
                </span>
              </div>
              <span className="text-sm font-mono font-bold text-blue-500 transition-all">
                {formatScientific(displayNs)} cm<sup>-2</sup>
              </span>
            </div>
          )}
        </div>
      </div>
      <div className="flex-1 p-2 relative overflow-hidden bg-transparent">
        <ElectronConcentrationChart />
      </div>
    </div>
  );

  const tabOrder = ["ebd", "density", "convergence"] as const;
  type Tab = (typeof tabOrder)[number];

  const slideVariants = {
    // 'direction' is passed via the `custom` prop in Framer Motion
    initial: (direction: number) => ({
      opacity: 0,
      x: direction > 0 ? 30 : -30, // Enter from right if moving right, else left
    }),
    animate: {
      opacity: 1,
      x: 0,
    },
    exit: (direction: number) => ({
      opacity: 0,
      x: direction > 0 ? -30 : 30, // Exit to left if moving right, else right
    }),
  };

  return (
    <div
      className={`${theme === "dark" ? "dark" : ""} fixed inset-0 font-sans`}
    >
      <div className="h-full w-full flex flex-col bg-[#f0f2eb] dark:bg-[#0c0c0e] text-slate-800 dark:text-gray-100 transition-colors duration-500 relative z-0">
        {/* If in Pop-out Mode, render ONLY the selected Chart full screen */}
        {viewMode ? (
          <div
            className="h-full w-full p-4 flex flex-col overflow-hidden"
            id="charts-export-area"
          >
            {viewMode === "ebd" && renderEBDChart()}
            {viewMode === "density" && renderDensityChart()}
          </div>
        ) : (
          /* OTHERWISE: Normal Application Layout */
          <>
            {/* Ambient Background Glow */}
            <div className="absolute top-[-10%] left-[-5%] w-125 h-125 bg-blue-500/20 dark:bg-blue-500/10 rounded-full blur-[120px] -z-10 pointer-events-none"></div>
            <div className="absolute bottom-[-10%] right-[-5%] w-150 h-150 bg-indigo-500/20 dark:bg-indigo-500/10 rounded-full blur-[150px] -z-10 pointer-events-none"></div>

            {/* --- HEADER --- */}
            <header className="fixed top-0 left-0 right-0 flex justify-between items-center px-8 py-2 z-50 transition-all duration-500 backdrop-blur-[6px] bg-white/40 dark:bg-[#0c0c0e]/60 border-b border-white/40 dark:border-white/5 shadow-[0_4px_30px_rgb(0,0,0,0.02)]">
              <div className="flex items-center gap-x-6 cursor-pointer hover:opacity-90 transition-opacity">
                <img
                  src={hemtLogo}
                  alt="HEMT Solver Logo"
                  className="h-10 w-auto object-contain hover:scale-105 transition-transform duration-300 drop-shadow-sm"
                />

                <div className="hidden lg:flex items-center justify-center bg-white/90 dark:bg-[#18181b]/90 rounded-full px-8 py-3.5 shadow-[0_4px_20px_rgb(0,0,0,0.03)] dark:shadow-none border border-transparent dark:border-white/5 transition-all w-137.5 backdrop-blur-md">
                  <p className="text-center text-[13px] font-semibold text-slate-600 dark:text-slate-300 tracking-wide">
                    Self-Consistent Schrödinger-Poisson Solver for AlGaN/GaN
                    HEMT
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-4">
                {/* Export Dropdown — hidden on convergence tab (it has its own CSV export) */}
                {activeTab !== "convergence" && (
                <Menu as="div" className="relative inline-block text-left">
                  <div>
                    <MenuButton
                      disabled={
                        !results || results.isRunning || results.z.length === 0
                      }
                      className="h-11 px-4 bg-white/90 dark:bg-[#18181b]/90 rounded-full flex items-center justify-center gap-2 shadow-[0_4px_20px_rgb(0,0,0,0.04)] dark:shadow-none border border-transparent dark:border-white/5 text-slate-700 dark:text-slate-300 hover:text-black dark:hover:text-white transition-all duration-300 disabled:opacity-40 opacity-90 hover:opacity-100 disabled:cursor-not-allowed backdrop-blur-md hover:cursor-pointer text-sm font-medium"
                    >
                      {isCapturing ? (
                        <span className="flex items-center gap-2">
                          <span className="animate-spin h-4 w-4 border-2 border-slate-700 dark:border-slate-300 border-t-transparent rounded-full"></span>
                          Exporting...
                        </span>
                      ) : (
                        <>
                          <Download size={16} strokeWidth={2} />
                          Export
                          <ChevronDown size={14} className="ml-1 opacity-70" />
                        </>
                      )}
                    </MenuButton>
                  </div>
                  <Transition
                    as={Fragment}
                    enter="transition ease-out duration-100"
                    enterFrom="transform opacity-0 scale-95"
                    enterTo="transform opacity-100 scale-100"
                    leave="transition ease-in duration-75"
                    leaveFrom="transform opacity-100 scale-100"
                    leaveTo="transform opacity-0 scale-95"
                  >
                    <MenuItems className="absolute right-0 mt-2 w-52 origin-top-right divide-y divide-slate-100 dark:divide-white/5 rounded-2xl bg-white/95 dark:bg-[#18181b]/95 shadow-lg ring-1 ring-black/5 dark:ring-white/10 focus:outline-none backdrop-blur-xl border border-white/40 dark:border-white/5 z-50">
                      <div className="px-1 py-1 ">
                        <MenuItem>
                          {({ focus }) => (
                            <button
                              onClick={handleExportPNG}
                              className={`${
                                focus
                                  ? "bg-blue-500/10 text-blue-600 dark:text-blue-400"
                                  : "text-slate-700 dark:text-slate-300"
                              } group flex w-full items-center rounded-xl px-3 py-2.5 text-sm font-medium transition-colors`}
                            >
                              <FileImage
                                className="mr-3 h-4 w-4 opacity-70 group-hover:opacity-100"
                                aria-hidden="true"
                              />
                              Save as PNG
                            </button>
                          )}
                        </MenuItem>
                        <MenuItem>
                          {({ focus }) => (
                            <button
                              onClick={handleExportCSV}
                              className={`${
                                focus
                                  ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400"
                                  : "text-slate-700 dark:text-slate-300"
                              } group flex w-full items-center rounded-xl px-3 py-2.5 text-sm font-medium transition-colors`}
                            >
                              <FileSpreadsheet
                                className="mr-3 h-4 w-4 opacity-70 group-hover:opacity-100"
                                aria-hidden="true"
                              />
                              Export Data (CSV)
                            </button>
                          )}
                        </MenuItem>
                        <MenuItem>
                          {({ focus }) => (
                            <button
                              onClick={handleExportJSON}
                              className={`${
                                focus
                                  ? "bg-amber-500/10 text-amber-600 dark:text-amber-400"
                                  : "text-slate-700 dark:text-slate-300"
                              } group flex w-full items-center rounded-xl px-3 py-2.5 text-sm font-medium transition-colors`}
                            >
                              <FileJson
                                className="mr-3 h-4 w-4 opacity-70 group-hover:opacity-100"
                                aria-hidden="true"
                              />
                              Export Config (JSON)
                            </button>
                          )}
                        </MenuItem>
                      </div>
                    </MenuItems>
                  </Transition>
                </Menu>
                )}

                <button
                  onClick={toggleTheme}
                  className="h-11 w-11 bg-white/90 dark:bg-[#18181b]/90 rounded-full flex items-center justify-center shadow-[0_4px_20px_rgb(0,0,0,0.04)] dark:shadow-none border border-transparent dark:border-white/5 text-slate-700 dark:text-slate-300 hover:text-black dark:hover:text-white hover:scale-105 transition-all duration-300 backdrop-blur-md hover:cursor-pointer"
                  title="Toggle Theme"
                >
                  {theme === "light" ? (
                    <Moon size={16} strokeWidth={2} />
                  ) : (
                    <Sun size={16} strokeWidth={2} />
                  )}
                </button>

                {/* Region selection — only relevant for single-simulation chart tabs */}
                {activeTab !== "convergence" && (
                <button
                  onClick={() =>
                    setIsRegionSelectionMode(!isRegionSelectionMode)
                  }
                  disabled={
                    !results || results.isRunning || results.z.length === 0
                  }
                  className={`h-11 px-4 ${isRegionSelectionMode ? "bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border-indigo-500/30" : "bg-white/90 dark:bg-[#18181b]/90 text-slate-700 dark:text-slate-300 border-transparent dark:border-white/5"} rounded-full flex items-center justify-center gap-2 shadow-[0_4px_20px_rgb(0,0,0,0.04)] dark:shadow-none border hover:text-black dark:hover:text-white transition-all duration-300 disabled:opacity-40 hover:cursor-pointer text-sm font-medium`}
                  title="Select region to compute accurate metrics"
                >
                  <Target
                    size={16}
                    strokeWidth={2}
                    className={`${isRegionSelectionMode ? "animate-pulse" : ""} drop-shadow-sm`}
                  />
                  Select Region
                </button>
                )}

                <div className="bg-white/90 dark:bg-[#18181b]/90 rounded-full flex items-center pl-6 pr-2 py-2 shadow-[0_4px_20px_rgb(0,0,0,0.04)] dark:shadow-none border border-transparent dark:border-white/5 backdrop-blur-md ml-2">
                  <div className="flex flex-col mr-4 w-22 relative">
                    <span className="items-center text-[13px] font-black text-slate-800 dark:text-gray-100 leading-tight transition-all duration-300">
                      <AnimatePresence mode="wait">
                        {results && !results.isRunning ? (
                          <motion.div
                            key="result"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                            transition={{ duration: 0.15 }}
                            className="absolute inset-0 flex flex-col items-center justify-center text-center"
                          >
                            <span className="text-[9px] uppercase font-bold text-slate-400 dark:text-slate-500 tracking-wider">
                              Iterations
                            </span>
                            <span className="text-[14px] font-black text-emerald-600 dark:text-emerald-500 leading-tight">
                              {results.iterations_used || "---"}
                            </span>
                          </motion.div>
                        ) : results?.isRunning ? (
                          <motion.div
                            key="loading"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                            transition={{ duration: 0.15 }}
                            className="flex items-center justify-center -ml-11.25 w-45 h-6 overflow-visible"
                          >
                            <Lottie animationData={animationData} loop />
                          </motion.div>
                        ) : (
                          <motion.div
                            key="empty"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                            transition={{ duration: 0.15 }}
                            className="absolute inset-0 flex items-center justify-center h-full w-full"
                          >
                            <span className="text-[15px] font-black text-slate-800 dark:text-gray-400 leading-tight transition-all duration-300 opacity-85">
                              Simulate
                            </span>
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </span>
                  </div>

                  <button
                    onClick={runSimulation}
                    disabled={results?.isRunning}
                    className="relative h-9 w-9 bg-slate-900 dark:bg-slate-100 hover:cursor-pointer rounded-full flex items-center justify-center text-white dark:text-slate-900 hover:scale-105 active:scale-95 transition-transform disabled:opacity-50 disabled:scale-100 shadow-md"
                    title="Run Simulation"
                  >
                    {results?.isRunning ? (
                      <div className="h-3.5 w-3.5 border-2 border-white dark:border-slate-900 border-t-transparent rounded-full animate-spin"></div>
                    ) : (
                      <Play
                        size={14}
                        strokeWidth={2.5}
                        className="ml-0.5"
                        fill="currentColor"
                      />
                    )}
                    <div
                      className={`absolute top-0 right-0 h-2.5 w-2.5 rounded-full border-2 border-white dark:border-[#18181b] transition-colors duration-300 ${results && !results.isRunning ? "bg-emerald-500" : "bg-amber-400"}`}
                    ></div>
                  </button>
                </div>
              </div>
            </header>

            {/* WORKSPACE (Now spans full height behind header) */}
            <main className="flex-1 flex overflow-hidden w-full h-full relative">
              {/* Left Sidebar (Has top padding so content starts below header, but scrolls under it) */}
              <aside className="w-100 bg-white/65 dark:bg-[#0c0c0e]/40 backdrop-blur-xl border-r border-white/40 dark:border-white/5 flex flex-col overflow-y-auto no-scrollbar shrink-0 animate-slide-up z-10 relative shadow-[4px_0_24px_rgb(0,0,0,0.02)] pt-22.5 pb-8">
                <LayerStackEditor />
                <SolverControls />
              </aside>

              {/* Main Content Area */}
              <div className="flex-1 flex flex-col pt-22.5 pb-6 px-7 overflow-hidden">
                {/* Tabs Row */}
                <div className="flex items-center gap-1 mb-4 bg-white/50 dark:bg-white/5 p-1.5 rounded-2xl w-fit border border-slate-200/50 dark:border-gray-800/50 backdrop-blur-md relative">
                  {([
                    { id: "ebd" as const, label: "Energy Band Diagram", activeColor: "text-blue-600 dark:text-blue-400" },
                    { id: "density" as const, label: "Electron Density n(z)", activeColor: "text-emerald-600 dark:text-emerald-400" },
                    { id: "convergence" as const, label: "Convergence Study", activeColor: "text-indigo-600 dark:text-indigo-400" },
                  ]).map((tab) => (
                    <button
                      key={tab.id}
                      onClick={() => handleTabChange(tab.id)}
                      className={`relative px-5 py-2 rounded-xl text-sm font-semibold transition-colors duration-300 z-10 ${
                        activeTab === tab.id
                          ? tab.activeColor
                          : "text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
                      }`}
                    >
                      {tab.label}

                      {activeTab === tab.id && (
                        <motion.div
                          layoutId="active-tab-highlight"
                          className="absolute inset-0 bg-white dark:bg-gray-400/10 dark:border dark:border-white/5 rounded-xl shadow-sm dark:shadow-sm/40 dark:shadow-gray-700 dark:inset-shadow-sm dark:inset-shadow-gray-900/10 z-[-1]"
                          transition={{
                            type: "spring",
                            bounce: 0.2,
                            duration: 0.5,
                          }}
                        />
                      )}
                    </button>
                  ))}
                </div>

                <section
                  id="charts-export-area"
                  className="flex-1 overflow-hidden relative bg-white dark:bg-[#121212] shadow-[0_8px_30px_rgb(0,0,0,0.04)] dark:shadow-none border border-transparent dark:border-white/5 rounded-3xl"
                >
                  <AnimatePresence
                    mode="wait"
                    initial={false}
                    custom={direction}
                  >
                    <motion.div
                      key={activeTab}
                      custom={direction}
                      variants={slideVariants}
                      initial="initial"
                      animate="animate"
                      exit="exit"
                      transition={{ duration: 0.15, ease: "easeOut" }}
                      className="w-full h-full"
                    >
                      {activeTab === "ebd"
                        ? renderEBDChart()
                        : activeTab === "density"
                          ? renderDensityChart()
                          : <ConvergenceStudy />}
                    </motion.div>
                  </AnimatePresence>
                </section>
              </div>
            </main>
          </>
        )}
      </div>
    </div>
  );
}

export default App;
