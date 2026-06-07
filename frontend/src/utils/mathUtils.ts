import type { SimulationResult } from "../store/useSimulationStore";

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
