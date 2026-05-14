function add_qbox(xyminmax,resxy,subs,varargin)

%ADD_QBOX new quantum region
%
%add_qbox(xyminmax,resxy,subs,type,carrier)
%add_qbox(xyminmax,resxy,subs,carrier)
%
%adds a new quantum region to the structure
%QBOXes define regions, where AQUILA is supposed to solve Schroedingers
%equation and use the quantum charge density intead of the classical
%charge density. These computations are very time consuming, so define
%as quantum regions only regions where you expect quantum mechanics to be
%necessary. QBOXes are superimposed on the structural definition defined
%by the MBOXes.
%
%xyminmax=[xmin ymin xmax ymax] for 2D-simulation
%xyminmax=[xmin xmax] for 1D-simulation
%   defines the corners of a region
%resxy=[resx resy] for 2D-simulation
%resxy=resx for 1D-simulation
%   defines the resolution in x- and y-direction
%subs denotes the number of subbands you want AQUILA to compute
%type=QWX,QWY,QWR denotes type of the region (2D-version only)
%   QWX= quantum well in x-direction (y-direction quantized, free motion in x-direction)
%   QWY= quantum well in y-direction (x-direction quantized, free motion in y-direction)
%   QWR= quantum wire, both directions quantized
%carrier=GE,XE,LE,HH,LH,SO defines carrier types for which the region
%   is expected to be a quantum region (Gamma-, X- and L-point electrons,
%   heavy, light and split-off holes). Choose any sum of these abbreviations.
%
%Note: overlapping of QBOXes is probably not handled properly

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
   error('add_qbox: INITAQUILA must be called before adding a quantumbox !')
end
aquila_control.progress_check=bitset(aquila_control.progress_check,4);

if nargin==5 %2D simulation
   tp=varargin{1};
   carrier=varargin{2};
else %1D simulation, substitute missing arguments
   tp=QWY;
   carrier=varargin{1};
end

if length(xyminmax)==2 %1D simulation, substitute missing arguments
   xyminmax=[xyminmax(1) 0 xyminmax(2) 0];
   resxy=[resxy(1) 0];
end

%add information to the structure database
aquila_structure.qbox=[aquila_structure.qbox;xyminmax resxy subs tp carrier];

%output some information
if aquila_control.verbose>1
   os=sprintf('added quantum box, type %d, %d subbands, carrier %d',tp,subs,carrier);
   disp(os)
   os=sprintf('%g<=x<=%g, %g<=y<=%g, xres %g, yres %g',xyminmax(1),xyminmax(3),xyminmax(2),xyminmax(4),...
      resxy(1),resxy(2));
   disp(os)
end
