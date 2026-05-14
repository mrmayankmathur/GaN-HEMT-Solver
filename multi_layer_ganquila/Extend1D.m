function b=extend1D(a,x)

%EXTEND1D extrapolate field in 1D
%
%y=extend1D(a,x)
%
%extrapolates a property defined between the nodes to values at the nodes
%
%x = vector defining the position of the nodes (length n)
%a = vector defining the values to be extrapolated (length n-1)
%y = extrapolated vector

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

hx=diff(x);
nx=length(x)-2;
boxvol=hx(1:nx)+hx(2:nx+1);
b=[a(1) (hx(1:nx).*a(1:nx)+hx(2:nx+1).*a(2:nx+1))./boxvol a(end)];
