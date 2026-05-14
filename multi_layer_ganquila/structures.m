%AQUILA uses four global structures to save data during the program run and
%to control the simulation:
%'aquila_control' contains flags and tuning parameters to control a program run.
%'aquila_subbands' contains wave functions and energies computed by the Schroedinger solver.
%'aquila_material' contains all material related parameters.
%'aquila_structure' contains all structural information.
%
%The members of aquila_control are:
%(the numbers are the default values)
%
%mode=1
%1 for 1D- or 2 for 2D-simulation
%
%periodic=0
%1 periodic boundary conditions in x-direction (001 direction)
%Periodicity refers to the electrostatic potential only, periodic boundary conditions
%also for the quantum mechanical part are much more difficult to handle and
%are not included in this release of AQUILA. This implies, that a computation
%with periodic boundary conditions makes sense only for purely classical problems or
%problems, where the quantum regions in every part of the structure do not interact
%and therefore can be treated separately. Note also, that periodic boundary conditions
%are supported in a 2D-simulation only.
%
%verbose=0
%defines level of output, 0 means nothing except warnings and errors,
%1 makes almost every routine telling you what is happening
%2 in addition also outputs progress of numerical routines
%
%T=4.2
%Temperature in K
%
%Efermi
%Fermi energy in the system. It is recomputed in the iteration loop and
%thus cannot be changed by the user.
%
%carriers=GE
%may be any sum of GE,XE,LE,HH,LH,SO and denotes the types of
%carriers to account for. Definitions in file 'constants'.
%
%inviter1
%is a structure that controls inverse vectoriteration for 1D eigenvalue tracking.
%It has two members:
%maxiter=30
%gives maximum number of iterations in inverse vectoriteration
%tol=1e-5;
%sets tolerance to archive in inverse vectoriteration
%
%inviter2
%same as inviter1, but for 2D eigenvalue tracking
%
%eigen
%controls eigenvalue computation by MATLABs Arnoldi (?) algorithm 'eigs'. It is a structure
%with two members:
%maxiter=300
%gives maximum iteration count
%tol=1e-5;
%sets desired tolerance
%
%poisson
%is a structure for controlling the self consistent, nonlinear Poisson solver.
%It has the following members:
%phitol=1e-4;
%sets desired tolerance in the electrical potential
%ftol=1e-5;
%sets desired tolerance in the error of Poissons equation
%maxiter=100;
%maximum iteration count
%The solver stops, if one of these stop criteria is met.
%
%phitol=1e-6;
%sets desired accuracy in the electric potential for the self consistent
%Schroedinger-Poisson solver.
%maxiter=100;
%maximum iteration count for the Schroedinger-Poisson solver.
%The Schroedinger equation is incorporated into the nonlinear Poisson solver
%by a predictor-corrector algorithm. This means, that for every solution
%of the Schroedinger equation several steps of the nonlinear Poisson solver
%are carried out. The Poisson solver then stops, if one of the stop criteria
%in the 'poisson' substructure mentioned above are met. Then a new solution
%of Schroedingers equation is computed. The whole iteration process stops,
%if the change in the potential is less than 'phitol' or if 'maxiter' is reached.
%Note, that for pure classical problems poisson.phitol is substituted by phitol,
%poisson.ftol is set to 0.1*phitol and poisson.maxiter is set to maxiter.
%
%fix_doping=1
%The value 1 means, that the doping is treated as constant space charge rather
%than a number of doping levels whose occupation depends on temperature and
%Fermi energy. This is sometimes necessary to achieve convergence in two
%dimensions. It will produce wrong results for the charges in the doping layer,
%when the dopant level drops below the Fermi level and a parallel channel is formed.
%Note also, that size confinement for doping levels is not included in the present version.
%
%schrenable=0.020;
%Below this energy tolerance in the potential the Schroedinger solver is switched on
%and the charge density in the QBOXes is switched from classical to quantum
%density. If poisson.phitol defined above is reached before schrenable, then the
%Schroedinger solver is switched on earlier.
%
%tracklimit=0;
%If the change in the potential is smaller than this value, the old eigenvalues/vectors
%are used as start values for the next step. Otherwise the energy spectrum is 
%recomputed from the start. For this tracking inverse vectoriteration is used. If the
%energy variation between two iteration steps is too large, the algorithm may lose
%eigenvalues or produce the same eigenvalue twice.
%0 means, that the energy spectrum is always recomputed from the start.
%
%progress_check
%used internally to control program run
%
%
%The members of aquila_structure are:
%
%qbox,mbox,pbox,bias,bcond
%matrices, that contain the information entered by the user to define
%the quantum-, material-, progress- and bias-boxes and the boundary conditions.
%
%xpos,ypos,hx,hy,boxvol
%the position of the nodes in x- and y-direction, the corresponding grid spacing and
%the area covered by each node. This information is computed in the 'buildstructure'
%and 'makegrid' routine.
%
%
%aquila_subbands consists of several member-structures, the index n denotes the
%number of the corresponding quantum box. Note, that not necessary all field are
%existent or filled with information, only the field necessary for subsequent
%computations are computed.
%
%structure(n)
%is a structure, that for each QBOX holds its node positions in the fields xpos and ypos
%and the corresponding boxvolume in boxvol.
%
%ge(n),xe(n),le(n),so(n),hh(n),lh(n)
%structures for different carrier types (gamma electrons, x-electrons, ...) in each qbox.
%Each of them hold the following information:
%E
%For 1D quantum wells and 2D quantum wires E is a vector containing the subband energies.
%For 2D quantum wells E is an array whos columns are the energy levels of the subbands
%at the grid lines.
%psi
%Holds the wave functions (psi, not |psi|^2) of the subbands. The wave functions are stacked
%from left to right. This means, that if the QBOX has mxn grid points and p subbands have
%been computed, then psi has m rows and n*l columns. In this case psi(:,1:n) is the wave
%function of the lowest subband, psi(:,n+1:2*n) the second subbands wave function and so on.
%
%
%The members of aquila_material are:
%
%xcontent
%the Aluminum content in the structure defined between the grid nodes.
%('between' means, in the little rectangular boxes enclosed by 4 adjacent grid nodes)
%
%xcontentx
%same as xcontent, but interpolated onto the grid nodes.
%
%doping
%the dopant concentration [Angstrom^-3]
%
%epsilon
%the material-dependent dielectric constant
%
%alpha,beta,e0
%internal parameters used for computation of band gap etc..
%
%ec,ev
%conduction band and valence band [eV] as defined by the material composition.
%In order to get the real band structure, you have to subtract the electrostatic potential
%'phi' from ec and ev.
%
%bias
%bias voltage for carrier systems at every node.
%This defines a local Fermi energy (or quasi-Fermilevel) and thereby allows
%to simulate non-equilibrium structures. Note however, that transport is not simulated. This
%means, that there must not be a contact (exchange of carriers) between systems
%of different bias. Extremely weak transport (e.g. tunneling) may be simulated
%with sufficient accuracy.
%
%several other quantities are computed as necessary, dependent on carrier types:
%eg,megd,eg6g8,meg
%energy level, DOS mass, Gamma6-Gamma8 energy distance and particle mass for Gamma electrons.
%The Gamma6-Gamma8 energy distance is needed here for inclusion of Gamma non-parabolicity
%in the classical charge densities.
%ex,mexd,mex
%energy level, DOS mass and particle mass for X electrons.
%el,meld,mel
%same for L-electrons
%ev,mhhd,mhh001,mhh110
%same for heavy holes, the particle masses are different for the 001- and 110-direction
%ev,mlhd,mlh001,mlh110
%same for light holes
%so,msod,mso
%same for split-off holes
%dop
%the donator level

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

