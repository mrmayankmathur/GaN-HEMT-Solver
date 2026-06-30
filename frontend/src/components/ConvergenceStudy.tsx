import React, { useMemo, useState } from "react";
import PlotlyPlot from "react-plotly.js";
import { Play, X, Sparkles, Plus, Download, CheckCircle2, Gauge } from "lucide-react";
import {
  useSimulationStore,
  type ConvergenceRun,
} from "../store/useSimulationStore";
import { formatScientific, nyquistSpacing, suggestSweep } from "../utils/mathUtils";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const Plot = (PlotlyPlot as any).default || PlotlyPlot;

type MetricKey = "ns" | "field" | "peakField" | "iterations" | "runtime";

const METRICS: { key: MetricKey; label: string; unit: string; sci: boolean }[] = [
  { key: "ns", label: "Sheet Density (ns)", unit: "cm⁻²", sci: true },
  { key: "field", label: "Avg Field", unit: "V/cm", sci: true },
  { key: "peakField", label: "Peak Field", unit: "V/cm", sci: true },
  { key: "iterations", label: "Iterations", unit: "", sci: false },
  { key: "runtime", label: "Runtime", unit: "s", sci: false },
];

// Peak |dEc/dz| for a run, in the app's V/cm convention (eV/nm × 1e4, matching
// the backend `slope` scaling so peak/avg field share a scale).
const peakFieldOf = (run: ConvergenceRun): number => {
  let max = 0;
  for (let i = 0; i < run.z.length - 1; i++) {
    const dz = run.z[i + 1] - run.z[i];
    if (dz === 0) continue;
    const grad = Math.abs(((run.ec[i + 1] - run.ec[i]) / dz) * 1e4);
    if (grad > max) max = grad;
  }
  return max;
};

const metricValue = (run: ConvergenceRun, key: MetricKey): number => {
  switch (key) {
    case "ns":
      return run.ns;
    case "field":
      return Math.abs(run.field);
    case "peakField":
      return peakFieldOf(run);
    case "iterations":
      return run.iterations;
    case "runtime":
      return run.runtime;
  }
};

// Coarse (warm) → fine (cool) colour for the band overlay.
const gradeColor = (t: number): string => {
  // t in [0,1], 0 = coarsest, 1 = finest
  const r = Math.round(239 + (59 - 239) * t);
  const g = Math.round(68 + (130 - 68) * t);
  const b = Math.round(68 + (246 - 68) * t);
  return `rgb(${r},${g},${b})`;
};

