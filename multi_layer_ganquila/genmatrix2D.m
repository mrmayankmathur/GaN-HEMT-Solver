function H=genmatrix2D(pot,x,y,massx,massy)

%GENMATRIX2D compute matrix for Schroedinger solution in 2D
%
%H=genmatrix2D(pot,x,y,massx,massy)
%
%given a potential pot and masses massx,massy (defined between the nodes)
%this function return the matrix diagonal and subdiagonal vectors of the corresponding
%Schroedingermatrix in the columns of H, The node positions are taken from the global
%structure definition using the index vectors x,y.

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

global aquila_structure aquila_control

%check correct execution order
if bitget(aquila_control.progress_check,1)==0
   error('genmatrix2D: INITAQUILA must be called before generating the Schroedingermatrix !')
end

%define some constants
constants

%some output for the user
if aquila_control.verbose>0
   disp('genmatrix2D: setting up matrix for 2D eigenvalue computation')
end

nx=length(x)-2;
ny=length(y)-2;
massx=1./massx;
massy=1./massy;

%get the area for each node and make the grid spacing a matrix
bv=aquila_structure.boxvol(y(2:end-1),x(2:end-1));
h2x=ones(ny+1,1)*aquila_structure.hx(x(1:end-1));
h2y=aquila_structure.hy(y(1:end-1))'*ones(1,nx+1);

%construct the coefficients for the nodes
%for the nodes not on the boundary.
%We set the wavefunction to zero on the boundary and therefore we don't

%have to include the boundary nodes.

% coefficients for (d/dx)^2+(d/dy)^2
f1=(massx(1:ny,2:nx+1).*h2y(1:ny,2:nx+1)+massx(2:ny+1,2:nx+1).*h2y(2:ny+1,2:nx+1))./(h2x(1:ny,2:nx+1).*2);
f2=(massx(1:ny,1:nx).*h2y(1:ny,1:nx)+massx(2:ny+1,1:nx).*h2y(2:ny+1,1:nx))./(h2x(1:ny,1:nx).*2);
f3=(massy(1:ny,1:nx).*h2x(1:ny,1:nx)+massy(1:ny,2:nx+1).*h2x(1:ny,2:nx+1))./(h2y(1:ny,1:nx).*2);
f4=(massy(2:ny+1,1:nx).*h2x(2:ny+1,1:nx)+massy(2:ny+1,2:nx+1).*h2x(2:ny+1,2:nx+1))./(h2y(2:ny+1,1:nx).*2);
d=-(f1+f2+f3+f4); %main diagonal 
d1=[f1(:,1:nx-1) zeros(ny,1)]; %first superdiagonal
dn=[f4(1:ny-1,:);zeros(1,nx)]; %nth superdiagonal

% multiply kinetic terms by hbar^2/2m0
d=d.*(-HBAR*HBAR/(2.0*M0));
d1=d1.*(-HBAR*HBAR/(2.0*M0));
dn=dn.*(-HBAR*HBAR/(2.0*M0));

%add potential on the main diagonal
d=d+pot(2:ny+1,2:nx+1).*bv;

%include boxvolume
d=d./bv;
d1(:,1:nx-1)=d1(:,1:nx-1)./sqrt(bv(:,1:nx-1).*bv(:,2:nx));
dn(1:ny-1,:)=dn(1:ny-1,:)./sqrt(bv(1:ny-1,:).*bv(2:ny,:));

%we return the diagonals in the columns of a matrix H
d=d';
d1=d1';
dn=dn';
d=d(:);
d1=d1(:);
dn=dn(:);
H=[d d1 dn];
