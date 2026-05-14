function add_pbox(xyminmax,varargin)

%ADD_PBOX progress indicator
%
%add_pbox(xyminmax)
%add_pbox(xyminmax,type)
%
%adds a new definition of what to output during the computation
%
%xyminmax=[xmin ymin xmax ymax] for 2D-simulation
%xyminmax=[xmin xmax] for 1D-simulation
%   defines the region of interest
%xmin==xmax displays cross-section in y-direction of band
%   and charges for ymin<y<ymax at x-position xmin as a graph
%   and displays value of sheet charge density [cm^-2] integrated along
%   the specified line as text
%ymin==ymax analog for cross-sections in x-direction
%if xyminmax defines a box: displays integrated charge desity in this box [cm^-1]
%   as text, no graph is plotted
%type can be CB,VB or CB+VB to display the conduction band, the valence band
%   or both (default)
%
%If any PBOX is defined then also the iteration counter and the maximal
%change in the potential in each iteration step is printed.

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
constants

%check correct execution order
if bitget(aquila_control.progress_check,1)==0
   error('add_pbox: INITAQUILA must be called before adding a progressmeter !')
end
aquila_control.progress_check=bitset(aquila_control.progress_check,5);

%substitute missing parameters
if nargin>1 

   tp=varargin{1};
else
   tp=CB+VB;
end
if length(xyminmax)==2
   xyminmax=[xyminmax(1) 0 xyminmax(2) 0];
end

%add information to the structure database
aquila_structure.pbox=[aquila_structure.pbox;xyminmax tp];

%output some information
if aquila_control.verbose>1
   os=sprintf('added progress box');
   disp(os)
   os=sprintf('%g<=x<=%g, %g<=y<=%g, type %d',xyminmax(1),xyminmax(3),xyminmax(2),xyminmax(4),tp);
   disp(os)
end
