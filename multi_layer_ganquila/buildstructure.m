function buildstructure;

%BUILDSTRUCTURE set up structure
%
%BUILDSTRUCTURE
%
%sets up the grid after the structure is defined.
%This function is normally called by RUNSTRUCTURE.
%BUILDSTRUCTURE also sets up global material property field.

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

global phi aquila_structure aquila_control aquila_material aquila_subbands
constants

%check correct execution order
if bitget(aquila_control.progress_check,2)==0
   error('buildstructure: At least one materialbox must be defined before building the structure !')
end
aquila_control.progress_check=bitset(aquila_control.progress_check,6);

%output, what is happening
if aquila_control.verbose>0
   disp('buildstructure: setting up grid');
end

%generate the grid and the matrix holding the electric potential
[phi,aquila_structure.xpos,aquila_structure.ypos]=makegrid('nodes');

%compute the grid spacing
aquila_structure.hx=diff(aquila_structure.xpos);
nx=length(aquila_structure.xpos)-2;
aquila_structure.hy=diff(aquila_structure.ypos);
ny=length(aquila_structure.ypos)-2;

%set up the area covered by each node
if aquila_control.mode==2 %2D
   aquila_structure.boxvol=([aquila_structure.hy(1) ...
         (aquila_structure.hy(1:ny)+aquila_structure.hy(2:ny+1)) aquila_structure.hy(end)]'*...
      [aquila_structure.hx(1) (aquila_structure.hx(1:nx)+aquila_structure.hx(2:nx+1)) ...
         aquila_structure.hx(end)])./4;
else %1D
   aquila_structure.boxvol=([aquila_structure.hx(1) (aquila_structure.hx(1:nx)+...
         aquila_structure.hx(2:nx+1)) aquila_structure.hx(end)])./2;
end   


%how many quantum boxes do we have
if ~isempty(aquila_structure.qbox)
   nr=length(aquila_structure.qbox(:,1));
else
   nr=0;
end

%compute positions and boxvolume for all QBOXes
if nr>0
   for c=1:nr      
      %find the position of the QBOX within the grid
      [ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,aquila_structure.qbox(c,[1:4]));
      %set up the area covered by each node
      if aquila_control.mode==2 %2D
         aquila_subbands.structure(c).xpos=aquila_structure.xpos([ix ix(end)+1]);
         aquila_subbands.structure(c).ypos=aquila_structure.ypos([iy iy(end)+1]);
         aquila_subbands.structure(c).boxvol=([aquila_structure.hy(iy(1)) ...
               (aquila_structure.hy(iy(1:end-1))+aquila_structure.hy(iy(2:end))) aquila_structure.hy(iy(end))]'*...
            [aquila_structure.hx(ix(1)) (aquila_structure.hx(ix(1:end-1))+aquila_structure.hx(ix(2:end))) ...
               aquila_structure.hx(ix(end))])./4;
      else %1D
         aquila_subbands.structure(c).xpos=aquila_structure.xpos([ix ix(end)+1]);
         aquila_subbands.structure(c).boxvol=([aquila_structure.hx(ix(1)) (aquila_structure.hx(ix(1:end-1))+...
               aquila_structure.hx(ix(2:end))) aquila_structure.hx(ix(end))])./2;
      end      
   end
end

%set up matrices for the x-content, doping and bias
aquila_material.xcontent=makegrid('x');
aquila_material.doping=makegrid('dop');
aquila_material.bias=zeros(size(phi));

%x-content and doping are defined between the grid nodes,
%now extrapolate them onto the grid nodes
if aquila_control.mode==2 %2D
   aquila_material.xcontentx=extend2d(aquila_material.xcontent);
   aquila_material.doping=extend2d(aquila_material.doping);
else %1D
   aquila_material.xcontentx=extend1d(aquila_material.xcontent,aquila_structure.xpos);
   aquila_material.doping=extend1d(aquila_material.doping,aquila_structure.xpos);
end

%now set up the material fields

%some output first
if aquila_control.verbose>0
   disp('buildstructure: setting up material parameters');
end

%find the carrier types used, we need the DOS and the masses for these carriers

%gamma electrons
carr=bitand(aquila_control.carriers,GE); %classical
qcarr=0; %quantum
if nr>0 %for all QBOXes
   for c=1:nr
      qcarr=qcarr+bitand(aquila_structure.qbox(nr,9),GE);
   end
