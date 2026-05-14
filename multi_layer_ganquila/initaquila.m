%INITAQUILA setup for AQUILA
%
%script, that sets up the global variables for AQUILA
%
%These variables are grouped in for global structures:
%'aquila_control' contains flags and tuning parameters to control a program run.
%'aquila_subbands' contains wave functions and energies computed by the Schroedinger solver.
%'aquila_material' contains all material related parameters.
%'aquila_structure' contains all structural information.
%The most important members of these structures are predefined in this script.
%In addition a global variable 'phi' is defined here, later to be used to hold
%the electrostatic potential.
%
%Note: For a more detailed description of the structures see file 'structures'.

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

%clear up the workspace, remove old stuff
clear global aquila_control aquila_subbands aquila_material aquila_structure ...
   phi fermi_3_save poimatrix
global aquila_control aquila_subbands aquila_material aquila_structure phi

constants
format short e

%the mode: 1D or 2D
aquila_control.mode=1;

%no periodicity
aquila_control.periodic=0;

%verbosity level of output
aquila_control.verbose=0;

%predefine temperature, Fermi energy and carrier types
aquila_control.T=4.2;
aquila_control.Efermi=-0.5*(1.519-5.405e-4*aquila_control.T^2 /(aquila_control.T+204));
aquila_control.carriers=GE;

%parameters for eigenvalue tracking
aquila_control.inviter1.maxiter=30;
aquila_control.inviter1.tol=1e-5;
aquila_control.inviter2.maxiter=30;
aquila_control.inviter2.tol=1e-5;
aquila_control.tracklimit=0;

%parameters for eigenvalue solving
aquila_control.eigen.tol=1e-5;
aquila_control.eigen.maxiter=300;

%parameters for self-consistent solution
aquila_control.poisson.phitol=1e-4;
aquila_control.poisson.ftol=1e-5;
aquila_control.poisson.maxiter=50;
aquila_control.schrenable=0.02;
aquila_control.phitol=2e-6;
aquila_control.maxiter=100;

%fully ionized doping per default
aquila_control.fix_doping=1;

%check correct progress
aquila_control.progress_check=1;

%for storing of structural data and boundary conditions
aquila_structure.qbox=[];
aquila_structure.mbox=[];
aquila_structure.bcond=[];

%for storing the progress indicator
aquila_structure.pbox=[];

%for storing the biased regions
aquila_structure.bias=[];
aquila_material.bias=[];

%x-content
aquila_material.xcontent=[];
aquila_material.xcontentx=[];

%position information
aquila_structure.xpos=[];
aquila_structure.hx=[];
aquila_structure.ypos=[];
aquila_structure.hy=[];
aquila_structure.boxvol=[];

%doping concentration
aquila_material.doping=[];

%for saving of wavefunctions and energies of the quantum structures
aquila_subbands.ge=[];
aquila_subbands.xe=[];
aquila_subbands.le=[];
aquila_subbands.so=[];
aquila_subbands.hh=[];
aquila_subbands.lh=[];
aquila_subbands.structure=[];

%electric potential
phi=[];