export const ConvergenceStudy: React.FC = () => {
  const {
    theme,
    layers,
    convergence,
    convergenceGridSpacings,
    convergenceTolerance,
    setConvergenceGridSpacings,
    setConvergenceTolerance,
    runConvergenceStudy,
    setGridSpacing,
  } = useSimulationStore();

  const [metric, setMetric] = useState<MetricKey>("ns");
  const [showEv, setShowEv] = useState(false);
  const [newSpacing, setNewSpacing] = useState("");

  const isRunning = convergence?.isRunning ?? false;
  const runs = convergence?.runs ?? [];
  const nyquist = useMemo(() => nyquistSpacing(layers), [layers]);

  const fontColor = theme === "dark" ? "#a1a1aa" : "#64748b";
  const gridColor = theme === "dark" ? "rgba(255,255,255,0.05)" : "rgba(0,0,0,0.05)";

  const activeMetric = METRICS.find((m) => m.key === metric)!;

  // --- Derived convergence analysis (coarse → fine; finest is the reference) ---
  const analysis = useMemo(() => {
    if (runs.length === 0) return null;
    const sorted = [...runs].sort((a, b) => b.gridSpacing - a.gridSpacing);
    const finest = sorted.reduce((f, r) =>
      r.gridSpacing < f.gridSpacing ? r : f,
    );
    const refVal = metricValue(finest, metric);

    const rows = sorted.map((r) => {
      const val = metricValue(r, metric);
      const pctDelta = refVal !== 0 ? ((val - refVal) / refVal) * 100 : 0;
      const converged = Math.abs(pctDelta) <= convergenceTolerance;
      return { run: r, val, pctDelta, converged };
    });

    // Coarsest mesh that is within tolerance of the finest = best accuracy/cost.
    const recommended = rows.find((row) => row.converged)?.run ?? finest;

    return { sorted, finest, refVal, rows, recommended };
  }, [runs, metric, convergenceTolerance]);

  // --- Sweep editor handlers ---
  const addSpacing = () => {
    const v = parseFloat(newSpacing);
    if (!isNaN(v) && v > 0 && !convergenceGridSpacings.includes(v)) {
      setConvergenceGridSpacings(
        [...convergenceGridSpacings, v].sort((a, b) => b - a),
      );
    }
    setNewSpacing("");
  };

  const removeSpacing = (val: number) =>
    setConvergenceGridSpacings(
      convergenceGridSpacings.filter((s) => s !== val),
    );

  const applyNyquistSweep = () => setConvergenceGridSpacings(suggestSweep(layers));

  const exportCSV = () => {
    if (!analysis) return;
    let csv =
      "GridSpacing(A),Nodes,SheetDensity(cm-2),AvgField(V/cm),PeakField(V/cm),Iterations,Runtime(s),EstMemory(MB),PctDeltaVsFinest,Converged\n";
    for (const { run: r, pctDelta, converged } of analysis.rows) {
      csv += `${r.gridSpacing},${r.nodes},${r.ns},${r.field},${peakFieldOf(r)},${r.iterations},${r.runtime},${r.memoryMb},${pctDelta.toFixed(4)},${converged ? "yes" : "no"}\n`;
    }
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "HEMT_Convergence_Study.csv";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const progressPct =
    convergence && convergence.total > 0
      ? (convergence.progress / convergence.total) * 100
      : 0;

  return (
    <div className="flex flex-col h-full w-full overflow-y-auto no-scrollbar">
      {/* ===== Sweep Editor / Controls ===== */}
      <div className="px-6 py-4 border-b border-slate-100 dark:border-gray-800/50 flex flex-col gap-4">
        <div className="flex items-center justify-between flex-wrap gap-3">
          <span className="text-xs font-bold text-slate-500 dark:text-gray-400 uppercase tracking-widest">
            Grid Spacing Sweep (Å)
          </span>
          <div className="flex items-center gap-2">
            <button
              onClick={applyNyquistSweep}
              disabled={isRunning}
              className="flex items-center gap-1.5 text-xs font-semibold px-3 py-1.5 rounded-lg bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-500/30 hover:bg-indigo-500/20 transition-colors disabled:opacity-40 hover:cursor-pointer"
              title={`Nyquist spacing ≈ ${nyquist.toFixed(2)} Å (½ thinnest layer)`}
            >
              <Sparkles size={13} /> Auto (Nyquist)
            </button>
          </div>
        </div>

        {/* spacing chips */}
        <div className="flex items-center gap-2 flex-wrap">
          {convergenceGridSpacings.map((s) => (
            <span
              key={s}
              className="group flex items-center gap-1.5 text-xs font-mono px-2.5 py-1 rounded-full bg-slate-100 dark:bg-white/5 border border-slate-200/60 dark:border-white/10 text-slate-700 dark:text-slate-300"
            >
              {s}
              <button
                onClick={() => removeSpacing(s)}
                disabled={isRunning}
                className="text-slate-400 hover:text-red-500 transition-colors disabled:opacity-40"
              >
                <X size={12} strokeWidth={2.5} />
              </button>
            </span>
          ))}
          <div className="flex items-center gap-1">
            <input
              type="number"
              step="0.25"
              value={newSpacing}
              onChange={(e) => setNewSpacing(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && addSpacing()}
              placeholder="add"
              disabled={isRunning}
              className="w-16 p-1 text-xs font-mono text-center border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30"
            />
            <button
              onClick={addSpacing}
              disabled={isRunning}
              className="p-1 rounded-lg bg-slate-100 dark:bg-white/5 hover:bg-slate-200 dark:hover:bg-white/10 text-slate-500 transition-colors disabled:opacity-40"
            >
              <Plus size={14} />
            </button>
          </div>
        </div>

        {/* tolerance + run */}
        <div className="flex items-end justify-between flex-wrap gap-4">
          <div className="flex items-end gap-4">
            <div className="flex flex-col gap-1">
              <label className="font-semibold text-[10px] tracking-wider uppercase text-slate-500 dark:text-gray-400 pl-1">
                Tolerance (%)
              </label>
              <input
                type="number"
                step="0.1"
                value={convergenceTolerance}
                onChange={(e) =>
                  setConvergenceTolerance(parseFloat(e.target.value) || 0)
                }
                disabled={isRunning}
                className="w-24 p-2 text-xs font-mono border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="font-semibold text-[10px] tracking-wider uppercase text-slate-500 dark:text-gray-400 pl-1">
                Plot Metric
              </label>
              <select
                value={metric}
                onChange={(e) => setMetric(e.target.value as MetricKey)}
                className="p-2 text-xs font-medium border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30"
              >
                {METRICS.map((m) => (
                  <option key={m.key} value={m.key}>
                    {m.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {runs.length > 0 && !isRunning && (
              <button
                onClick={exportCSV}
                className="flex items-center gap-1.5 text-xs font-semibold px-3 py-2 rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30 hover:bg-emerald-500/20 transition-colors hover:cursor-pointer"
              >
                <Download size={13} /> CSV
              </button>
            )}
            <button
              onClick={runConvergenceStudy}
              disabled={isRunning || convergenceGridSpacings.length === 0}
              className="flex items-center gap-2 text-xs font-bold px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-white transition-colors disabled:opacity-50 hover:cursor-pointer"
            >
              {isRunning ? (
                <span className="animate-pulse">
                  Sweeping {convergence?.progress}/{convergence?.total}…
                </span>
              ) : (
                <>
                  <Play size={13} fill="currentColor" /> Run Convergence Study
                </>
              )}
            </button>
          </div>
        </div>

        {/* progress bar */}
        {isRunning && (
          <div className="h-1.5 w-full rounded-full bg-slate-200 dark:bg-white/5 overflow-hidden">
            <div
              className="h-full bg-blue-500 transition-all duration-500"
              style={{ width: `${progressPct}%` }}
            />
          </div>
        )}
      </div>

      {/* ===== Empty state ===== */}
      {runs.length === 0 && !isRunning && (
        <div className="flex-1 flex flex-col items-center justify-center text-slate-400 gap-2 p-10 text-center">
          <Gauge size={32} strokeWidth={1.5} className="opacity-50" />
          <p className="text-sm">
            Define a grid-spacing sweep and run a convergence study to check
            whether your results are mesh-independent.
          </p>
        </div>
      )}

      {/* ===== Results ===== */}
      {analysis && (
        <div className="flex flex-col gap-6 p-6">
          {/* Recommendation banner */}
          <div className="flex items-center justify-between flex-wrap gap-3 rounded-2xl border border-emerald-500/30 bg-emerald-500/5 px-5 py-3">
            <div className="flex items-center gap-3">
              <CheckCircle2
                size={20}
                className="text-emerald-500 shrink-0"
              />
              <div className="text-sm">
                <span className="font-bold text-slate-700 dark:text-slate-200">
                  Recommended mesh: {analysis.recommended.gridSpacing} Å
                </span>
                <span className="text-slate-500 dark:text-slate-400 ml-2 text-xs">
                  coarsest within ±{convergenceTolerance}% of the finest mesh •{" "}
                  {analysis.recommended.nodes} nodes •{" "}
                  {analysis.recommended.runtime}s
                </span>
              </div>
            </div>
            <button
              onClick={() => setGridSpacing(analysis.recommended.gridSpacing)}
              className="text-xs font-semibold px-3 py-1.5 rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 transition-colors hover:cursor-pointer"
            >
              Apply to Solver
            </button>
          </div>

          {/* Convergence chart */}
          <div className="rounded-2xl border border-slate-100 dark:border-white/5 bg-white/40 dark:bg-white/[0.02] p-3">
            <div className="text-[11px] font-bold text-slate-500 dark:text-gray-400 uppercase tracking-widest px-2 pb-1">
              {activeMetric.label} vs Grid Spacing
            </div>
            <div className="h-72">
              <Plot
                data={[
                  {
                    x: analysis.sorted.map((r) => r.gridSpacing),
                    y: analysis.sorted.map((r) => metricValue(r, metric)),
                    type: "scatter",
                    mode: "lines+markers",
                    name: activeMetric.label,
                    line: { color: "#3b82f6", width: 2 },
                    marker: { size: 8, color: "#3b82f6" },
                  },
                ]}
                layout={{
                  autosize: true,
                  margin: { l: 70, r: 20, t: 10, b: 45 },
                  showlegend: false,
                  xaxis: {
                    title: {
                      text: "Grid Spacing dz (Å) — coarse → fine",
                      font: { color: fontColor, size: 12 },
                    },
                    type: "log",
                    autorange: "reversed",
                    gridcolor: gridColor,
                    tickfont: { color: fontColor },
                  },
                  yaxis: {
                    title: {
                      text: `${activeMetric.label}${activeMetric.unit ? ` (${activeMetric.unit})` : ""}`,
                      font: { color: fontColor, size: 12 },
                    },
                    gridcolor: gridColor,
                    tickfont: { color: fontColor },
                  },
                  plot_bgcolor: "transparent",
                  paper_bgcolor: "transparent",
                  shapes: [
                    // Tolerance band around the finest-mesh value
                    {
                      type: "rect",
                      xref: "paper",
                      yref: "y",
                      x0: 0,
                      x1: 1,
                      y0: analysis.refVal * (1 - convergenceTolerance / 100),
                      y1: analysis.refVal * (1 + convergenceTolerance / 100),
                      fillcolor: "rgba(16, 185, 129, 0.12)",
                      line: { width: 0 },
                      layer: "below",
                    },
                    // Nyquist reference line
                    {
                      type: "line",
                      xref: "x",
                      yref: "paper",
                      x0: nyquist,
                      x1: nyquist,
                      y0: 0,
                      y1: 1,
                      line: { color: "#6366f1", width: 1.5, dash: "dash" },
                    },
                  ],
                  annotations: [
                    {
                      x: Math.log10(nyquist),
                      y: 1,
                      xref: "x",
                      yref: "paper",
                      text: `Nyquist ≈ ${nyquist.toFixed(2)} Å`,
                      showarrow: false,
                      font: { color: "#6366f1", size: 10 },
                      yanchor: "bottom",
                    },
                  ],
                }}
                useResizeHandler
                style={{ width: "100%", height: "100%" }}
                config={{ responsive: true, displayModeBar: false }}
              />
            </div>
          </div>

          {/* Comparison table */}
          <div className="rounded-2xl border border-slate-100 dark:border-white/5 overflow-hidden">
            <div className="text-[11px] font-bold text-slate-500 dark:text-gray-400 uppercase tracking-widest px-4 py-2.5 border-b border-slate-100 dark:border-white/5 bg-white/40 dark:bg-white/[0.02]">
              Mesh Comparison ({activeMetric.label} reference)
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead>
                  <tr className="text-[10px] uppercase tracking-wider text-slate-400 dark:text-gray-500 border-b border-slate-100 dark:border-white/5">
                    <th className="text-left font-semibold px-4 py-2">dz (Å)</th>
                    <th className="text-right font-semibold px-3 py-2">Nodes</th>
                    <th className="text-right font-semibold px-3 py-2">ns (cm⁻²)</th>
                    <th className="text-right font-semibold px-3 py-2">Avg Field</th>
                    <th className="text-right font-semibold px-3 py-2">Iters</th>
                    <th className="text-right font-semibold px-3 py-2">Runtime</th>
                    <th className="text-right font-semibold px-3 py-2">Mem (MB)</th>
                    <th className="text-right font-semibold px-3 py-2">%Δ</th>
                    <th className="text-center font-semibold px-3 py-2">Conv.</th>
                  </tr>
                </thead>
                <tbody className="font-mono text-slate-600 dark:text-slate-300">
                  {analysis.rows.map(({ run: r, pctDelta, converged }) => {
                    const isRec =
                      r.gridSpacing === analysis.recommended.gridSpacing;
                    return (
                      <tr
                        key={r.gridSpacing}
                        className={`border-b border-slate-50 dark:border-white/5 transition-colors ${
                          converged
                            ? "bg-emerald-500/[0.04]"
                            : "hover:bg-slate-50 dark:hover:bg-white/[0.02]"
                        }`}
                      >
                        <td className="px-4 py-2 font-bold text-slate-700 dark:text-slate-200">
                          {r.gridSpacing}
                          {isRec && (
                            <span className="ml-1.5 text-[9px] font-sans font-bold text-emerald-600 dark:text-emerald-400 uppercase">
                              ★ rec
                            </span>
                          )}
                        </td>
                        <td className="px-3 py-2 text-right">{r.nodes}</td>
                        <td className="px-3 py-2 text-right">
                          {formatScientific(r.ns)}
                        </td>
                        <td className="px-3 py-2 text-right">
                          {formatScientific(Math.abs(r.field))}
                        </td>
                        <td className="px-3 py-2 text-right">{r.iterations}</td>
                        <td className="px-3 py-2 text-right">{r.runtime}s</td>
                        <td className="px-3 py-2 text-right">{r.memoryMb}</td>
                        <td
                          className={`px-3 py-2 text-right ${
                            converged
                              ? "text-emerald-600 dark:text-emerald-400"
                              : "text-amber-600 dark:text-amber-400"
                          }`}
                        >
                          {pctDelta >= 0 ? "+" : ""}
                          {pctDelta.toFixed(2)}%
                        </td>
                        <td className="px-3 py-2 text-center">
                          {converged ? "✓" : "✗"}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>

          {/* Band-diagram overlay */}
          <div className="rounded-2xl border border-slate-100 dark:border-white/5 bg-white/40 dark:bg-white/[0.02] p-3">
            <div className="flex items-center justify-between px-2 pb-1">
              <div className="text-[11px] font-bold text-slate-500 dark:text-gray-400 uppercase tracking-widest">
                Band Diagram Overlay (Ec{showEv ? " + Ev" : ""})
              </div>
              <label className="flex items-center gap-1.5 text-[11px] text-slate-500 dark:text-gray-400 cursor-pointer">
                <input
                  type="checkbox"
                  checked={showEv}
                  onChange={(e) => setShowEv(e.target.checked)}
                  className="accent-blue-500"
                />
                Show Ev
              </label>
            </div>
            <div className="h-80">
              <Plot
                data={analysis.sorted.flatMap((r, i) => {
                  const t =
                    analysis.sorted.length > 1
                      ? i / (analysis.sorted.length - 1)
                      : 1;
                  const color = gradeColor(t);
                  const traces: Partial<Plotly.ScatterData>[] = [
                    {
                      x: r.z,
                      y: r.ec,
                      type: "scatter",
                      mode: "lines",
                      name: `Ec @ ${r.gridSpacing}Å`,
                      line: { color, width: 1.5 },
                    },
                  ];
                  if (showEv) {
                    traces.push({
                      x: r.z,
                      y: r.ev,
                      type: "scatter",
                      mode: "lines",
                      name: `Ev @ ${r.gridSpacing}Å`,
                      line: { color, width: 1.5, dash: "dot" },
                      showlegend: false,
                    });
                  }
                  return traces;
                })}
                layout={{
                  autosize: true,
                  margin: { l: 60, r: 20, t: 10, b: 45 },
                  showlegend: true,
                  legend: { font: { color: fontColor, size: 9 } },
                  xaxis: {
                    title: { text: "Depth (nm)", font: { color: fontColor, size: 12 } },
                    gridcolor: gridColor,
                    tickfont: { color: fontColor },
                  },
                  yaxis: {
                    title: { text: "Energy (eV)", font: { color: fontColor, size: 12 } },
                    gridcolor: gridColor,
                    tickfont: { color: fontColor },
                  },
                  plot_bgcolor: "transparent",
                  paper_bgcolor: "transparent",
                  hovermode: "x unified",
                }}
                useResizeHandler
                style={{ width: "100%", height: "100%" }}
                config={{ responsive: true, displayModeBar: false }}
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
