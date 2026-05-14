function charge=genqcharge(nr,tp,sub,varargin)

%GENQCHARGE compute quantum charge density
%
%charge=genqcharge(nr,tp,sub)
%charge=genqcharge(nr,tp,sub,deltaphi)
%charge=genqcharge(nr,tp,sub,deltaphi,flag)
%
%returns quantum charge of certain type tp for quantum box nr
%dependent on Fermi energy (per Angstrom^3). If deltaphi is given, then 
%deltaphi is added to the energy level of the subband.
%If flag=1 then the derivative of the charge is returned.
%
%nr indicates the number of the QBOX for which the density is to be calculated
%tp indicates the type of charge
%   tp is one of GE,XE,LE,HH,LH,SO (see file 'constants')
%sub indicates the subband whose charge density is to be returned

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

global aquila_control aquila_structure aquila_subbands aquila_material
constants

%check execution order
if bitget(aquila_control.progress_check,6)==0
   error('genqcharge: You must run BUILDSTRUCTURE before generating charge !')
end
if bitget(aquila_control.progress_check,7)==0
   error('genqcharge: You must run SCHRSOLVE before generating quantum charge !')
end

%substitute missing arguments
if nargin==3
   fl=0;
   deltaphi=[];
elseif nargin==4
   fl=0;
   deltaphi=varargin{1};
else
   fl=varargin{2};
   deltaphi=varargin{1};  
end   

charge=[];
%some checks
if nr>length(aquila_structure.qbox(:,1))
   disp('genqcharge: this QBOX is not defined !');
   return
end
if bitand(aquila_structure.qbox(:,9),tp)==0
   disp('genqcharge: this carrier type is not defined in this QBOX!');
   return
end

%find the position of the QBOX within the grid
[ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,aquila_structure.qbox(nr,[1:4]));
ix=[ix ix(end)+1];
if aquila_control.mode==2
   iy=[iy iy(end)+1];
end

%get wavefunction, energy level and mass of the requested subband QBOX
switch tp
case GE %gamma electrons
   if sub>length(aquila_subbands.ge(nr).E(:,1))
      disp('genqcharge: this subband is not defined !');
      return
   end
   m=aquila_material.megd;
   psi=aquila_subbands.ge(nr).psi(:,(sub-1)*length(ix)+1:sub*length(ix));
   E=aquila_subbands.ge(nr).E(sub,:);
case XE %X-electrons
   if sub>length(aquila_subbands.xe(nr).E(:,1))
      disp('genqcharge: this subband is not defined !');
      return
   end
   m=aquila_material.mexd;
   psi=aquila_subbands.xe(nr).psi(:,(sub-1)*length(ix)+1:sub*length(ix));
   E=aquila_subbands.xe(nr).E(sub,:);
case LE %L-electrons
   if sub>length(aquila_subbands.le(nr).E(:,1))
      disp('genqcharge: this subband is not defined !');
      return
   end
   m=aquila_material.meld;
   psi=aquila_subbands.le(nr).psi(:,(sub-1)*length(ix)+1:sub*length(ix));
   E=aquila_subbands.le(nr).E(sub,:);
case HH %heavy holes
   if sub>length(aquila_subbands.hh(nr).E(:,1))
      disp('genqcharge: this subband is not defined !');
      return
   end
   m=aquila_material.mhhd;
   psi=aquila_subbands.hh(nr).psi(:,(sub-1)*length(ix)+1:sub*length(ix));
   E=aquila_subbands.hh(nr).E(sub,:);
case LH %light holes
   if sub>length(aquila_subbands.lh(nr).E(:,1))
      disp('genqcharge: this subband is not defined !');
      return
   end
   m=aquila_material.mlhd;
   psi=aquila_subbands.lh(nr).psi(:,(sub-1)*length(ix)+1:sub*length(ix));
   E=aquila_subbands.lh(nr).E(sub,:);
case SO %split-off holes
   if sub>length(aquila_subbands.so(nr).E(:,1))
      disp('genqcharge: this subband is not defined !');
      return
   end
   m=aquila_material.msod;
   psi=aquila_subbands.so(nr).psi(:,(sub-1)*length(ix)+1:sub*length(ix));
   E=aquila_subbands.so(nr).E(sub,:);
otherwise
   disp('genqcharge: Carrier type undefined!');
end

%now compute the corresponding charge density

psi=psi.*psi; %form square of wavefunction, abs is not necessary here because psi is real
if isempty(deltaphi)
   deltaphi=zeros(size(psi));
