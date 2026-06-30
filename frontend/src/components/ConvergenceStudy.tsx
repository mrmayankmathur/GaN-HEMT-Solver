import React, { useMemo, useState, useRef, useEffect } from "react";
import PlotlyPlot from "react-plotly.js";
import { Play, X, Sparkles, Plus, Download, CheckCircle2, Gauge, AlertTriangle, ChevronDown, Check } from "lucide-react";
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

// Metric colours for multi-metric chart traces
const METRIC_COLORS: Record<MetricKey, string> = {
  ns: "#3b82f6",
  field: "#f59e0b",
  peakField: "#ef4444",
  iterations: "#8b5cf6",
  runtime: "#10b981",
};

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

/** Row data produced by the analysis pass. */
interface AnalysisRow {
  run: ConvergenceRun;
  val: number;           // metric value for the selected convergence metric
  pctDelta: number;      // % Δ vs finest mesh
  pctSuccessive: number | null;  // % Δ vs next-finer mesh (null for the finest)
  converged: boolean;    // |pctDelta| ≤ tolerance
  stableConverged: boolean; // converged AND all finer meshes also converged
}

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

  // Multi-metric checkboxes for the chart (refinement #3)
  const [selectedMetrics, setSelectedMetrics] = useState<Set<MetricKey>>(
    () => new Set<MetricKey>(["ns"]),
  );
  // The "primary" metric drives the table's %Δ columns and the recommendation.
  // Default to "ns" — the most critical convergence indicator.
  const [primaryMetric, setPrimaryMetric] = useState<MetricKey>("ns");
  const [showEv, setShowEv] = useState(false);
  const [newSpacing, setNewSpacing] = useState("");
  const [metricsDropdownOpen, setMetricsDropdownOpen] = useState(false);
  const metricsDropdownRef = useRef<HTMLDivElement>(null);

  // Close dropdown on click outside
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (metricsDropdownRef.current && !metricsDropdownRef.current.contains(e.target as Node)) {
        setMetricsDropdownOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const isRunning = convergence?.isRunning ?? false;
  const runs = convergence?.runs ?? [];
  const nyquist = useMemo(() => nyquistSpacing(layers), [layers]);

  const fontColor = theme === "dark" ? "#a1a1aa" : "#64748b";
  const gridColor = theme === "dark" ? "rgba(255,255,255,0.05)" : "rgba(0,0,0,0.05)";

  const primaryMeta = METRICS.find((m) => m.key === primaryMetric)!;

  // Toggle a metric in the chart selection; ensure at least one stays selected
  const toggleMetric = (key: MetricKey) => {
    setSelectedMetrics((prev) => {
      const next = new Set(prev);
      if (next.has(key)) {
        if (next.size > 1) next.delete(key);
      } else {
        next.add(key);
      }
      return next;
    });
  };

  // --- Derived convergence analysis ---
  // Sorts coarse → fine. Computes both Δ-vs-finest and Δ-vs-next-finer.
  // Recommendation uses stable convergence (refinement #2):
  //   coarsest mesh whose error remains below tolerance for ALL finer meshes.
  const analysis = useMemo(() => {
    if (runs.length === 0) return null;
    const sorted = [...runs].sort((a, b) => b.gridSpacing - a.gridSpacing);
    const finest = sorted.reduce((f, r) =>
      r.gridSpacing < f.gridSpacing ? r : f,
    );
    const refVal = metricValue(finest, primaryMetric);

    // Build rows with both delta columns
    const rows: AnalysisRow[] = sorted.map((r, i) => {
      const val = metricValue(r, primaryMetric);
      const pctDelta = refVal !== 0 ? ((val - refVal) / refVal) * 100 : 0;
      const converged = Math.abs(pctDelta) <= convergenceTolerance;

      // Successive delta: compare to the next-finer mesh (i+1 in coarse→fine order)
      let pctSuccessive: number | null = null;
      if (i < sorted.length - 1) {
        const nextFiner = sorted[i + 1];
        const nextVal = metricValue(nextFiner, primaryMetric);
        pctSuccessive = nextVal !== 0 ? ((val - nextVal) / nextVal) * 100 : 0;
      }

      return { run: r, val, pctDelta, pctSuccessive, converged, stableConverged: false };
    });

    // Stable convergence flag: walk from finest → coarsest, propagating
    // "all finer meshes converged" upward. (refinement #2)
    let allFinerConverged = true;
    for (let i = rows.length - 1; i >= 0; i--) {
      if (rows[i].converged && allFinerConverged) {
        rows[i].stableConverged = true;
      } else {
        allFinerConverged = false;
        rows[i].stableConverged = false;
      }
    }

    // Recommendation: coarsest mesh that is stably converged.
    const recommended =
      rows.find((row) => row.stableConverged)?.run ?? finest;

    // Compute the recommended row's error for the summary card
    const recRow = rows.find((row) => row.run.gridSpacing === recommended.gridSpacing)!;
    const isStable = recRow.stableConverged;

    return { sorted, finest, refVal, rows, recommended, recRow, isStable };
  }, [runs, primaryMetric, convergenceTolerance]);

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

  // CSV export with metadata header (refinement #8)
  const exportCSV = () => {
    if (!analysis) return;
    const now = new Date().toISOString().split("T")[0];
    let csv = "";
    // Metadata block
    csv += `# HEMT Convergence Study\n`;
    csv += `# Generated: ${now}\n`;
    csv += `# Tolerance: ${convergenceTolerance}%\n`;
    csv += `# Nyquist spacing: ${nyquist.toFixed(2)} Å\n`;
    csv += `# Recommended mesh: ${analysis.recommended.gridSpacing} Å\n`;
    csv += `# Primary metric: ${primaryMeta.label}\n`;
    csv += `# Convergence status: ${analysis.isStable ? "Converged" : "Not fully converged"}\n`;
    csv += `#\n`;
    // Data header
    csv +=
      "GridSpacing(A),Nodes,SheetDensity(cm-2),AvgField(V/cm),PeakField(V/cm),Iterations,Runtime(s),EstSolverMemory(MB),PctDeltaVsFinest,PctDeltaVsNextFiner,StablyConverged\n";
    for (const { run: r, pctDelta, pctSuccessive, stableConverged } of analysis.rows) {
      csv += `${r.gridSpacing},${r.nodes},${r.ns},${r.field},${peakFieldOf(r)},${r.iterations},${r.runtime},${r.memoryMb},${pctDelta.toFixed(4)},${pctSuccessive !== null ? pctSuccessive.toFixed(4) : ""},${stableConverged ? "yes" : "no"}\n`;
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

  // Determine if runtime is among selected metrics (needs secondary Y-axis)
  const hasRuntime = selectedMetrics.has("runtime");
  // "Physical" metrics are everything except runtime
  const physicalMetrics = [...selectedMetrics].filter((k) => k !== "runtime");

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

        {/* tolerance + metric checkboxes + run */}
        <div className="flex items-end justify-between flex-wrap gap-4">
          <div className="flex items-end gap-4 flex-wrap">
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
            {/* Multi-metric dropdown selector */}
            <div className="flex flex-col gap-1 relative" ref={metricsDropdownRef}>
              <label className="font-semibold text-[10px] tracking-wider uppercase text-slate-500 dark:text-gray-400 pl-1">
                Chart Metrics
              </label>
              <button
                type="button"
                onClick={() => setMetricsDropdownOpen((o) => !o)}
                className="p-2 text-xs font-medium border border-slate-300/60 dark:border-gray-700 rounded-lg bg-white dark:bg-[#1a1a1a] text-slate-700 dark:text-gray-200 outline-none focus:ring-2 focus:ring-blue-500/30 flex items-center gap-1.5 min-w-40 justify-between hover:cursor-pointer"
              >
                <span className="truncate">
                  {selectedMetrics.size === METRICS.length
                    ? "All metrics"
                    : [...selectedMetrics]
                        .map((k) => METRICS.find((m) => m.key === k)!.label)
                        .join(", ")}
                </span>
                <ChevronDown
                  size={13}
                  className={`shrink-0 opacity-60 transition-transform duration-200 ${
                    metricsDropdownOpen ? "rotate-180" : ""
                  }`}
                />
              </button>
              {metricsDropdownOpen && (
                <div className="absolute top-full left-0 mt-1 z-50 w-56 rounded-xl bg-white/95 dark:bg-[#1a1a1a]/95 backdrop-blur-xl shadow-lg ring-1 ring-black/5 dark:ring-white/10 border border-slate-200/60 dark:border-white/10 py-1 animate-fadeIn">
                  {METRICS.map((m) => {
                    const isSelected = selectedMetrics.has(m.key);
                    const isOnly = isSelected && selectedMetrics.size === 1;
                    return (
                      <button
                        key={m.key}
                        type="button"
                        onClick={() => toggleMetric(m.key)}
                        disabled={isOnly}
                        className={`w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium transition-colors hover:cursor-pointer ${
                          isSelected
                            ? "text-slate-800 dark:text-slate-100"
                            : "text-slate-500 dark:text-slate-400"
                        } ${
                          isOnly
                            ? "opacity-50 cursor-not-allowed"
                            : "hover:bg-slate-50 dark:hover:bg-white/5"
                        }`}
                      >
                        <span
                          className="w-4 h-4 rounded flex items-center justify-center shrink-0 border transition-colors"
                          style={{
                            borderColor: METRIC_COLORS[m.key],
                            backgroundColor: isSelected ? METRIC_COLORS[m.key] + "20" : "transparent",
                          }}
                        >
                          {isSelected && <Check size={11} strokeWidth={3} style={{ color: METRIC_COLORS[m.key] }} />}
                        </span>
                        <span
                          className="border-b-2 pb-px"
                          style={{ borderColor: METRIC_COLORS[m.key] }}
                        >
                          {m.label}
                        </span>
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
            {/* Primary metric for recommendation / table deltas */}
            <div className="flex flex-col gap-1">
              <label className="font-semibold text-[10px] tracking-wider uppercase text-slate-500 dark:text-gray-400 pl-1">
                Convergence Ref.
              </label>
              <select
                value={primaryMetric}
                onChange={(e) => setPrimaryMetric(e.target.value as MetricKey)}
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
          {/* ===== Summary card (refinement #5) ===== */}
          <div
            className={`rounded-2xl border px-5 py-4 ${
              analysis.isStable
                ? "border-emerald-500/30 bg-emerald-500/5"
                : "border-amber-500/30 bg-amber-500/5"
            }`}
          >
            <div className="flex items-start justify-between flex-wrap gap-4">
              <div className="flex items-start gap-3">
                {analysis.isStable ? (
                  <CheckCircle2
                    size={22}
                    className="text-emerald-500 shrink-0 mt-0.5"
                  />
                ) : (
                  <AlertTriangle
                    size={22}
                    className="text-amber-500 shrink-0 mt-0.5"
                  />
                )}
                <div>
                  <div className="text-sm font-bold text-slate-700 dark:text-slate-200 mb-2">
                    Recommended Mesh
                  </div>
                  <div className="grid grid-cols-2 sm:grid-cols-5 gap-x-6 gap-y-2">
                    <div>
                      <div className="text-[10px] uppercase font-bold text-slate-400 dark:text-slate-500 tracking-wider">
                        Grid Spacing
                      </div>
                      <div className="text-sm font-mono font-bold text-slate-700 dark:text-slate-200">
                        {analysis.recommended.gridSpacing} Å
                      </div>
                    </div>
                    <div>
                      <div className="text-[10px] uppercase font-bold text-slate-400 dark:text-slate-500 tracking-wider">
                        Nodes
                      </div>
                      <div className="text-sm font-mono font-bold text-slate-700 dark:text-slate-200">
                        {analysis.recommended.nodes.toLocaleString()}
                      </div>
                    </div>
                    <div>
                      <div className="text-[10px] uppercase font-bold text-slate-400 dark:text-slate-500 tracking-wider">
                        Runtime
                      </div>
                      <div className="text-sm font-mono font-bold text-slate-700 dark:text-slate-200">
                        {analysis.recommended.runtime} s
                      </div>
                    </div>
                    <div>
                      <div className="text-[10px] uppercase font-bold text-slate-400 dark:text-slate-500 tracking-wider">
                        Error ({primaryMeta.label})
                      </div>
                      <div className="text-sm font-mono font-bold text-slate-700 dark:text-slate-200">
                        {Math.abs(analysis.recRow.pctDelta).toFixed(2)}%
                      </div>
                    </div>
                    <div>
                      <div className="text-[10px] uppercase font-bold text-slate-400 dark:text-slate-500 tracking-wider">
                        Status
                      </div>
                      <div
                        className={`text-sm font-bold ${
                          analysis.isStable
                            ? "text-emerald-600 dark:text-emerald-400"
                            : "text-amber-600 dark:text-amber-400"
                        }`}
                      >
                        {analysis.isStable ? "Converged" : "Not converged"}
                      </div>
                    </div>
                  </div>
                  {!analysis.isStable && (
                    <p className="text-[11px] text-amber-600 dark:text-amber-400 mt-2">
                      Oscillatory or non-monotonic convergence detected — the recommended
                      mesh is the finest available. Consider extending the sweep to finer spacings.
                    </p>
                  )}
                </div>
              </div>
              <button
                onClick={() => setGridSpacing(analysis.recommended.gridSpacing)}
                className="text-xs font-semibold px-3 py-1.5 rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 transition-colors hover:cursor-pointer shrink-0"
              >
                Apply to Solver
              </button>
            </div>
          </div>

          {/* ===== Convergence chart (multi-metric with secondary Y for runtime) ===== */}
          <div className="rounded-2xl border border-slate-100 dark:border-white/5 bg-white/40 dark:bg-white/2 p-3">
            <div className="text-[11px] font-bold text-slate-500 dark:text-gray-400 uppercase tracking-widest px-2 pb-1">
              Convergence Chart
            </div>
            <div className="h-80">
              <Plot
                data={[
                  // Physical metrics on primary Y-axis
                  ...physicalMetrics.map((key) => {
                    const meta = METRICS.find((m) => m.key === key)!;
                    return {
                      x: analysis.sorted.map((r) => r.gridSpacing),
                      y: analysis.sorted.map((r) => metricValue(r, key)),
                      type: "scatter" as const,
                      mode: "lines+markers" as const,
                      name: meta.label,
                      line: { color: METRIC_COLORS[key], width: 2 },
                      marker: { size: 7, color: METRIC_COLORS[key] },
                      yaxis: "y",
                    };
                  }),
                  // Runtime on secondary Y-axis (refinement #6)
                  ...(hasRuntime
                    ? [
                        {
                          x: analysis.sorted.map((r) => r.gridSpacing),
                          y: analysis.sorted.map((r) => r.runtime),
                          type: "scatter" as const,
                          mode: "lines+markers" as const,
                          name: "Runtime",
                          line: { color: METRIC_COLORS.runtime, width: 2, dash: "dot" as const },
                          marker: { size: 7, color: METRIC_COLORS.runtime },
                          yaxis: "y2",
                        },
                      ]
                    : []),
                ]}
                layout={{
                  autosize: true,
                  margin: { l: 70, r: hasRuntime ? 70 : 20, t: 10, b: 45 },
                  showlegend: true,
                  legend: { font: { color: fontColor, size: 10 }, orientation: "h", y: -0.2 },
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
                      text:
                        physicalMetrics.length === 1
                          ? `${METRICS.find((m) => m.key === physicalMetrics[0])!.label}${METRICS.find((m) => m.key === physicalMetrics[0])!.unit ? ` (${METRICS.find((m) => m.key === physicalMetrics[0])!.unit})` : ""}`
                          : "Value",
                      font: { color: fontColor, size: 12 },
                    },
                    gridcolor: gridColor,
                    tickfont: { color: fontColor },
                  },
                  // Secondary Y-axis for runtime (refinement #6)
                  ...(hasRuntime
                    ? {
                        yaxis2: {
                          title: {
                            text: "Runtime (s)",
                            font: { color: METRIC_COLORS.runtime, size: 12 },
                          },
                          overlaying: "y" as const,
                          side: "right" as const,
                          gridcolor: "transparent",
                          tickfont: { color: METRIC_COLORS.runtime },
                        },
                      }
                    : {}),
                  plot_bgcolor: "transparent",
                  paper_bgcolor: "transparent",
                  shapes: [
                    // Tolerance band around the finest-mesh value of the primary metric
                    {
                      type: "rect" as const,
                      xref: "paper" as const,
                      yref: "y" as const,
                      x0: 0,
                      x1: 1,
                      y0: analysis.refVal * (1 - convergenceTolerance / 100),
                      y1: analysis.refVal * (1 + convergenceTolerance / 100),
                      fillcolor: "rgba(16, 185, 129, 0.12)",
                      line: { width: 0 },
                      layer: "below" as const,
                    },
                    // Nyquist reference line
                    {
                      type: "line" as const,
                      xref: "x" as const,
                      yref: "paper" as const,
                      x0: nyquist,
                      x1: nyquist,
                      y0: 0,
                      y1: 1,
                      line: { color: "#6366f1", width: 1.5, dash: "dash" as const },
                    },
                  ],
                  // Informative Nyquist annotation (refinement #4)
                  annotations: [
                    {
                      x: Math.log10(nyquist),
                      y: 1,
                      xref: "x" as const,
                      yref: "paper" as const,
                      text: `<b>Nyquist spacing</b><br>= thinnest layer / 2 ≈ ${nyquist.toFixed(2)} Å<br><i>Recommended max spacing</i>`,
                      showarrow: true,
                      arrowhead: 2,
                      arrowsize: 0.8,
                      arrowcolor: "#6366f1",
                      ax: 40,
                      ay: 20,
                      font: { color: "#6366f1", size: 10 },
                      align: "left" as const,
                      bgcolor: theme === "dark" ? "rgba(30,30,30,0.85)" : "rgba(255,255,255,0.9)",
                      bordercolor: "#6366f1",
                      borderwidth: 1,
                      borderpad: 4,
                    },
                  ],
                }}
                useResizeHandler
                style={{ width: "100%", height: "100%" }}
                config={{ responsive: true, displayModeBar: false }}
              />
            </div>
          </div>

          {/* ===== Comparison table (with both Δ columns, refinement #1) ===== */}
          <div className="rounded-2xl border border-slate-100 dark:border-white/5 overflow-hidden">
            <div className="text-[11px] font-bold text-slate-500 dark:text-gray-400 uppercase tracking-widest px-4 py-2.5 border-b border-slate-100 dark:border-white/5 bg-white/40 dark:bg-white/2">
              Mesh Comparison ({primaryMeta.label} reference)
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
                    <th className="text-right font-semibold px-3 py-2">Est. Memory (MB)</th>
                    <th className="text-right font-semibold px-3 py-2" title="Percentage difference compared to the finest mesh">Δ vs Finest</th>
                    <th className="text-right font-semibold px-3 py-2" title="Percentage difference compared to the next-finer mesh">Δ vs Next Finer</th>
                    <th className="text-center font-semibold px-3 py-2" title="Stably converged: within tolerance for this AND all finer meshes">Conv.</th>
                  </tr>
                </thead>
                <tbody className="font-mono text-slate-600 dark:text-slate-300">
                  {analysis.rows.map(({ run: r, pctDelta, pctSuccessive, stableConverged }) => {
                    const isRec =
                      r.gridSpacing === analysis.recommended.gridSpacing;
                    return (
                      <tr
                        key={r.gridSpacing}
                        className={`border-b border-slate-50 dark:border-white/5 transition-colors ${
                          stableConverged
                            ? "bg-emerald-500/4"
                            : "hover:bg-slate-50 dark:hover:bg-white/2"
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
                        {/* Δ vs finest (refinement #1) */}
                        <td
                          className={`px-3 py-2 text-right ${
                            Math.abs(pctDelta) <= convergenceTolerance
                              ? "text-emerald-600 dark:text-emerald-400"
                              : "text-amber-600 dark:text-amber-400"
                          }`}
                        >
                          {pctDelta >= 0 ? "+" : ""}
                          {pctDelta.toFixed(2)}%
                        </td>
                        {/* Δ vs next finer (refinement #1) */}
                        <td
                          className={`px-3 py-2 text-right ${
                            pctSuccessive === null
                              ? "text-slate-300 dark:text-slate-600"
                              : Math.abs(pctSuccessive) <= convergenceTolerance
                                ? "text-emerald-600 dark:text-emerald-400"
                                : "text-amber-600 dark:text-amber-400"
                          }`}
                        >
                          {pctSuccessive !== null
                            ? `${pctSuccessive >= 0 ? "+" : ""}${pctSuccessive.toFixed(2)}%`
                            : "—"}
                        </td>
                        {/* Stable convergence indicator (refinement #2) */}
                        <td className="px-3 py-2 text-center">
                          {stableConverged ? "✓" : "✗"}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>

          {/* Band-diagram overlay */}
          <div className="rounded-2xl border border-slate-100 dark:border-white/5 bg-white/40 dark:bg-white/2 p-3">
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
