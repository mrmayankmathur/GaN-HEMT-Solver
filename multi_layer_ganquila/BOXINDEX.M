function [ix,iy]=boxindex(x,varargin)

%BOXINDEX find nodes
%
%[ix,iy]=boxindex(x,y,box)      for 2D simulation
%ix=boxindex(x,box)             for 1D simulation
%
%x = vector of the node positions in x-direction
%y = vector of the node positions in y-direction (2D-simulation only)
%box=[xmin ymin xmax ymax] 2D-simulation
%box=[xmin xmax] 1D-simulation
%    denotes the box you want to find
%
%ix = index into the x-node vector denotes all nodes
%   with xmin <= node-position < xmax, i.e. the xmax-node is not included
%iy = same for y-nodes

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

if nargin==2
   box=varargin{1};
   box=[box(1) 0 box(2) 0];
   iy=1;
else
   y=varargin{1};
   box=varargin{2};
   iy=intersect(find(box(2)<=y),find(box(4)>y));
   if isempty(iy)&(aquila_control.mode==1)
      iy=1;
   end
end
ix=intersect(find(box(1)<=x),find(box(3)>x));

