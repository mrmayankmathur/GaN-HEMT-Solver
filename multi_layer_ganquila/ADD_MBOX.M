function add_mbox(xyminmax,resxy,x,dop)

%ADD_MBOX new material region
%
%adds a new material region to the structure
%In AQUILA the whole structure to be simulated is composed of rectangular
%regions of GaAs/AlGaAs/AlAs (2D) or layers of these materials (1D).
%These regions and their properties are defined using ADD_MBOX.
%
%add_mbox(xyminmax,resxy,x,dop)
%
%xyminmax=[xmin ymin xmax ymax] for 2D-simulation
%xyminmax=[xmin xmax] or xyminmax=width for 1D-simulation
%   defines the corners of a region filled with the specified material
%resxy=[resx resy] for 2D-simulation
%resxy=resx for 1D-simulation
%   defines the resolution in x- and y-direction desired for this region
%x defines the Aluminum-content in this region, 0<=x<=1
%dop defines the doping level in the region in units cm^-3
%   dop<0 means n-type.
%
%Note 1: the final size of the structure is the smallest rectangle enclosing
%        all MBOXes. AQUILA will enhance the resolution in certain regions to
%        ensure, that all regions get at least the desired resolution.
%Note 2: take care in choosing a good grid. Enhance the resolution where
%        you expect large gradients of the potential or the charge density to proper
%        model these regions and reduce resolution in the uninteresting regions
%        to save computing time.
%Note 3: take care to fill the whole structure with MBOXes. AQUILA will refuse to handle
%        unassigned regions (=free surfaces not on the boundary of the structure)
%        and will warn you if this happens.
%Note 4: MBOXes are processed in order of appearance, so take care 
%        not to overwrite previous definitions by letting regions overlap.
%Note 5: p-type doping is implemented only in a rudimentary way at this stage of the
%        project. It is handeled as a constant negative space charge.
%Note 6: The x-direction is the GaAs(001)-direction, the y-direction is the GaAs(110)-direction.

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
   error('add_mbox: INITAQUILA must be called before adding a materialbox !')
end
aquila_control.progress_check=bitset(aquila_control.progress_check,2);

if length(xyminmax)==1 %only a layer width is given, this means 1D simulation
   if isempty(aquila_structure.mbox) %no layer is defined up to now, so we start at position 0
      xstart=0;
   else
      xstart=aquila_structure.mbox(end,3); %the layer starts, where the previos layer ends
   end
   xyminmax=[xstart 0 xstart+xyminmax 0]; %substitute missing parameters
   resxy=[resxy(1) 0];
end

if length(xyminmax)==2 %layer start and end are given, this also means 1D simulation
   xyminmax=[xyminmax(1) 0 xyminmax(2) 0]; %substitute missing parameters
   resxy=[resxy(1) 0];
end

%add information to structure database
aquila_structure.mbox=[aquila_structure.mbox;xyminmax resxy x dop*1e-24];

%output some information
if aquila_control.verbose>1
   os=sprintf('added material box, xcontent %g, doping %g',x,dop);
   disp(os)
   os=sprintf('%g<=x<=%g, %g<=y<=%g, xres %g, yres %g',xyminmax(1),xyminmax(3),xyminmax(2),xyminmax(4),...
      resxy(1),resxy(2));
   disp(os)
end
