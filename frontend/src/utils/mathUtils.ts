import React from "react";
import type { Layer, SimulationResult } from "../store/useSimulationStore";

/**
 * Render a number in "base × 10^exp" form for display.
 * Lifted from App.tsx so the convergence view can share it.
 */
export const formatScientific = (value: number | undefined): React.ReactNode => {
  if (!value) {
    return React.createElement(
      "span",
      null,
      "0.000 × 10",
      React.createElement("sup", null, "0"),
    );
  }
  const [base, exponent] = value.toExponential(3).split("e");
  return React.createElement(
    "span",
    null,
    `${base} × 10`,
    React.createElement("sup", null, parseInt(exponent, 10)),
  );
};

/**
 * Nyquist grid spacing (Å): half the thinnest physical feature in the stack.
 * To resolve a layer of thickness t, the mesh must sample it at least twice,
 * so dz ≤ t/2. Layer thickness is stored in nm → ×10 for Å.
 */
export const nyquistSpacing = (layers: Layer[]): number => {
  const thinnest = layers.reduce(
    (min, l) => (l.thickness > 0 ? Math.min(min, l.thickness) : min),
    Infinity,
  );
  if (!isFinite(thinnest)) return 2.5;
  return (thinnest * 10) / 2;
};

/**
 * Suggest a coarse → fine geometric sweep of grid spacings (Å) anchored to the
 * Nyquist spacing. Spans roughly 5 Å (or 2× Nyquist, whichever is larger) down
 * to ~Nyquist/2, giving points on both sides of the Nyquist reference.
 */
export const suggestSweep = (layers: Layer[]): number[] => {
  const nyq = nyquistSpacing(layers);
  const coarse = Math.max(5, nyq * 2);
  const fine = Math.max(0.25, nyq / 2);

  const STEPS = 7;
  const ratio = Math.pow(fine / coarse, 1 / (STEPS - 1));
  const sweep: number[] = [];
  for (let i = 0; i < STEPS; i++) {
    const val = coarse * Math.pow(ratio, i);
    sweep.push(Math.round(val * 100) / 100); // 2 decimal places
  }
  // De-duplicate in case rounding collapses neighbours
  return Array.from(new Set(sweep));
};

/**
 * Computes average electric field and sheet density for a specific sub-region.
 * Returns null if region is invalid or not enough points.
 */
export const computeRegionMetrics = (
  results: SimulationResult | null,
  regionLimits: [number, number] | null,
): { slope: number; ns: number } | null => {
  if (!results || !results.z || results.z.length === 0) return null;

  let zSub: number[] = results.z;
  let ecSub: number[] = results.ec;
  let nSub: number[] = results.n;

  if (regionLimits) {
    const minZ = Math.min(regionLimits[0], regionLimits[1]);
    const maxZ = Math.max(regionLimits[0], regionLimits[1]);

    const indices = [];
    for (let i = 0; i < results.z.length; i++) {
      if (results.z[i] >= minZ && results.z[i] <= maxZ) {
        indices.push(i);
      }
    }

    if (indices.length < 2) return null;

    zSub = indices.map((i) => results.z[i]);
    ecSub = indices.map((i) => results.ec[i]);
    nSub = indices.map((i) => results.n[i]);
  }

  if (zSub.length < 2) return null;

  // 1. Average Electric Field (Slope) in V/cm
  // EC is in eV, Z is in nm. 1 eV/nm = 1e7 V/cm.
  // The backend scales it as (dEc / dz) * 1e4 because backend Z is in Angstroms inside the arrays.
  // Wait, in frontend results.z is in nm.
  const dz_nm = zSub[zSub.length - 1] - zSub[0];
  const dEc = ecSub[ecSub.length - 1] - ecSub[0];
  // 1 eV / 1 nm = 1e7 V/cm
  const slope = (dEc / dz_nm) * 1e4;

  // 2. Sheet Density via Trapezoidal integration
  // We need to integrate n(z) dz.
  // Here backend n(z) is in cm^-3. dz is in nm.
  // To get cm^-2, we must multiply by 1e-7 (since 1 nm = 1e-7 cm).
  let ns = 0;
  for (let i = 0; i < zSub.length - 1; i++) {
    const dz_cm = (zSub[i + 1] - zSub[i]) * 1e-7;
    const avgN = (nSub[i] + nSub[i + 1]) / 2.0;
    ns += avgN * dz_cm;
  }

  return { slope, ns };
};
