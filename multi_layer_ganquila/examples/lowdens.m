%1D simulation of a low density NRC sample

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

initaquila                              %initialize the system
aquila_control.mode=1;                  %1D simulation
aquila_control.fix_doping=0;             %handle doping as doping levels, not as space charge

add_mbox(100,10,0,0);                   %100 A GaAs
add_mbox(120,10,0.33,0);                %120 A AlGaAs
add_mbox(2,1,0.33,0);                   %2 A AlGaAs, this is introduced here only
                                        %to match the grid spacing from 10 A to 1 A
add_mbox(2,1,0.33,-6.29e19*0.94);       %2 A n-AlGaAs, this simulates a delta doped layer
                                        %the factor 0.94 simulates the doping efficiency
                                        %and is determined by comparing the experimental
                                        %values for the charge density with the simulation
add_mbox(2,1,0.33,0);                   %2 A AlGaAs, this again matches the grid spacing
add_mbox(800,10,.33,0);                 %800 A AlGaAs
add_mbox(2,1,0.33,0);                   %2 A AlGaAs
add_mbox(2,1,0.33,-3.14e19*0.94);       %2 A n-AlGaAs, second delta doping
add_mbox(2,1,0.33,0);                   %2 A AlGaAs
add_mbox(1200,50,0.33,0);               %1200 A AlGaAs, Spacer
add_mbox(10000,100,0,0);                %10000 A GaAs, transition to bulk, at this
                                        %interface the two-dimensional electron system
                                        %will be formed

add_qbox([2200 2800],10,2,GE);          %model the qunatum region with 10 A resolution
                                        %compute 2 subbands and model only gamma electrons

add_boundary(LEFT,POTENTIAL,0);         %the potential at the surface should be 0
                                        %this means free surface, no gate
add_boundary(RIGHT,FIELD,0);            %the transition to the bulk of the substrate
                                        %modeled by zero electric field

add_pbox([2200 2800],CB);               %screen output, zoom into the quantum region
                                        %conduction band only, this will also output
                                        %the sheet density of electrons in the channel
add_pbox([0 3000],CB);                  %screen output, overview of the whole structure
                                        %conduction band only
startpotential(0);
runstructure;                           %do the simulation

%now give some output
%This can also be done interactively from the command line
%after running the simulation. All the relevant information is
%stored in the global variables of AQUILA.

%The following lines are meant to be an example only, because there are so
%many possibilities for output, depending on the specific
%interest of the user, so it seams not possible to create a
%postprocessing routine satisfying all users desires.
%(How do the bands look like? How much charge is in the channel?
%How do the subbands look like? What is the energy separation between them?
%How many subbands are occupied? Is there parallel conduction in the doping layer? ...)

%plot the conduction band and the Fermi energy in the range 0...4000 A
clf
ix=boxindex(aquila_structure.xpos,[0 4000]);
plot(aquila_structure.xpos(ix)',[(aquila_material.ec(ix)-phi(ix))' ...
      aquila_control.Efermi*ones(size(aquila_structure.xpos(ix)))']);

%what is the sheet density of the electrons in the channel
ch=sumcharge(phi);  %the total charge
ix=boxindex(aquila_structure.xpos,[2200 2800]); %the channel position
%sum the charge weighted by the area covered by each node and scale it
%from A^-2 to cm^-2. The output is negative because of the negative electron charge.
sum(ch(ix).*aquila_structure.boxvol(ix))*1e16  %the electron sheet density in the channel

%how do the wavefunctions look like
%We only have gamma electrons in one QBOX, this is, what the ge(1) stand for.
%We have to square the wavefunctions to get the probability distribution.
l=length(aquila_subbands.structure(1).xpos); %the size of one wavefunction
plot(aquila_subbands.structure(1).xpos,[aquila_subbands.ge(1).psi(1:l)' ...
      aquila_subbands.ge(1).psi(l+1:2*l)'].^2)

%What is the energy difference of the subbands, is more than one subband occupied?
aquila_subbands.ge(1).E(2)-aquila_subbands.ge(1).E(1)
%the energy difference is about 6.9 meV
%now compare the energy levels to the Fermi energy
aquila_subbands.ge(1).E(1)
aquila_subbands.ge(1).E(2)
aquila_control.Efermi
%we see, that the Fermi energy is between the first and second subband
%we therefore have only one occupied subband

%how much charge is in the first and in the second subband
ch=genqcharge(1,GE,1); %charge distribution for gamma electrons in the first subband
                       %of the first quantum box
sum(ch.*aquila_subbands.structure(1).boxvol)*1e16 %integrate to get the sheet density
ch=genqcharge(1,GE,2); %charge distribution for gamma electrons in the second subband
                       %of the first quantum box
sum(ch.*aquila_subbands.structure(1).boxvol)*1e16 %integrate to get the sheet density
