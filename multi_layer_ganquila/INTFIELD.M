function integral=intfield(field)

%INTFIELD integrate over whole structure
%
%integral=intfield(field)
%
%integrates the field over the whole area covered by the structure.
%Does basically the same as routine 'integrate'.

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

if bitget(aquila_control.progress_check,6)==0
   error('intfield: You must run BUILDSTRUCTURE before integrating a field !')
end

%weighted summation
integral=sum(sum(field.*aquila_structure.boxvol));
