function add_boundary(varargin)

%ADD_BOUNDARY set boundary condition
%
%adds a new boundary condition (BC) for the electrostatic potential
%
%2D version:
%add_boundary(xminmax,pos,type,val)
%
%xminmax=[xmin xmax] sets the BC at all nodes xmin <= node-position <= xmax
%pos=BOTTOM,TOP,LEFT,RIGHT determines boundary where the BC is to be set
%type=POTENTIAL,FIELD fixes either the electrostatic potential (Dirichlet) or the
%   electric field (von Neumann) in the specified region
%val is the value of the BC
%
%Note 1: take care to set boundary conditions on ALL boundary points or the 
%        solution of Poisson equation will fail. AQUILA will warn you, if this happens.
%Note 2: BCs on each border are processed in order of appearance, so take care 
%        not to overwrite previous definitions by letting regions overlap.
%
%1D version:
%add_boundary(pos,type,val)
%
%with pos=LEFT,RIGHT only

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

%check for correct execution order
if bitget(aquila_control.progress_check,1)==0
   error('add_boundary: INITAQUILA must be called before adding a boundary condition !')
end
aquila_control.progress_check=bitset(aquila_control.progress_check,3);

if nargin==4 %the 2D-version is used
   xminmax=varargin{1};
   pos=varargin{2};
   tp=varargin{3};
   val=varargin{4};
else %the 1D-version is used, so define missing values to zero
   xminmax=[0 0];
   pos=varargin{1};
   tp=varargin{2};
   val=varargin{3};
end   

%add the information to the structure database
aquila_structure.bcond=[aquila_structure.bcond;xminmax pos tp val];

%output some information
if aquila_control.verbose>1
   os=sprintf('added boundary condition on edge %d',pos);
   disp(os)
   os=sprintf('type %d, %g<=position<=%g, value %g',tp,xminmax(1),xminmax(2),val);
   disp(os)
end