end
switch fl
case 0 %we need the charge itself
   switch tp
   case {GE,XE,LE} %electrons
      switch aquila_structure.qbox(nr,8)
      case QWX %quantum wells in x-direction
         charge=-(KB*aquila_control.T*M0/(pi*HBAR*HBAR))*m(iy,ix).*psi.*...
            (log(1+exp( (ones(length(iy),1)*(aquila_control.Efermi-E)+deltaphi-...
            aquila_material.bias(iy,ix))./(KB*aquila_control.T)) ));
      case QWY %quantum well in y-direction
         charge=-(KB*aquila_control.T*M0/(pi*HBAR*HBAR))*m(iy,ix).*psi.*...
            (log(1+exp( ( (aquila_control.Efermi-E)'*ones(1,length(ix)) +deltaphi-...
            aquila_material.bias(iy,ix))./(KB*aquila_control.T)) ));
      case QWR %quantum wire
         charge=-sqrt((KB*aquila_control.T*M0/(2*pi*HBAR*HBAR)))*sqrt(m(iy,ix)).*psi.*...
            fermi(-1/2,(aquila_control.Efermi-E+deltaphi-aquila_material.bias(iy,ix))/(KB*aquila_control.T));      
      end   
   case {HH,LH,SO} %the same for holes, same formulas with positive sign and energies swapped
      switch aquila_structure.qbox(nr,8)
      case QWX
         charge=(KB*aquila_control.T*M0/(pi*HBAR*HBAR))*m(iy,ix).*psi.*...
            (log(1+exp( (ones(length(iy),1)*(E-aquila_control.Efermi)-deltaphi+...
            aquila_material.bias(iy,ix))./(KB*aquila_control.T)) ));
      case QWY
         charge=(KB*aquila_control.T*M0/(pi*HBAR*HBAR))*m(iy,ix).*psi.*...
            (log(1+exp( ( (E-aquila_control.Efermi)'*ones(1,length(ix)) -deltaphi+...
            aquila_material.bias(iy,ix))./(KB*aquila_control.T)) ));
      case QWR
         charge=sqrt((KB*aquila_control.T*M0/(2*pi*HBAR*HBAR)))*sqrt(m(iy,ix)).*psi.*...
            fermi(-1/2,(E-deltaphi-aquila_control.Efermi+aquila_material.bias(iy,ix))/(KB*aquila_control.T));      
      end
   end
case 1 %we need the derivative of the charge
   switch tp
   case {GE,XE,LE} %electrons
      switch aquila_structure.qbox(nr,8)
      case QWX
         charge=-(M0/(pi*HBAR*HBAR))*m(iy,ix).*psi.*...
            (1./(1+exp( (ones(length(iy),1)*(E-aquila_control.Efermi)-deltaphi+...
            aquila_material.bias(iy,ix))./(KB*aquila_control.T)) ));
      case QWY
         charge=-(M0/(pi*HBAR*HBAR))*m(iy,ix).*psi.*...
            (1./(1+exp( ((E-aquila_control.Efermi)'*ones(1,length(ix))-deltaphi+...
            aquila_material.bias(iy,ix))./(KB*aquila_control.T))));
      case QWR
         charge=-(1/(KB*aquila_control.T))*sqrt((KB*aquila_control.T*M0/(2*pi*HBAR*HBAR)))*...
            sqrt(m(iy,ix)).*psi.*fermi(-3/2,(aquila_control.Efermi-E+deltaphi-...
            aquila_material.bias(iy,ix))/(KB*aquila_control.T));      
      end   
   case {HH,LH,SO} %holes
      switch aquila_structure.qbox(nr,8)
      case QWX
         charge=(M0/(pi*HBAR*HBAR))*m(iy,ix).*psi.*...
            (1./(1+exp( (ones(length(iy),1)*(aquila_control.Efermi-E)+deltaphi-...
            aquila_material.bias(iy,ix))./(KB*aquila_control.T))))';
      case QWY
         charge=(M0/(pi*HBAR*HBAR))*m(iy,ix).*psi.*...
            (1./(1+exp( ((aquila_control.Efermi-E)'*ones(1,length(ix))+deltaphi-...
            aquila_material.bias(iy,ix))./(KB*aquila_control.T))));
      case QWR
         charge=(1/(KB*aquila_control.T))*sqrt((KB*aquila_control.T*M0/(2*pi*HBAR*HBAR)))*...
            sqrt(m(iy,ix)).*psi.*fermi(-3/2,(E-deltaphi-aquila_control.Efermi+...
            aquila_material.bias(iy,ix))/(KB*aquila_control.T));      
      end
   end
end
