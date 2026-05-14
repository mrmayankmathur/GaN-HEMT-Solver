function charge=addqcharge(charge,deltaphi,fl,tp)

%ADDQCHARGE add QBOX charge
%
%charge=addqcharge(charge,deltaphi,flag,type)
%
%Adds the charge of a certain type of all QBOXes to charge. In the field 'charge'
%the areas of the QBOXes are zeroed and the charge in these areas substituted
%by the quantum charge of the QBOXes. deltaphi is added to the
%energylevel in the area of the QBOXes (predictor-scheme).
%If flag=1, then the derivative of the quantum charge is inserted in 'charge'.

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

global aquila_control aquila_structure
constants

%check for correct execution order
if bitget(aquila_control.progress_check,6)==0
   error('addqcharge: You must run BUILDSTRUCTURE before generating charge !')
end
if bitget(aquila_control.progress_check,7)==0
   error('addqcharge: You must run SCHRSOLVE before generating quantum charge !')
end

%output for the user
if aquila_control.verbose>0
   disp('addqcharge: substitute quantum charge')               
end

%for all QBOXes
if ~isempty(aquila_structure.qbox)
   for nr=1:length(aquila_structure.qbox(:,1))
      
      %find the position of the QBOX within the grid
      [ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,aquila_structure.qbox(nr,[1:4]));
      ix=[ix ix(end)+1];
      if aquila_control.mode==2
         iy=[iy iy(end)+1];
      end
      dphi=deltaphi(iy,ix); %extract the corresponding part from deltaphi
      charge(iy,ix)=zeros(size(charge(iy,ix))); %delete the charge in the QBOX area
      for sub=1:aquila_structure.qbox(nr,7) %for all subbands
         %Gamma electrons
         %if the QBOX contains gamma electrons and gamma electrons are requested
         if (bitand(aquila_structure.qbox(nr,9),GE)>0)&(tp==GE)
            if aquila_control.verbose>1
               os=sprintf('QBOX %d, subband %d, gamma electrons',nr,sub);
               disp(os)               
            end
            %add the corresponding quantum charge to the charge field
            charge(iy,ix)=charge(iy,ix)+genqcharge(nr,GE,sub,dphi,fl);
         end
         
         %now follows the same for the other types of charge
         
         %X-electrons
         if (bitand(aquila_structure.qbox(nr,9),XE)>0)&(tp==XE)
            if aquila_control.verbose>1
               os=sprintf('QBOX %d, subband %d, X electrons',nr,sub);
               disp(os)               
            end
            charge(iy,ix)=charge(iy,ix)+genqcharge(nr,XE,sub,dphi,fl);
         end
         %L-electrons
         if (bitand(aquila_structure.qbox(nr,9),LE)>0)&(tp==LE)
            if aquila_control.verbose>1
               os=sprintf('QBOX %d, subband %d, L electrons',nr,sub);
               disp(os)               
            end
            charge(iy,ix)=charge(iy,ix)+genqcharge(nr,LE,sub,dphi,fl);
         end
         %heavy holes
         if (bitand(aquila_structure.qbox(nr,9),HH)>0)&(tp==HH)
            if aquila_control.verbose>1
               os=sprintf('QBOX %d, subband %d, heavy holes',nr,sub);
               disp(os)               
            end
            charge(iy,ix)=charge(iy,ix)+genqcharge(nr,HH,sub,dphi,fl);
         end
         %light holes
         if (bitand(aquila_structure.qbox(nr,9),LH)>0)&(tp==LH)
            if aquila_control.verbose>1
               os=sprintf('QBOX %d, subband %d, light holes',nr,sub);
               disp(os)               
            end
            charge(iy,ix)=charge(iy,ix)+genqcharge(nr,LH,sub,dphi,fl);
         end
         %split-off holes
         if (bitand(aquila_structure.qbox(nr,9),SO)>0)&(tp==SO)
            if aquila_control.verbose>1
               os=sprintf('QBOX %d, subband %d, split-off holes',nr,sub);
               disp(os)               
            end
            charge(iy,ix)=charge(iy,ix)+genqcharge(nr,SO,sub,dphi,fl);
         end
      end
   end
else %if this routine was called without QBOXes defined, this should neve happen
   disp('addqcharge: no QBOXes defined, so no quantum charge was added !');
end

