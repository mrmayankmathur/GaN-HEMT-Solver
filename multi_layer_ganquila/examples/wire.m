%A Cleaved Edge Overgrowth (CEO) quantum wire
%
%for a detailled description of the underlying physics see my PhD thesis:
%'Elektronische Eigenschaften von Halbleiternanostrukturen hergestellt
%durch Ueberwachsen von Spaltflaechen', (c) 2000 by 'Verein zur Foerderung
%des Walter Schottky Instituts der Technischen Universitaet Muenchen e.V.'
%Am Coulombwall, 85748 Garching, Germany, ISBN: 3-932749-33-2
%
%or
%Evidence of Luttinger Liquid Behavior in GaAs/AlGaAs Quantum Wires,
%M. Rother, W. Wegscheider, R. A. Deutschmann, M. Bichler, and G. Abstreiter,
%Physica E 6, 551 (2000)
%
%or
%A. Yacoby, H.L. Stoermer, N.S. Wingreen, L.N. Pfeiffer, K.W. Baldwin, and K.W. West
%Phys. Rev. Lett. 77, 4612 (1996)

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

initaquila                                            %Initialization
aquila_control.mode=2;                                %2D-Simulation

add_mbox([0 0 1000 10000],[500 5000],0,0);            %001-GaAs Cap
add_mbox([1000 0 4994 10000],[500 5000],0.3,0);       %001-AlGaAs
add_mbox([4994 0 4996 10000],[1 5000],0.3,0);         %001-AlGaAs to increase grid resolution
add_mbox([4996 0 4998 10000],[1 5000],0.3,-1.6e19);   %001-AlGaAs n-type delta-doping
add_mbox([4998 0 5000 10000],[1 5000],0.3,0);         %001-AlGaAs
add_mbox([5000 0 5500 10000],[200 5000],0.3,0);       %001-AlGaAs-spacer 
add_mbox([5500 0 5750 10000],[20 5000],0,0);          %001-GaAs quantum well 250 Angstrom
add_mbox([5750 0 30000 10000],[5000 5000],0.3,0);     %001-AlGaAs
%here is the CEO
add_mbox([0 10000 30000 10500],[5000 200],0.3,0);      %110-AlGaAs-spacer
add_mbox([0 10500 30000 10502],[5000 1],0.3,0);        %110-AlGaAs to increase grid resolution
add_mbox([0 10502 30000 10504],[5000 1],0.3,-1.6e19);  %110-AlGaAs n-type delta-doping
add_mbox([0 10504 30000 10506],[5000 1],0.3,0);        %110-AlGaAs-doping
add_mbox([0 10506 30000 13500],[5000 1000],0.3,0);     %110-AlGaAs
add_mbox([0 13500 30000 13700],[5000 100],0,0);        %110-GaAs Cap

add_qbox([5450 9000 5800 10050],[40 40],4,QWR,GE);     %the quantum wire region

add_boundary([0 30000],BOTTOM,FIELD,0);                %no field at the bottom
                                                       %transition to bulk
add_boundary([0 30000],TOP,POTENTIAL,0);               %zero potential at 110 free surface
add_boundary([0 10001],LEFT,POTENTIAL,-2.7);           %negative biased gate on 001 surface
                                                       %below cleavage plane
add_boundary([10001 13700],LEFT,FIELD,0);              %zero field on free 001 surface
                                                       %above cleavage plane
add_boundary([0 13700],RIGHT,FIELD,0);                 %no field at right boundary
                                                       %transition to bulk

add_pbox([5400 9800 5900 9800],CB);                    %display cross section of the wire
add_pbox([5625 8000 5625 10000],CB);

runstructure;                                          %DO IT

%Now lets plot the contours of the lowest four subbands
clf
l=length(aquila_subbands.structure(1).xpos); %width of the quantum region
subplot(1,4,1);
surf(aquila_subbands.structure(1).xpos,aquila_subbands.structure(1).ypos,...
   aquila_subbands.ge(1).psi(:,1:l).^2);      
axis image
axis off
view(2);
shading interp

subplot(1,4,2);
surf(aquila_subbands.structure(1).xpos,aquila_subbands.structure(1).ypos,...
   aquila_subbands.ge(1).psi(:,1*l+1:2*l).^2);      
axis image
axis off
view(2);
shading interp

subplot(1,4,3);
surf(aquila_subbands.structure(1).xpos,aquila_subbands.structure(1).ypos,...
   aquila_subbands.ge(1).psi(:,2*l+1:3*l).^2);      
axis image
axis off
view(2);
shading interp

subplot(1,4,4);
surf(aquila_subbands.structure(1).xpos,aquila_subbands.structure(1).ypos,...
   aquila_subbands.ge(1).psi(:,3*l+1:4*l).^2);      
axis image
axis off
view(2);
shading interp

%Now get the energies and the carrier densities in the subbands
disp('Subband Energies [meV]')
disp(aquila_subbands.ge(1).E)
disp('Fermi Energy [meV]')
disp(aquila_control.Efermi)
disp('Carriers in subband 1 [cm^-1]')
ch=genqcharge(1,GE,1); %get the charge density
%you could plot ch directly using a surf-command similar to the one above,
%but here we want the total density. The factor 1e8 scales from
%Angstrom^-1 to cm^-1
disp(sum(sum(ch.*aquila_subbands.structure(1).boxvol))*1e8) %integrate it over the QBOX
disp('Carriers in subband 2 [cm^-1]')
ch=genqcharge(1,GE,2);
disp(sum(sum(ch.*aquila_subbands.structure(1).boxvol))*1e8)
disp('Carriers in subband 3 [cm^-1]')
ch=genqcharge(1,GE,3);
disp(sum(sum(ch.*aquila_subbands.structure(1).boxvol))*1e8)
disp('Carriers in subband 4 [cm^-1]')
ch=genqcharge(1,GE,4);
disp(sum(sum(ch.*aquila_subbands.structure(1).boxvol))*1e8)
