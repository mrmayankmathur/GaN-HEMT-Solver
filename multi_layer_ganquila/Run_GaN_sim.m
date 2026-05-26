function [z_out, Ec_out, Ev_out, n_out, ns_out, slope_out] = Run_GaN_sim(input_layers, phi_b)
    % Run_GaN_sim: Self-consistent solver for HEMT stacks

    global aquila_control
    aquila_control.verbose = 0;

    if nargin < 2
        phi_b = 1.7; % Default pinning potential if not provided
    end

    
    %% 1. DEFINE GENERIC LAYER SCHEMA & GLOBALS
    a_substrate = 3.189; % Angstroms (GaN)
    dz = 2.5;            % GRID SPACING in Angstroms
    
    % FIX: Ensure variable names match the function input
    layers = [input_layers{:}];
    
    %% 2. DYNAMIC DOMAIN ASSEMBLY
    z = []; Ec = []; Ev = []; eps_r = []; meff = []; Nd = []; P_total = [];
    interface_nodes = [];
    current_z = 0;
    
    [Eg_ref, ~, ~, ~, ~] = ganmaterial(0);
    
    for i = 1:length(layers)
        L = layers(i);
        [Eg_L, eps_L, m_L, Psp_L, Ppz_coeff_L] = ganmaterial(L.Al_x);
        
        if i == 1
            z_layer = (0 : dz : L.thickness)';
        else
            z_layer = (current_z + dz : dz : current_z + L.thickness)';
        end
        N_layer = length(z_layer);
        
        a_layer = 3.1986 - 0.0891 * L.Al_x;
        strain = (a_substrate - a_layer) / a_layer;
        P_pz = Ppz_coeff_L * strain;
        
        dEc = 0.7 * (Eg_L - Eg_ref);
        Ec_layer = ones(N_layer, 1) * dEc;
        Ev_layer = Ec_layer - (ones(N_layer, 1) * Eg_L);
        
        % Populate arrays
        eps_layer  = ones(N_layer, 1) * eps_L;
        meff_layer = ones(N_layer, 1) * m_L;
        Nd_layer   = ones(N_layer, 1) * L.Nd_val; % Adjusted to L.Nd_val
        P_layer    = ones(N_layer, 1) * (Psp_L + P_pz);
        
        z       = [z; z_layer];
        Ec      = [Ec; Ec_layer];
        Ev      = [Ev; Ev_layer];
        eps_r   = [eps_r; eps_layer];
        meff    = [meff; meff_layer];
        Nd      = [Nd; Nd_layer];
        P_total = [P_total; P_layer];
        
        current_z = current_z + L.thickness;
        if i < length(layers)
            interface_nodes = [interface_nodes; length(z)];
        end
    end
    N = length(z);
    
    %% 3. MULTI-JUNCTION POLARIZATION SPIKES
    rho_pol = zeros(N, 1);
    unit_conv = 0.062415; 
    for idx = interface_nodes'
        sigma_int = P_total(idx+1) - P_total(idx); 
        rho_pol(idx) = (sigma_int * unit_conv) / dz; 
    end
    
    %% 4. SELF-CONSISTENT LOOP
    phi = zeros(N, 1);           
    n_conc = zeros(N, 1);        
    damping = 0.1;              
    kT = 0.0259;
    Nd_unit = Nd * 1e-24; 
    num_subbands = 10; 
    
    for iter = 1:100
        % --- A. POISSON ---
        A = sparse(N, N);
        b = zeros(N, 1);
        for i = 2:N-1
            e_avg = 0.5 * (eps_r(i) + eps_r(i+1));
            e_avg_m = 0.5 * (eps_r(i) + eps_r(i-1));
            A(i,i) = -(e_avg + e_avg_m);
            A(i,i+1) = e_avg;
            A(i,i-1) = e_avg_m;
            b(i) = -(Nd_unit(i) - n_conc(i) + rho_pol(i)) * dz^2 * 180.95;
        end
        A(1,1) = 1; b(1) = -phi_b;
        A(N,N) = 1; A(N,N-1) = -1; b(N) = 0;
        
        phi_new = A \ b;
        phi = (1-damping)*phi + damping*phi_new;
        
        % --- B. SCHRODINGER ---
        diags = genmatrix1D(Ec - phi, z', meff);
        main_diag  = diags(:,1);
        super_diag = diags(:,2);
        len = length(main_diag);
        lower_diag = [0; super_diag(1:end-1)];
        H_sparse = spdiags([lower_diag, main_diag, super_diag], -1:1, len, len);
        
        sigma = min(Ec - phi) - 0.1; 
        [psi_internal, E_eig] = eigs(H_sparse, num_subbands, sigma);
        E_vals = diag(E_eig);
        
        psi = zeros(N, num_subbands);
        psi(2:end-1, :) = psi_internal;
        
        % --- C. DENSITY ---
        n_new = zeros(N,1);
        Ef = 0; 
        [~, max_idx] = max(psi(:,1));
        meff_well = meff(max_idx);
        
        for k = 1:num_subbands
            arg = (Ef - E_vals(k))/kT;
            occ = max(arg, 0) + log(1 + exp(-abs(arg)));
            prefactor = (meff_well * 4.17e14 * 1e-16) * kT; 
            Ns = prefactor * occ;
            psi_norm = psi(:,k).^2 / (sum(psi(:,k).^2)*dz);
            n_new = n_new + Ns * psi_norm;
        end
        n_conc = (1-damping)*n_conc + damping*n_new;
    end

    %% 5. FORMAT OUTPUTS
    y_cm3 = n_conc * 1e24;
    ns_out = trapz(z * 1e-8, y_cm3); 
    
    z_out = z' / 10; 
    Ec_out = (Ec - phi)';
    Ev_out = (Ev - phi)';
    n_out = y_cm3';
    
    % Compute the average internal electric field (V/cm) from the energy band diagram (Ec)
    % Note: 1 eV/nm = 1e7 V/cm
    slope_out = ((Ec_out(end) - Ec_out(1)) / (z_out(end) - z_out(1))) * 1e4;

    % Optional: Diagnostic message inside the block
    if iter == 100
        fprintf('Run_GaN_sim: Solver Complete.\n');
    end
end % End of function