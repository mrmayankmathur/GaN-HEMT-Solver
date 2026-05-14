function charge=sumcharge(phi,varargin)

%SUMCHARGE collect charge
%
%charge=sumcharge(phi)
%charge=sumcharge(phi,deltaphi)
%charge=sumcharge(phi,flag)
%charge=sumcharge(phi,deltaphi,flag)
%
%collects all charges in the structure according to the global variable
%'aquila_control.carriers' for a given electric potential phi (flag=0, default)
%or Dcharge/Dphi (flag=1). In the areas of the QBOXes the classical charge of the
%type specified in the QBOX definition is substituted by the quantum charge density.
%If deltaphi is given, it is used in a predictor scheme to approximate the quantum
%charge density from eigenvalues of a different potential.

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
constants

%first some output
if aquila_control.verbose>0
   disp('sumcharge: collecting all the charges in the structure')               
end

%generate missing arguments
if nargin==1 %we only have phi
   fl=0; %return the density itself
   deltaphi=zeros(size(phi)); %set deltaphi to zero
end
if nargin==2
   if length(varargin{1})>1 %argument 2 is a vector, so it must be deltaphi
      deltaphi=varargin{1};
      fl=0; 
   else %argument 2 is a number, so it must be the flag
      fl=varargin{1}; 
      deltaphi=zeros(size(phi));
   end
end
if nargin==3
   deltaphi=varargin{1};
   fl=varargin{2};
end

%set charge to zero and sum over all carrier types
charge=zeros(size(phi));

%gamma electrons
if bitand(aquila_control.carriers,GE)>0
   %tell the user
   if aquila_control.verbose>1
      disp('gamma electrons')               
   end
   %compute the classical charge or its derivative (if fl=1)
   ch=gencharge(phi,GE,fl);
   %if we already have wavefunctions, then substitute the classical charge density
   %by the quantum charge density in the area of the QBOXes
   if bitget(aquila_control.progress_check,7)>0
      ch=addqcharge(ch,deltaphi,fl,GE);
   end
   %finally add the charge of the gamma electrons to the total charge
   charge=charge+ch;
end

%now follows the same for the other charge types

%X electrons
if bitand(aquila_control.carriers,XE)>0
   if aquila_control.verbose>1
      disp('X electrons')               
   end
   ch=gencharge(phi,XE,fl);
   if bitget(aquila_control.progress_check,7)>0
      ch=addqcharge(ch,deltaphi,fl,XE);
   end
   charge=charge+ch;
end

%L electrons
if bitand(aquila_control.carriers,LE)>0
   if aquila_control.verbose>1
      disp('L electrons')               
   end
   ch=gencharge(phi,LE,fl);
   if bitget(aquila_control.progress_check,7)>0
      ch=addqcharge(ch,deltaphi,fl,LE);
   end
   charge=charge+ch;
end

%heavy holes
if bitand(aquila_control.carriers,HH)>0
   if aquila_control.verbose>1
      disp('heavy holes')               
   end
   ch=gencharge(phi,HH,fl);
   if bitget(aquila_control.progress_check,7)>0
      ch=addqcharge(ch,deltaphi,fl,HH);
   end
   charge=charge+ch;
end

%light holes
if bitand(aquila_control.carriers,LH)>0
   if aquila_control.verbose>1
      disp('light holes')               
   end
   ch=gencharge(phi,LH,fl);
   if bitget(aquila_control.progress_check,7)>0
      ch=addqcharge(ch,deltaphi,fl,LH);
   end
   charge=charge+ch;
end

%split-off holes
if bitand(aquila_control.carriers,SO)>0
   if aquila_control.verbose>1
      disp('split-off holes')               
   end
   ch=gencharge(phi,SO,fl);
   if bitget(aquila_control.progress_check,7)>0
      ch=addqcharge(ch,deltaphi,fl,SO);
   end
   charge=charge+ch;
end

%finally the doping
charge=charge+gencharge(phi,DOP,fl);

%issue a warning to the user, that something might be wrong
%if 'charge' is still empty.
if isempty(charge)
   disp('sumcharge: no charge was created in the structure');
end
