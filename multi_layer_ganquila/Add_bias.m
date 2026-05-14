function add_bias(xyminmax,bias)

%ADD_BIAS new biased region
%
%adds a new biased region to the structure
%In AQUILA there normally exists only one single Fermi level. You may however specify
%biased regions. In these regions then a new quasi-Fermilevel is established, which
%is different from the original Fermilevel by a certain bias voltage.
%These regions and their corresponding bias voltage are defined using ADD_BIAS.
%
%add_bias(xyminmax,bias)
%
%xyminmax=[xmin ymin xmax ymax] for 2D-simulation
%xyminmax=[xmin xmax] or xyminmax=width for 1D-simulation
%   defines the corners of a region with a certain bias level
%bias defines the bias level with respect to the original Fermilevel
%
%Note: You do not have to specify biased regions. The normal Fermilevel is determined
%      automatically and valid in the whole structure, if no biased regions are specified.
%

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
   error('add_mbox: INITAQUILA must be called before adding a biased region !')
end

if length(xyminmax)==2 %layer start and end are given, this means 1D simulation
   xyminmax=[xyminmax(1) 0 xyminmax(2) 0]; %substitute missing parameters
end

%add information to structure database
aquila_structure.bias=[aquila_structure.bias;xyminmax bias];

%output some information
if aquila_control.verbose>1
   os=sprintf('added biased region, bias %g',bias);
   disp(os)
   os=sprintf('%g<=x<=%g, %g<=y<=%g',xyminmax(1),xyminmax(3),xyminmax(2),xyminmax(4));
   disp(os)
end
