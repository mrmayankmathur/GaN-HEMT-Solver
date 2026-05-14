function [E,psi]=schrtrack1D(pot,x,y,mass,ev,evec)

%SCHRTRACK1D refine eigenvalues in 1D
%
%[E,psi]=schrtrack1D(pot,x,y,mass,nr,ev,evec)
%
%Solves Schroedingers Equation and computes wavefunctions and energies in 1D
%by refining old eigenvalues. Quantization along y-axis.
%
%pot : potential
%x,y : position of nodes
%mass: mass
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

global aquila_control

hhy=diff(y);
hhx=diff(x);
ny=length(y)-2;

%the area covered by each node
bv=sqrt((hhy(1:ny)+hhy(2:ny+1))/2);

%extrapolate the mass onto the nodes in x-direction
if aquila_control.mode==2
   mass=[mass(:,1) (mass(:,1:end-1).*(ones(ny+1,1)*hhx(1:end-1))+...
         mass(:,2:end).*(ones(ny+1,1)*hhx(2:end)))./...
         (ones(ny+1,1)*(hhx(1:end-1)+hhx(2:end))) mass(:,end)];
end

%size of the problem
nr=length(ev(:,1));
nx=length(x);
Ex=[];
psi=[];
s=size(pot);

%for all columns
for i_count=1:nx
   %generate the Schroedinger matrix
   H=genmatrix1D(pot(:,i_count),y,mass(:,i_count));
   %convert eigenvector from AQUILA format to columns
   E=ev(:,i_count);
   psi2=[];
   for count=0:nr-1
      psi2=[psi2 evec(:,count*nx+i_count)];
   end
   psi2=psi2(2:end-1,:);
   %call the inverse vectoriteration
   [E,psi2]=inviter1(H,E,psi2);
   %normalize the result
   psi2=psi2./(bv'*ones(1,length(E)));
   psi2=psi2./(ones(ny,1)*sqrt(sum(psi2.*psi2.*( (bv.*bv)'*ones(1,length(E)) ) )) );
   Ex=[Ex E];
   psi=[psi psi2];
end
%convert eigenvectors back to AQUILA format
ind=[1:nr:s(2)*nr];
psi2=[];
for i_count=0:nr-1
   psi2=[psi2 psi(:,ind+i_count)];
end
psi=[zeros(1,s(2)*nr);psi2;zeros(1,s(2)*nr)];
E=Ex;
