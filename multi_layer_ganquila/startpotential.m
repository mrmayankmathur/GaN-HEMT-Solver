function startpotential(startpot)

%STARTPOTENTIAL use non-zero startpotential
%
%startpotential(phi)
%
%Allows you to specify a potential for starting the iteration
%different form the default flat (all zero) potential.
%The field phi must have the correct size and can be obtained
%e.g. from a previous run of a similar structure. Using an
%external startpotential also means, that the Schroedinger solver
%is switched on immediately at the beginning of the iteration.

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

aquila_control.phistart=startpot; %save the startpotential for later use
