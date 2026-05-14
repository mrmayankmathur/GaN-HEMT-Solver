function H=genmatrix1D(pot,y,mass)

%GENMATRIX1D compute matrix for Schroedinger solution in 1D
%
%H=genmatrix1D(pot,y,mass)
%
%given a potential pot, node positions y and masses mass (defined between the nodes)
%this function returns the matrix diagonal and subdiagonal vector of the corresponding
%Schroedingermatrix in the columns of H

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

constants

%some output for the user
if aquila_control.verbose>0
   disp('genmatrix1D: setting up matrix for 1D eigenvalue computation')
end

h=diff(y)';
n=length(y)-2;

%set up the area for each node
bv=((h(1:n)+h(2:n+1))./2);

%set up the main diagonal and first superdiagonal
%corresponding to the operator  (d/dx)^2
d=-(1./(h(2:n+1).*mass(2:n+1))+1./(h(1:n).*mass(1:n)));
d1=[1./(h(2:n).*mass(2:n));0];

%multiply kinetic terms by hbar^2/2m0
d=d.*(-HBAR*HBAR/(2.0*M0));
d1=d1.*(-HBAR*HBAR/(2.0*M0));

%add potential on the main diagonal
d=d+pot(2:n+1).*bv;

%include boxvolume
d=d./bv;
d1(1:n-1)=d1(1:n-1)./sqrt(bv(1:n-1).*bv(2:n));

%and return the resulting diagonals in the columns of H
H=[d d1];

