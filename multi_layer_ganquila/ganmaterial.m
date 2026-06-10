function [Eg, eps, meff, P_sp, P_pz_coeffs] = ganmaterial(x)
% GANMATERIAL - Returns Al(x)Ga(1-x)N parameters
% INPUT: x = Aluminum mole fraction (0.0 to 1.0)

    % 1. Bandgap (Eg)
    Eg_GaN = 3.42;
    Eg_AlN = 6.1;
    b = -1.0; % Bowing parameter
    Eg = x * Eg_AlN + (1-x) * Eg_GaN - b * x * (1-x);

    % 2. Dielectric Constant (epsilon)
    % Interpolate between 8.9 (GaN) and 8.5 (AlN)
    eps = 8.9 * (1-x) + 8.5 * x; 

    % 3. Effective Mass (m*)
    % Linear interpolation between 0.20 (GaN) and 0.32 (AlN)
    meff = 0.20 * (1-x) + 0.32 * x;

    % 4. Spontaneous Polarization (P_sp) 
    P_sp = -0.09*x - 0.034*(1-x) + 0.0191*x*(1-x);

    % 5. Piezoelectric Coefficients
    % We calculate the term 2 * (e31 - e33 * C13/C33) for later use
    % GaN Parameters
    val_GaN = 2 * (-0.338 - 0.667 * (103/405));
    % AlN Parameters
    val_AlN = 2 * (-0.533 - 1.505 * (108/373));
    
    % Interpolate coefficient for AlGaN
    P_pz_coeffs = x * val_AlN + (1-x) * val_GaN;
end