import { useState } from "react";
import {
  Download,
  Moon,
  Sun,
  Play,
  ChevronDown,
  FileImage,
  FileSpreadsheet,
} from "lucide-react";
import {
  Menu,
  MenuButton,
  MenuItem,
  MenuItems,
  Transition,
} from "@headlessui/react";

import { Fragment } from "react";
import { LayerStackEditor } from "./components/LayerStackEditor";
import { SolverControls } from "./components/SolverControls";
import { BandDiagramChart } from "./components/BandDiagramChart";
import { ElectronConcentrationChart } from "./components/ElectronConcentrationChart";
import { useSimulationStore } from "./store/useSimulationStore";
import { toPng } from "html-to-image";

// Import the user-provided logo image
import hemtLogo from "./assets/hemtLogo.png";

// Helper for scientific notation formatting
const formatScientific = (value: number | undefined) => {
  if (!value)
    return (
      <span>
        0.000 &times; 10<sup>0</sup>
      </span>
    );
  const [base, exponent] = value.toExponential(3).split("e");
  return (
    <span>
      {base} &times; 10<sup>{parseInt(exponent, 10)}</sup>
    </span>
  );
};

function App() {
  const { theme, toggleTheme, results, runSimulation } = useSimulationStore();
  const [isCapturing, setIsCapturing] = useState(false);

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
    let csvContent = "z(nm),Ec(eV),Ev(eV),n(cm^-3)\n";
    for (let i = 0; i < results.z.length; i++) {
      csvContent += `${results.z[i]},${results.ec[i]},${results.ev[i]},${results.n[i]}\n`;
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

  return (
    <div
      className={`${theme === "dark" ? "dark" : ""} fixed inset-0 font-sans`}
    >
      <div className="h-full w-full flex flex-col bg-[#f0f2eb] dark:bg-[#0c0c0e] text-slate-800 dark:text-gray-100 transition-colors duration-500 relative z-0">
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
                Self-Consistent Schrödinger-Poisson Solver for AlGaN/GaN HEMT
              </p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            {/* Export Dropdown */}
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
                <MenuItems className="absolute right-0 mt-2 w-48 origin-top-right divide-y divide-slate-100 dark:divide-white/5 rounded-2xl bg-white/95 dark:bg-[#18181b]/95 shadow-lg ring-1 ring-black/5 dark:ring-white/10 focus:outline-none backdrop-blur-xl border border-white/40 dark:border-white/5 z-50">
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
                  </div>
                </MenuItems>
              </Transition>
            </Menu>

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

            <div className="bg-white/90 dark:bg-[#18181b]/90 rounded-full flex items-center pl-6 pr-2 py-2 shadow-[0_4px_20px_rgb(0,0,0,0.04)] dark:shadow-none border border-transparent dark:border-white/5 backdrop-blur-md ml-2">
              <div className="flex flex-col mr-4">
                <span className="text-[9px] uppercase font-bold text-slate-400 dark:text-slate-500 tracking-wider">
                  Sheet Density
                </span>
                <span className="text-[13px] font-black text-slate-800 dark:text-gray-100 leading-tight">
                  {results && !results.isRunning
                    ? formatScientific(results.ns)
                    : "---"}
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

          {/* Wrapper to handle top padding so the Export snapshot doesn't include empty space */}
          <div className="flex-1 flex flex-col pt-22.5 pb-6 px-8 overflow-hidden">
            <section
              id="charts-export-area"
              className="flex-1 flex flex-col gap-6 overflow-hidden"
            >
              <div className="flex-1 bg-white dark:bg-[#121212] shadow-[0_8px_30px_rgb(0,0,0,0.04)] dark:shadow-none border border-transparent dark:border-white/5 rounded-3xl flex flex-col overflow-hidden">
                <div className="px-6 py-2.5 border-b border-slate-100 dark:border-gray-800/50 text-xs font-bold text-slate-500 dark:text-gray-400 tracking-widest flex items-center justify-between">
                  <span className="text-xs font-bold text-slate-500 dark:text-gray-400 uppercase tracking-widest">
                    Energy Band Diagram (EBD)
                  </span>
                  {results && !results.isRunning && (
                    <div className="flex flex-col items-center rounded-2xl px-3 py-1 bg-black/5 dark:bg-white/5">
                      <div>
                        <span className="text-[10px] uppercase font-bold text-slate-500">
                          Average Electric Field:
                        </span>
                      </div>
                      <span className="text-sm font-mono font-bold text-blue-500">
                        {results.slope !== undefined
                          ? formatScientific(Math.abs(results.slope))
                          : "---"}{" "}
                        MV/cm
                      </span>
                    </div>
                  )}
                </div>
                <div className="flex-1 p-2 relative overflow-hidden bg-transparent">
                  <BandDiagramChart />
                </div>
              </div>

              <div className="h-72 bg-white dark:bg-[#121212] shadow-[0_8px_30px_rgb(0,0,0,0.04)] dark:shadow-none border border-transparent dark:border-white/5 rounded-3xl flex flex-col overflow-hidden shrink-0">
                <div className="px-6 py-2.5 border-b border-slate-100 dark:border-gray-800/50 text-xs font-bold text-slate-500 dark:text-gray-400 tracking-widest flex items-center justify-between">
                  <div className="uppercase">Electron Density n(z)</div>
                  <div className="flex items-center gap-6">
                    {results && !results.isRunning && (
                      <div className="flex flex-col items-center rounded-2xl px-3 py-1 bg-black/5 dark:bg-white/5">
                        <div className="mb-px">
                          <span className="text-[10px] uppercase font-bold text-slate-500">
                            Sheet Density (n<sub>s</sub>)
                          </span>
                        </div>
                        {/* Change this line */}
                        <span className="text-sm font-mono font-bold text-blue-500">
                          {formatScientific(results?.ns)} cm<sup>2</sup>
                        </span>
                      </div>
                    )}
                  </div>
                </div>
                <div className="flex-1 p-2 relative overflow-hidden bg-transparent">
                  <ElectronConcentrationChart />
                </div>
              </div>
            </section>
          </div>
        </main>
      </div>
    </div>
  );
}

export default App;
