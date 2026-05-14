function [E,psi]=schrtrack2D(pot,x,y,massx,massy,ev,evec)

%SCHRTRACK2D refine eigenvalues in 2D
%
%[E,psi]=schrsolv2D(pot,x,y,massx,massy,ev,evec)
%
%Refines old solutions of Schroedingers Equation in 2D using inverse vectoriteration
%
%pot        : potential
%x,y        : indices of node positions in global node positions aquila_structure.xpos/.ypos
%massx,massy: mass
%ev         : vector of old eigenenergies
%evec       : matrix of corresponding wavefunctions

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

global aquila_structure
nx=length(x)-2;
ny=length(y)-2;

%get the area covered by each node for later normalization
bv=sqrt(aquila_structure.boxvol(y(2:end-1),x(2:end-1)));

%generate the corresponding Schroedinger matrix
H=genmatrix2D(pot,x,y,massx,massy);

%reshape the eigenvectors from AQUILA format into columns of a matrix
psi=[];
for i_count=0:length(ev)-1
   psix=evec(:,i_count*(nx+2)+1:(i_count+1)*(nx+2));
   psix=psix(2:ny+1,2:nx+1)';
   psi=[psi psix(:)];
end

%call inverse vectoriteration
[E,psi2]=inviter2(H,nx,ev,psi);
   
%normalize the results and reshape them into AQUILA format
%AQUILA stores all eigenfunctions of one carrier type of a QBOX in one matrix
%containing the matrices of the eigenfunctions stacked from left to right:
%  #####|#####|#####
%  #EV1#|#EV2#|#EV3#
%  #####|#####|#####
psi2=reshape(psi2,nx,ny*length(E));
psi=[];
for i_count=0:length(E)-1
   psix=psi2(:,i_count*ny+1:(i_count+1)*ny)'./bv;
   psix=psix./sqrt(sum(sum(psix.*psix.*bv.*bv)));
   %the wavefunction has value zero as boundary condition
   psi=[psi [zeros(1,nx+2);zeros(ny,1) psix zeros(ny,1);zeros(1,nx+2)]];
end   
