% AQUILA Toolbox
%
%Version 1.0   27-DEZ-1999
%Copyright 1999 Martin Rother
%distributed under the terms of the BSD License
%
%AQUILA, simulation of low dimensional GaAs/AlGaAs semiconductor structures
%by self consistent solution of Schroedinger and Poisson equation
%in one or two dimensions
%
%Contact information:
%
%Address: Dr. Martin Rother
%         Soyerhofstrasse 1
%         81547 Muenchen
%         Germany
%
%Phone:   0-(49)-89-69398213
%EMail:   martin.rother@web.de
%         
%
%documentation
%  bugs            - known bugs
%  contents        - this file
%  howto           - how it works
%  structures      - data structures used in AQUILA
%
%initialization
%  initaquila      - set up the system
%  constants       - define some important constants
%
%structure definition
%  add_mbox        - define material region
%  add_qbox        - define quantum region
%  add_boundary    - define boundary condition
%  add_bias        - define a region with biased Quasi-Ferminiveau
%  startpotential  - define startpotential
%
%progress indication
%  add_pbox        - define screen output to be shown during computation
%
%simulation
%  runstructure    - perform the self-consistent computation
%  schrsolve       - solve Schroedinger equation
%  sumcharge       - compute total charge density
%  addqcharge      - add quantum charge
%
%helpers
%  boxindex        - find nodes
%  extend1D        - extrapolate in 1D
%  extend2D        - extrapolate in 2D
%  fermi           - complete Fermi-Dirac integral
%  gencharge       - compute charge density for certain carrier type
%  genqcharge      - compute the quantum charge density for certain QBOX
%  integrate       - integrate a field
%  intfield        - integrate a field over the whole structure
%  gaasmaterial    - material database for GaAs/AlGaAs material system
%
%internals
%  buildstructure  - set up the structure
%  genmatrix1D     - set up Schroedinger matrix for 1D Schroedinger solution
%  genmatrix2D     - set up Schroedinger matrix for 2D Schroedinger solution
%  genmatrixpoi    - set up Poisson matrix for 2D and 1D Poisson solution
%  genrhspoi       - set up right hand side of 2D or 1D Poisson equation
%  inviter1D       - refine eigenvalues in 1D
%  inviter2D       - refine eigenvalues in 2D
%  makegrid        - set up a grid and node positions
%  schrsolv1D      - solve Schroedinger equation in 1D
%  schrsolv2D      - solve Schroedinger equation in 2D
%  schrtrack1D     - refine old energies and wavefunctions in 1D
%  schrtrack2D     - refine old energies and wavefunctions in 2D
%
%This file is part of AQUILA.
%
%Copyright 1999 Martin Rother
%
%This file is part of AQUILA.
%
%AQUILA is free software; you can redistribute it and/or modify
%it under the terms of the BSD License as published by
%the Open Source Initiative according to the License Policy
%on MATLAB(R)CENTRAL.
%
%AQUILA is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%BSD License for more details.
