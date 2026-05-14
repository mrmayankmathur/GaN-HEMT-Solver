function [E,psi]=schrsolv1D(pot,x,y,mass,nr)

%SCHRSOLV1D solve Schroedinger equation in 1D
%
%[E,psi]=schrsolv1D(pot,x,y,mass,nr)
%
%Solves Schroedingers Equation and computes wavefunctions and energies in 1D.
%Quantization along y-axis.
%
%pot : potential
%x,y : position of nodes
%mass: mass
%nr  : nr of desired solutions

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

global aquila_control

hhy=diff(y);
hhx=diff(x);
ny=length(y)-2;

%form area covered by each node for later normalization
bv=sqrt((hhy(1:ny)+hhy(2:ny+1))/2);

%extrapolate the mass-matrix onto the nodes in x-direction
if aquila_control.mode==2
   mass=[mass(:,1) (mass(:,1:end-1).*(ones(ny+1,1)*hhx(1:end-1))+...
         mass(:,2:end).*(ones(ny+1,1)*hhx(2:end)))./...
         (ones(ny+1,1)*(hhx(1:end-1)+hhx(2:end))) mass(:,end)];
end

%generate the Schroedinger matrix for the first column
H=genmatrix1D(pot(:,1),y,mass(:,1));

%set up sinewave as a start vector
psi_start=sin(linspace(0,pi,length(y)))';
psi_start=psi_start(2:length(y)-1);

%make H a MATLAB sparse matrix and set up the parameters for MATLABs solver
H=spdiags([[H(1:ny-1,2);0] H(:,1) [0;H(1:ny-1,2)]],[-1 0 1],ny,ny);
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

%tell the user, if something is wrong
if length(E)<nr
   os=sprintf('schrsolv1D: found only %d eigenvalues instead of %d',length(E),nr);
   disp(os);
end
%normalize the solution
psi2=psi2./(bv'*ones(1,length(E)));
psi2=psi2./(ones(ny,1)*sqrt(sum(psi2.*psi2.*( (bv.*bv)'*ones(1,length(E)) ) )) );
psi=psi2;

%we are finished for 1D calculation now
%for 2D calculation we have to do the same procedure for all columns of the grid
%it generally will be faster, to compute the eigenvalues of one node by
%inverse vectoriteration from the eigenvalues of the neighbouring node
%because the potential usually is a smooth function with only slight changes
%between neighbouring nodes
if aquila_control.mode==2
   Ex=E;
   s=size(pot);
   for i_count=2:s(2) %for all columns
      %generate the corresponding Schroedinger matrix
      H=genmatrix1D(pot(:,i_count),y,mass(:,i_count));
      [E,psi2]=inviter1(H,E,psi2);% do inverse vectoriteration
      %detect convergence to wrong EVs in inviter
      %if this has happened, the change in the potential was to high
      %and we have to recompute the eigenvalues of this column of the grid
      %from the start using MATLABs solver
      dEmax=max(abs(E-Ex(:,end)));%largest change in the energy level
      diffE=min( min(abs(diff(E))),min(abs(diff(Ex(:,end)))) );%smallest subband spacing
      if (dEmax>diffE)|(~isempty(find(isnan(E)))) %the change in the levels is too high, regenerate EVs
         %call 'eigs'
         H=spdiags([[H(1:ny-1,2);0] H(:,1) [0;H(1:ny-1,2)]],[-1 0 1],ny,ny);
         psi_start=sin(linspace(0,pi,length(y)))';
         psi_start=psi_start(2:length(y)-1);
         opt.tol=aquila_control.eigen.tol;
         opt.maxit=aquila_control.eigen.maxiter;
         opt.v0=psi_start;
         opt.issym=1;
         if aquila_control.verbose>0
            opt.disp=nr;
         else
            opt.disp=0;
         end
         [psi2,E]=eigs(H,speye(size(H)),nr,'SR',opt);
         E=diag(E);         
      end
      %normalize the resulting eigenvectors
      psi2=psi2./(bv'*ones(1,length(E)));
      psi2=psi2./(ones(ny,1)*sqrt(sum(psi2.*psi2.*( (bv.*bv)'*ones(1,length(E)) ) )) );
      Ex=[Ex E];
      psi=[psi psi2];
   end
   %and convert them back to AQUILAs format
   %AQUILA stores all eigenfunctions of one carrier type of a QBOX in one matrix
   %containing the matrices of the eigenfunctions stacked from left to right:
   %  #####|#####|#####
   %  #EV1#|#EV2#|#EV3#
   %  #####|#####|#####
   ind=[1:nr:s(2)*nr];
   psi2=[];
   for i_count=0:nr-1
      psi2=[psi2 psi(:,ind+i_count)];
   end
   %the wavefunction has value zero as boundary condition
   psi=[zeros(1,s(2)*nr);psi2;zeros(1,s(2)*nr)];
   E=Ex;
else
   psi=[zeros(1,nr);psi;zeros(1,nr)]; %boundary condition in 1D
end

