import React, { useState, useEffect, useMemo } from "react";
import PlotlyPlot from "react-plotly.js";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const Plot = (PlotlyPlot as any).default || PlotlyPlot;
import { useSimulationStore } from "../store/useSimulationStore";

export const BandDiagramChart: React.FC = () => {
  const { results, theme, isRegionSelectionMode, ebdLimits, setEbdLimits } = useSimulationStore();
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
    // Speed up rendering when not first loading
    const duration = isRegionSelectionMode ? 0 : 1200;
    const startTime = performance.now();

    const animate = (time: number) => {
      const elapsed = time - startTime;
      const progress = duration === 0 ? 1 : Math.min(elapsed / duration, 1);

      const easeOut = 1 - Math.pow(1 - progress, 4);
      setDrawIndex(Math.max(2, Math.floor(easeOut * totalPoints)));

      if (progress < 1) {
        animationFrameId = requestAnimationFrame(animate);
      }
    };

    animationFrameId = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(animationFrameId);
  }, [results, isRegionSelectionMode]);

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

  const isRunning = results.isRunning;
  const currentZ = isRunning ? [] : results.z.slice(0, drawIndex);
  const currentEc = isRunning ? [] : results.ec.slice(0, drawIndex);
  const currentEv = isRunning ? [] : results.ev.slice(0, drawIndex);
  const fermiX = isRunning ? [] : axisRanges.x;

  const handleSelected = (event: Readonly<Plotly.PlotSelectionEvent>) => {
    if (event && event.range && event.range.x) {
       const xRange = event.range.x as [number, number];
       // clamp inside physical bounds
       const minPossible = results.z[0];
       const maxPossible = results.z[results.z.length - 1];

       const x0 = Math.max(minPossible, Math.min(xRange[0], xRange[1]));
       const x1 = Math.min(maxPossible, Math.max(xRange[0], xRange[1]));
       setEbdLimits([x0, x1]);
    }
  };

  // Build the highlight shape if region mode is active
  const shapes: Partial<Plotly.Shape>[] = [];
  if (isRegionSelectionMode && ebdLimits) {
     shapes.push({
        type: 'rect',
        xref: 'x',
        yref: 'paper',
        x0: ebdLimits[0],
        x1: ebdLimits[1],
        y0: 0,
        y1: 1,
        fillcolor: 'rgba(99, 102, 241, 0.15)', // Indigo
        line: { width: 0 },
        layer: 'below'
     });
  }

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
            fixedrange: isRegionSelectionMode, // Locks zooming/panning in X when selection mode is ON
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
            fixedrange: isRegionSelectionMode, // Lock zooming Y
          },
          plot_bgcolor: "transparent",
          paper_bgcolor: "transparent",
          hovermode: "x unified",
          dragmode: isRegionSelectionMode ? "select" : "zoom",
          shapes: shapes,
        }}
        useResizeHandler={true}
        onSelected={isRegionSelectionMode ? handleSelected : undefined}
        style={{ width: "100%", height: "100%" }}
        config={{ responsive: true, displayModeBar: false }}
      />
    </div>
  );
};