end
%query the required values from the material database
if carr+qcarr>0 %we have gamma electrons
   aquila_material.eg=gaasmaterial(aquila_material.xcontentx,'E_g'); %their energy level
   aquila_material.megd=gaasmaterial(aquila_material.xcontentx,'M_eG'); %DOS mass
   aquila_material.eg6g8=gaasmaterial(aquila_material.xcontentx,'E_G6G8'); %G6-G8 energy distance
   if qcarr>0 %mass for solving Schroedingers equation is needed
      aquila_material.meg=gaasmaterial(aquila_material.xcontent,'M_eG');
   end   
end

%now follows the same for all the other carrier types
%X electrons
carr=bitand(aquila_control.carriers,XE);
qcarr=0;
if nr>0
   for c=1:nr
      qcarr=qcarr+bitand(aquila_structure.qbox(nr,9),XE);
   end
end
if carr+qcarr>0
   aquila_material.ex=gaasmaterial(aquila_material.xcontentx,'E_x');
   aquila_material.mexd=gaasmaterial(aquila_material.xcontentx,'M_eXd');
   if qcarr>0
      aquila_material.mex=gaasmaterial(aquila_material.xcontent,'M_eG');
   end   
end
%L electrons
carr=bitand(aquila_control.carriers,LE);
qcarr=0;
if nr>0
   for c=1:nr
      qcarr=qcarr+bitand(aquila_structure.qbox(nr,9),LE);
   end
end
if carr+qcarr>0
   aquila_material.el=gaasmaterial(aquila_material.xcontentx,'E_l');
   aquila_material.meld=gaasmaterial(aquila_material.xcontentx,'M_eLd');
   if qcarr>0
      aquila_material.mel=gaasmaterial(aquila_material.xcontent,'M_eL');
   end   
end
%heavy holes
carr=bitand(aquila_control.carriers,HH);
qcarr=0;
if nr>0
   for c=1:nr
      qcarr=qcarr+bitand(aquila_structure.qbox(nr,9),HH);
   end
end
if carr+qcarr>0
   aquila_material.ev=gaasmaterial(aquila_material.xcontentx,'E_v');
   aquila_material.mhhd=gaasmaterial(aquila_material.xcontentx,'M_hhd');
   if qcarr>0
      aquila_material.mhh001=gaasmaterial(aquila_material.xcontent,'M_hh001');
      aquila_material.mhh110=gaasmaterial(aquila_material.xcontent,'M_hh110');
   end   
end
%light holes
carr=bitand(aquila_control.carriers,LH);
qcarr=0;
if nr>0
   for c=1:nr
      qcarr=qcarr+bitand(aquila_structure.qbox(nr,9),LH);
   end
end
if carr+qcarr>0
   aquila_material.ev=gaasmaterial(aquila_material.xcontentx,'E_v');
   aquila_material.mlhd=gaasmaterial(aquila_material.xcontentx,'M_lhd');
   if qcarr>0
      aquila_material.mlh001=gaasmaterial(aquila_material.xcontent,'M_lh001');
      aquila_material.mlh110=gaasmaterial(aquila_material.xcontent,'M_lh110');
   end   
end
%split-off holes
carr=bitand(aquila_control.carriers,SO);
qcarr=0;
if nr>0
   for c=1:nr
      qcarr=qcarr+bitand(aquila_structure.qbox(nr,9),SO);
   end
end
if carr+qcarr>0
   aquila_material.eso=gaasmaterial(aquila_material.xcontentx,'E_vso');
   aquila_material.msod=gaasmaterial(aquila_material.xcontentx,'M_so');
   if qcarr>0
      aquila_material.mso=gaasmaterial(aquila_material.xcontent,'M_so');
   end   
end
%donator level
aquila_material.dop=gaasmaterial(aquila_material.xcontentx,'E_d');
%epsilon
aquila_material.epsilon=gaasmaterial(aquila_material.xcontent,'eps');
if ~isempty(aquila_structure.pbox)
   aquila_material.ev=gaasmaterial(aquila_material.xcontentx,'E_v');
   aquila_material.ec=gaasmaterial(aquila_material.xcontentx,'E_c');
end

%set up the field for the bias voltage
if ~isempty(aquila_structure.bias)
   nr=length(aquila_structure.bias(:,1));
else
   nr=0;
end
if nr>0
   for c=1:nr      
      %find the position of the bias box within the grid
      [ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,aquila_structure.bias(c,[1:4]));
      %set up the bias
      aquila_material.bias(iy,ix)=aquila_structure.bias(c,5);
   end
end
