function b=extend2D(a)

%EXTEND2D extrapolate field in 2D
%
%y=extend2D(a)
%
%extrapolates a property defined between the nodes to values at the nodes
%
%a = field defining the values to be extrapolated (gridsize minus 1 in each direction)
%y = extrapolated field
%the position of the nodes are taken from the global structure definition

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

nx=length(aquila_structure.xpos)-2;
ny=length(aquila_structure.ypos)-2;
bv=aquila_structure.boxvol(2:end-1,2:end-1);
b=(((aquila_structure.hy(1:ny)/2)'*(aquila_structure.hx(1:nx)/2)).*a(1:ny,1:nx)+...
   ((aquila_structure.hy(1:ny)/2)'*(aquila_structure.hx(2:nx+1)/2)).*a(1:ny,2:nx+1)+...
   ((aquila_structure.hy(2:ny+1)/2)'*(aquila_structure.hx(1:nx)/2)).*a(2:ny+1,1:nx)+...
   ((aquila_structure.hy(2:ny+1)/2)'*(aquila_structure.hx(2:nx+1)/2)).*a(2:ny+1,2:nx+1))./bv;
bv=(aquila_structure.hy(1:ny)+aquila_structure.hy(2:ny+1))';
b=[(aquila_structure.hy(1:ny)'.*a(1:ny,1)+aquila_structure.hy(2:ny+1)'.*a(2:ny+1,1))./bv b ...
      (aquila_structure.hy(1:ny)'.*a(1:ny,end)+aquila_structure.hy(2:ny+1)'.*a(2:ny+1,end))./bv];
bv=aquila_structure.hx(1:nx)+aquila_structure.hx(2:nx+1);
b=[a(1,1) (aquila_structure.hx(1:nx).*a(1,1:nx)+aquila_structure.hx(2:nx+1).*a(1,2:nx+1))./bv a(1,end);b;...
      a(end,1) (aquila_structure.hx(1:nx).*a(end,1:nx)+aquila_structure.hx(2:nx+1).*a(end,2:nx+1))./bv a(end,end)];
if aquila_control.periodic==1
   b(:,1)=(b(:,1)*aquila_structure.hx(1)+b(:,end)*aquila_structure.hx(end))./...
      (aquila_structure.hx(1)+aquila_structure.hx(end));
   b(:,end)=b(:,1);
end
