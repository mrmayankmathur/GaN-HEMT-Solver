%Cleaved-Edge-Overgrowth (CEO) Superlattice (SL)
%demo for periodic potentials
%Note: the quantization of the 2D electron system is simulated in
%x-(001)-direction only
%
%for e description of the underlying physics see for example
%Negative Differential Resistance of a 2D Electron Gas in a 1D Miniband,
%R. A. Deutschmann, W. Wegscheider, M. Rother, M. Bichler, and G. Abstreiter,
%Physica E 7, 294 (2000)

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

initaquila                                            %initialization
aquila_control.mode=2;                                %2D-simulation
aquila_control.periodic=1;                            %periodic boundary conditions

                                                      %001-direction, one period of the SL
add_mbox([0 0 200 400],[20 50],0,0);                  %200 A GaAs
add_mbox([200 0 400 400],[20 50],0.3,0);              %200 A AlGaAs
add_mbox([0 400 200 700],[20 20],0,0);                %200 A GaAs with finer resolution
add_mbox([200 400 400 700],[20 20],0.3,0);            %200 A AlGaAs with finer resolution

                                                      %110-direction
add_mbox([0 700 400 900],[20 20],0,0);                %200 A GaAs quantum well
add_mbox([0 900 400 1400],[20 50],0.3,0);             %500 A AlGaAs spacer
add_mbox([0 1400 400 1402],[20 1],0.3,0);             %2 A AlGaAs 
add_mbox([0 1402 400 1404],[20 1],0.3,-6e19);         %2 A AlGaAs delta-doped
add_mbox([0 1404 400 1406],[20 1],0.3,0);             %2 A AlGaAs 
add_mbox([0 1406 400 2100],[20 100],0.3,0);           %700 A AlGaAs 
add_mbox([0 2100 400 2300],[20 50],0,0);              %200 A GaAs cap
                                           
add_qbox([0 0 400 950],[20 20],2,QWX,GE);           %the 2D electron system

add_boundary([0 400],BOTTOM,FIELD,0);                 %transition to bulk, no field
add_boundary([0 400],TOP,POTENTIAL,0);                %free surface, no gate
%we don't need BC's for left and right boundary, because we have
%periodic boundary conditions

add_pbox([0 850 400 850],CB);                    %cross section trough modulated electron system
add_pbox([100 0 100 1000],CB);                   %cross section trough CEO plane
add_pbox([300 0 300 1000],CB);                   %cross section trough CEO plane

runstructure;

