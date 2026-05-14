function charge=gencharge(phi,tp,varargin)

%GENCHARGE compute charge density
%
%charge=gencharge(phi,type)
%charge=gencharge(phi,type,flag)
%
%returns charge of certain type dependent on potential phi and
%Fermi energy (per A^3) (flag=0, default) or returns derivative of charge (flag=1)
%
%phi is the electric potential for which the charge density is to be returned
%type indicates type of charge
%   type is one of GE,XE,LE,HH,LH,DOP (see file 'constants')
%flag returns charge (flag=0, default) or Dcharge/Dphi (flag=1)

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

global aquila_control aquila_material
constants

%check for correct execution order
if bitget(aquila_control.progress_check,6)==0
   error('gencharge: You must run BUILDSTRUCTURE before generating charge !')
end

%substitute missing arguments
if nargin==2
   fl=0;
else
   fl=varargin{1};
end

switch tp %check, which type of charge is to be returned
   
case GE %gamma electrons
   eta=(aquila_control.Efermi-aquila_material.bias-(aquila_material.eg-phi))/(KB*aquila_control.T);
   %the second Fermi integral accounts for gamma non-parabolicity
   switch fl
   case 0 %return the charge
      charge=-2*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 * (aquila_material.megd.^1.5).*...
         (fermi(1/2,eta)+(15*0.83*KB*aquila_control.T/4)*fermi(3/2,eta)./aquila_material.eg6g8);      
   case 1 %return derivative of charge
      charge=-2*(1/(KB*aquila_control.T))*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.megd.^1.5).*(fermi(-1/2,eta)+(15*0.83*KB*aquila_control.T/4)*...
         fermi(1/2,eta)./aquila_material.eg6g8);      
   end
   
   %now the same for all the other types of carriers
   
case XE %X electrons
   eta=(aquila_control.Efermi-aquila_material.bias-(aquila_material.ex-phi))/(KB*aquila_control.T);
   switch fl
   case 0
      charge=-2*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.mexd.^1.5).*fermi(1/2,eta);      
   case 1
      charge=-2*(1/(KB*aquila_control.T))*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.mexd.^1.5).*fermi(-1/2,eta);      
   end
   
case LE %L electrons
   eta=(aquila_control.Efermi-aquila_material.bias-(aquila_material.el-phi))/(KB*aquila_control.T);
   switch fl
   case 0
      charge=-2*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.meld.^1.5).*fermi(1/2,eta);      
   case 1
      charge=-2*(1/(KB*aquila_control.T))*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.meld.^1.5).*fermi(-1/2,eta);      
   end
   
case LH %gamma light holes
   eta=-(aquila_control.Efermi-aquila_material.bias-(aquila_material.ev-phi))/(KB*aquila_control.T);
   switch fl
   case 0
      charge=2*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.mlhd.^1.5).*fermi(1/2,eta);      
   case 1
      charge=-2*(1/(KB*aquila_control.T))*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.mlhd.^1.5).*fermi(-1/2,eta);      
   end
   
case HH %gamma heavy holes
   eta=-(aquila_control.Efermi-aquila_material.bias-(aquila_material.ev-phi))/(KB*aquila_control.T);
   switch fl
   case 0
      charge=2*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.mhhd.^1.5).*fermi(1/2,eta);         
   case 1
      charge=-2*(1/(KB*aquila_control.T))*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.mhhd.^1.5).*fermi(-1/2,eta);         
   end
   
case SO %gamma split off holes
   eta=-(aquila_control.Efermi-aquila_material.bias-(aquila_material.eso-phi))/(KB*aquila_control.T);
   switch fl
   case 0
      charge=2*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.msod.^1.5).*fermi(1/2,eta);         
   case 1
      charge=-2*(1/(KB*aquila_control.T))*(M0*KB*aquila_control.T/(2*pi*HBAR*HBAR)).^1.5 *...
         (aquila_material.msod.^1.5).*fermi(-1/2,eta);         
   end
   
%now the doping charge
case DOP
   %n-type doping
   ix=find(aquila_material.doping<0);
   eta=-(aquila_control.Efermi-aquila_material.bias(ix)-(aquila_material.dop(ix)-phi(ix)))/(KB*aquila_control.T);
   charge=zeros(size(phi));
   switch fl
   case 0 %return doping charge
      if aquila_control.fix_doping==1   %fully ionized doping, needed to fix convergence problems         
         %The '-' sign here and in the following is correct, because the variable
         %'aquila_material.doping' is negative for n-type doping by definition.
         %With this '-' sign a positive charge results.
         charge(ix)=-aquila_material.doping(ix);
      else
         charge(ix)=-aquila_material.doping(ix).*(1-1./(1+0.5*exp(eta)));
      end   
   case 1 %return derivative of doping charge
      if aquila_control.fix_doping==0  %stays zero for fully ionized doping
         i2=find(eta<100); %to fix overflow errors
         ix=ix(i2);
         tmp=exp(eta(i2));
         tmp2=(1+0.5*tmp);
         tmp2=tmp2.*tmp2;
         charge(ix)=(1/(KB*aquila_control.T))*aquila_material.doping(ix).*( 0.5*(tmp./tmp2) );
      end
   end
   %p-type doping
   %This is incorporated only extremely rudimentary as always
   %fully ionized space charge. This is typically used to model
   %traps at interfaces or other negatively charged structures
   %like quantum dots.
   ix=find(aquila_material.doping>0);
   charge(ix)=-aquila_material.doping(ix);
   
%inform the user, if the requested property is undefined for some reason
otherwise
   error('gencharge: Property undefined!');
end
