function integral=integrate(field,posbox)

%INTEGRATE integrate a field
%
%integral=integrate(field,posbox)
%
%integrates field over the area defined in posbox
%posbox=[xmin ymin xmax ymax] for 2D
%posbox=[xmin xmax] for 1D
%
%Note: the routine finds the grid nodes contained in the box defined in posbox
%   and sums the values of the corresponding nodes weighted by the area covered
%   by these nodes. It does not correctly handle positions between nodes.

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

%check execution order
if bitget(aquila_control.progress_check,6)==0
   error('integrate: You must run BUILDSTRUCTURE before integrating in the structure !')
end

%for 1D simulation extend position box
if length(posbox)==2
   posbox=[posbox(1) 0 posbox(2) 0];
end

%find position of given box within global grid
[ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,posbox);
ix=[ix ix(end)+1];
if aquila_control.mode==2
   iy=[iy iy(end)+1];
end

%summation weighted by boxvolume
integral=sum(sum(field(iy,ix).*aquila_structure.boxvol(iy,ix)));