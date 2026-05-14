%constants
%
%script, that defines useful constants for AQUILA
%
%physical constants
%HBAR [eV s] Planck constant/2pi
%M0 [eV s^2/A^2] electron mass
%KB [eV/K] Boltzmann constant
%
%type of the quantum regions (see ADD_QBOX)
%QWX, QWY, QWR
%
%position of the boundary conditions (see ADD_BOUNDARY)
%LEFT, RIGHT, TOP, BOTTOM
%
%type of the boundary conditions (see ADD_BOUNDARY)
%POTENTIAL, FIELD
%
%carrier types
%GE=Gamma electrons
%XE=X electrons
%LE=L electrons
%LH=light holes
%HH=heavy holes
%SO=split-off holes

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

%physical constants
HBAR=6.5822e-16;% eV s
E0E0=14.409;% eV A
M0=9.1096e-31*6.241457e-2;	% eV s^2/A^2
KB=8.61708e-5;	% eV/K

%defines type of quantum region for Schroedinger solve
QWX=1;
QWY=2;
QWR=3;

%defines position of boundary condition for Poisson solve
LEFT=1;
RIGHT=2;
TOP=3;
BOTTOM=4;

%defines type of boundary condition for Poisson solve
FIELD=1;
POTENTIAL=2;

%defines carrier type to account for
GE=1;
XE=2;
LE=4;
SO=8;
HH=16;
LH=32;

%and the doping
DOP=64;

%what to display
CB=1;
VB=2;
