%Example for AQUILA 1.0
%1D-Simulation of a quantum wire substrate

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

initaquila                             %initialize
aquila_control.mode=1;                 %1D-Simulation
aquila_control.fix_doping=0;           %use doping levels instead of treating the doping
                                       %as a space charge

add_mbox(1020,20,0,0);                 %1020 A GaAs Cap
add_mbox(4000,50,0.328,0);             %4000 A AlGaAs
add_mbox(2,1,0.328,0);                 %2 A AlGaAs to increase grid resolution
add_mbox(2,1,0.328,-8.34e19*0.94*0.2); %2 A delta-doped AlGaAs
add_mbox(2,1,0.328,0);                 %2 A AlGaAs
add_mbox(500,20,0.328,0);              %500 A AlGaAs spacer
add_mbox(300,10,0,0);                  %300 A GaAs quantum well
add_mbox(10000,100,0.328,0);           %10000 A AlGaAs

add_qbox([5475 5910],5,3,GE);          %set quantum box onto quantum well

add_boundary(LEFT,POTENTIAL,0);        %free surface, no gate
add_boundary(RIGHT,FIELD,0);           %transition to bulk

add_pbox([5400 6000],CB);
add_pbox([0 7000],CB);

runstructure;                          %DO IT
