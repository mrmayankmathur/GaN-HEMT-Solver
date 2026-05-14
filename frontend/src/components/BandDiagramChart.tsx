import React, { useState, useEffect, useMemo } from "react";
import PlotlyPlot from "react-plotly.js";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const Plot = (PlotlyPlot as any).default || PlotlyPlot;
import { useSimulationStore } from "../store/useSimulationStore";

export const BandDiagramChart: React.FC = () => {
  const { results, theme } = useSimulationStore();
  const [drawIndex, setDrawIndex] = useState(0);
  const [prevResults, setPrevResults] = useState(results);

  if (results !== prevResults) {
    setPrevResults(results);
    setDrawIndex(0);
  }

  useEffect(() => {
    if (!results || results.z.length === 0 || results.isRunning) {
      return;
    }

    let animationFrameId: number;
    const totalPoints = results.z.length;
    const duration = 1200;
    const startTime = performance.now();

    const animate = (time: number) => {
      const elapsed = time - startTime;
      const progress = Math.min(elapsed / duration, 1);

      const easeOut = 1 - Math.pow(1 - progress, 4);
      setDrawIndex(Math.max(2, Math.floor(easeOut * totalPoints)));

      if (progress < 1) {
        animationFrameId = requestAnimationFrame(animate);
      }
    };

    animationFrameId = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(animationFrameId);
  }, [results]);

  const axisRanges = useMemo(() => {
    if (!results || results.z.length === 0) return null;

    const maxEc = results.ec.reduce(
      (max, val) => Math.max(max, val),
      -Infinity,
    );
    const minEv = results.ev.reduce((min, val) => Math.min(min, val), Infinity);

    return {
      x: [results.z[0], results.z[results.z.length - 1]],
      y: [minEv - 0.5, maxEc + 0.5],
    };
  }, [results]);

  if (!results || results.z.length === 0 || !axisRanges) {
    return (
      <div className="flex items-center justify-center h-full text-slate-400">
        Run simulation to see data
      </div>
    );
  }

  const fontColor = theme === "dark" ? "#a1a1aa" : "#64748b";
  const gridColor =
    theme === "dark" ? "rgba(255,255,255,0.05)" : "rgba(0,0,0,0.05)";

  // 🚨 NEW: Pass empty arrays to Plotly while the simulation is calculating
  const isRunning = results.isRunning;
  const currentZ = isRunning ? [] : results.z.slice(0, drawIndex);
  const currentEc = isRunning ? [] : results.ec.slice(0, drawIndex);
  const currentEv = isRunning ? [] : results.ev.slice(0, drawIndex);
  const fermiX = isRunning ? [] : axisRanges.x; // Hides the Fermi line while calculating

  return (
    <div className="w-full h-full relative">
      {results?.isRunning && (
        <div className="absolute inset-0 z-10 flex items-center justify-center bg-black/10 backdrop-blur-[1px]">
          <div className="text-xs font-mono animate-pulse">
            SOLVING POISSON-SCHRODINGER...
          </div>
        </div>
      )}
      <Plot
        data={[
          {
            x: currentZ,
            y: currentEc,
            type: "scatter",
            mode: "lines",
            name: "Ec",
            line: { color: "#3b82f6", width: 2 },
          },
          {
            x: currentZ,
            y: currentEv,
            type: "scatter",
            mode: "lines",
            name: "Ev",
            line: { color: "#22c55e", width: 2 },
          },
          {
            x: fermiX,
            y: [0, 0],
            type: "scatter",
            mode: "lines",
            name: "Ef",
            line: { color: "#ef4444", width: 1, dash: "dot" },
            hoverinfo: "skip",
          },
        ]}
        layout={{
          autosize: true,
          margin: { l: 60, r: 20, t: 10, b: 40 },
          showlegend: true,
          legend: {
            x: 0.85,
            y: 0.95,
            bgcolor: "transparent",
            font: { color: fontColor },
          },
          xaxis: {
            title: {
              text: "Depth (nm)",
              font: {
                color: fontColor,
                size: 13,
                family: "system-ui, sans-serif",
              },
            },
            gridcolor: gridColor,
            tickfont: { color: fontColor },
            range: axisRanges.x,
          },
          yaxis: {
            title: {
              text: "Energy (eV)",
              font: {
                color: fontColor,
                size: 13,
                family: "system-ui, sans-serif",
              },
            },
            gridcolor: gridColor,
            tickfont: { color: fontColor },
            range: axisRanges.y,
          },
          plot_bgcolor: "transparent",
          paper_bgcolor: "transparent",
          hovermode: "x unified",
        }}
        useResizeHandler={true}
        style={{ width: "100%", height: "100%" }}
        config={{ responsive: true, displayModeBar: false }}
      />
    </div>
  );
};
