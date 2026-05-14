%Known bugs and things that AQUILA 1.0 cannot handle
%
%- The material database might not be completely correct, I just copied some
%  values from some papers and code and some values from Landolt-Bornstein/Adachi.
%
%- The Gamma nonparabolicity is taken into account only for classical treated
%  electron densities. For quantum densities and for the computation of
%  energy levels the parabolic approximation is used. Thus especially higher 
%  levels and densities in higher subbands may be wrong.
%
%- The algorithm may be failing to converge for certain boundary conditions
%  and structures as the iteration gets trapped in a local minimum.
%
%- p-doping is included only as fixed space charge.
%
%- drift and diffusion is not included. Thus diffusion regions can not be handeled properly.
%
%- Sometimes a 'matrix close to singular' warning from routine 'inviter' occurs.
%  This may be ignored.
%
%- inverse vectoriteration sometimes loses eigenvalues.
%
%- several other simplifying assumptions. Mail me for the details on whether and how
%  something is treated.

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
