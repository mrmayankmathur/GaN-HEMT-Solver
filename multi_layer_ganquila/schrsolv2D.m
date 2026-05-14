function [E,psi]=schrsolv2D(pot,x,y,massx,massy,nr)

%SCHRSOLV2D solve Schroedinger equation in 2D
%
%[E,psi]=schrsolv2D(pot,x,y,massx,massy,nr)
%
%Solves Schroedingers Equation and computes wavefunctions and energies in 2D.
%
%pot        : potential
%x,y        : indices of nodes in global node positions aquila_structure.xpos/.ypos
%massx,massy: mass
%nr         : nr of desired solutions

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

global aquila_control aquila_structure
nx=length(x)-2;
ny=length(y)-2;

%compute area covered by the node for later normalization of the wavefunctions
bv=sqrt(aquila_structure.boxvol(y(2:end-1),x(2:end-1)));

%create the Schroedinger matrix
H=genmatrix2D(pot,x,y,massx,massy);

%create a vector to start the MATLABs 'eigs'
%we use one period of a sine-wave as approximation to the lowest eigenvector
psi_start=sin(linspace(0,pi,length(y)))'*sin(linspace(0,pi,length(x)));
psi_start=psi_start(2:length(y)-1,2:length(x)-1);
psi_start=psi_start(:);

%make H a MATLAB sparse matrix and set up the parameters for the solver
n=nx*ny;
H=spdiags([[H(1:n-nx,3);zeros(nx,1)] [H(1:n-1,2);0] H(:,1)...      
   [0;H(1:n-1,2)] [zeros(nx,1);H(1:n-nx,3)]],[-nx -1 0 1 nx],n,n);
opt.tol=aquila_control.eigen.tol;
opt.maxit=aquila_control.eigen.maxiter;
opt.v0=psi_start;
opt.issym=1;
if aquila_control.verbose>0
   opt.disp=nr;
else
   opt.disp=0;
end
%call the solver
[psi2,E]=eigs(H,speye(size(H)),nr,'SR',opt);
E=diag(E);

%tell the user, if there were problems
if length(E)<nr
   os=sprintf('schrsolv2D: found only %d eigenvalues instead of %d',length(E),nr);
   disp(os);
end

%normalize the eigenfunctions and reshape them to the original grid
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
