function schrsolve(potential,fl)

%SCHRSOLVE solve Schroedinger equation
%
%schrsolve(potential,flag)
%
%Solves Schroedingers equation for all quantum boxes and all carrier types.
%The resulting energies and wavefunctions are stored in the global
%structure aquila_subbands.xx (xx=ge,xe,le,hh,lh,so).
%The necessary information concerning material composition etc. are taken from the 
%global variables characterizing the grid.
%
%potential is the electrostatic potential for which Schroedingers equation is to be solved.
%flag=1 indicates, that old solutions should be adapted to a slightly changed
%   potential via inverse vectoriteration instead of a complete recomputation
%   of the energy spectrum.
%
%Result: aquila_subbands.xx(nr).E = vector of energies or matrix for 1D quantization
%        aquila_subbands.xx(nr).psi = wavefunctions of all subbands
%           size=nr. of solutions * size of corresponding QBOX
%           i.e. psi=[1st 2nd 3rd ..] subband-wavefunction
%        nr numbers the QBOXes in order of definition
%(See file 'structures' for a description of aquila_subbands).

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

global aquila_subbands aquila_control aquila_structure aquila_material

%check for correct execution order
if bitget(aquila_control.progress_check,6)==0
   error('schrsolve: You must run BUILDSTRUCTURE before solving Schroedingers equation !')
end

%define some constants
constants

%tell the user, what we are doing
if aquila_control.verbose>0
   disp('schrsolve: solving Schroedinger equation for all quantum regions')               
end

n=size(aquila_structure.qbox);
for count=1:n(1) %for all QBOXes   
   if bitand(aquila_structure.qbox(count,9),GE)>0 %the QBOX works on gamma electrons
      %find the indices of the corresponding nodes in the grid
      [ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,...
         aquila_structure.qbox(count,[1:4]));
      %get the masses
      mx=aquila_material.meg(iy,ix);
      my=mx; 
      %correct the indices
      ix=[ix ix(end)+1];
      if aquila_control.mode==2
         iy=[iy iy(end)+1];
      end
      %compute the potential = sum of conduction band edge and electric potential
      pot=aquila_material.eg(iy,ix)-potential(iy,ix);
      %some output for the user
      if aquila_control.verbose>1
         os=sprintf('qbox nr %d, Gamma electrons, type %d',count,aquila_structure.qbox(count,8));
         disp(os)               
      end
      %call the driver routine for the solver
      if length(aquila_subbands.ge)>=count %we already have subbands -> use them in the solver
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),aquila_subbands.ge(count),fl);
      else %we have no subbands computed before
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),[],fl);
      end
      %store the result
      aquila_subbands.ge(count).E=E;
      aquila_subbands.ge(count).psi=ev;
   end
   
   %here comes the same stuff for X-point electrons
   if bitand(aquila_structure.qbox(count,9),XE)>0
      [ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,...
         aquila_structure.qbox(count,[1:4]));
      mx=aquila_material.mex(iy,ix);
      my=mx;
      ix=[ix ix(end)+1];
      if aquila_control.mode==2
         iy=[iy iy(end)+1];
      end
      pot=aquila_material.ex(iy,ix)-potential(iy,ix);
      if aquila_control.verbose>1
         os=sprintf('qbox nr %d, X electrons, type %d',count,aquila_structure.qbox(count,8));
         disp(os)               
      end
      if length(aquila_subbands.xe)>=count
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),aquila_subbands.xe(count),fl);
      else
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),[],fl);
      end
      aquila_subbands.xe(count).E=E;
      aquila_subbands.xe(count).psi=ev;
   end
   
   %L-point electrons
   if bitand(aquila_structure.qbox(count,9),LE)>0
      [ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,...
         aquila_structure.qbox(count,[1:4]));
      mx=aquila_material.mel(iy,ix);
      my=mx;
      ix=[ix ix(end)+1];
      if aquila_control.mode==2
         iy=[iy iy(end)+1];
      end
      pot=aquila_material.el(iy,ix)-potential(iy,ix);
      if aquila_control.verbose>1
         os=sprintf('qbox nr %d, L electrons, type %d',count,aquila_structure.qbox(count,8));
         disp(os)               
      end
      if length(aquila_subbands.le)>=count
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),aquila_subbands.le(count),fl);
      else
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),[],fl);
      end
      aquila_subbands.le(count).E=E;
      aquila_subbands.le(count).psi=ev;
   end
   
   %light holes
   if bitand(aquila_structure.qbox(count,9),LH)>0
      [ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,...
         aquila_structure.qbox(count,[1:4]));
      mx=aquila_material.mlh001(iy,ix);
      my=aquila_material.mlh110(iy,ix);
      ix=[ix ix(end)+1];
      if aquila_control.mode==2
         iy=[iy iy(end)+1];
      end
      pot=-(aquila_material.ev(iy,ix)-potential(iy,ix));
      if aquila_control.verbose>1
         os=sprintf('qbox nr %d, light holes, type %d',count,aquila_structure.qbox(count,8));
         disp(os)               
      end
      if length(aquila_subbands.lh)>=count
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),aquila_subbands.lh(count),fl);
      else
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),[],fl);
      end
      aquila_subbands.lh(count).E=-E;
      aquila_subbands.lh(count).psi=ev;
   end
   
   %heavy holes
   if bitand(aquila_structure.qbox(count,9),HH)>0
      [ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,...
         aquila_structure.qbox(count,[1:4]));
      mx=aquila_material.mhh001(iy,ix);
      my=aquila_material.mhh110(iy,ix);
      ix=[ix ix(end)+1];
      if aquila_control.mode==2
         iy=[iy iy(end)+1];
      end
      pot=-(aquila_material.ev(iy,ix)-potential(iy,ix));
      if aquila_control.verbose>1
         os=sprintf('qbox nr %d, heavy holes, type %d',count,aquila_structure.qbox(count,8));
         disp(os)               
      end
      if length(aquila_subbands.hh)>=count
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),aquila_subbands.hh(count),fl);
      else
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),[],fl);
      end
      aquila_subbands.hh(count).E=-E;
      aquila_subbands.hh(count).psi=ev;
   end
   
   %split-off holes
   if bitand(aquila_structure.qbox(count,9),SO)>0
      [ix,iy]=boxindex(aquila_structure.xpos,aquila_structure.ypos,...
         aquila_structure.qbox(count,[1:4]));
      mx=aquila_material.mso(iy,ix);%DOS mass probably not correct here
      my=mx;
      ix=[ix ix(end)+1];
      if aquila_control.mode==2
         iy=[iy iy(end)+1];
      end
      pot=-(aquila_material.eso(iy,ix)-potential(iy,ix));
      if aquila_control.verbose>1
         os=sprintf('qbox nr %d, split-off holes, type %d',count,aquila_structure.qbox(count,8));
         disp(os)               
      end
      if length(aquila_subbands.so)>=count
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),aquila_subbands.so(count),fl);
      else
         [E,ev]=solveit(pot,ix,iy,mx,my,aquila_structure.qbox(count,7),...
            aquila_structure.qbox(count,8),[],fl);
      end
      aquila_subbands.so(count).E=-E;
      aquila_subbands.so(count).psi=ev;
   end
end
%set the flag, that we now have subbands
aquila_control.progress_check=bitset(aquila_control.progress_check,7);   

%the driver routine for the solvers
function [E,ev]=solveit(pot,xp,yp,mx,my,subb,tp,subbands,fl);
global aquila_control aquila_structure
constants
%for every type of QBOX call the corresponding solver
%according to the flag 'fl' use Arnoldi (schrsolv..) or inverse vectoriteration (schrtrack..)
switch tp
case QWR %x and y quantized, a quantum wire
   if (bitget(aquila_control.progress_check,7)>0)&(fl==1)&(~isempty(subbands))
      [E,ev]=schrtrack2D(pot,xp,yp,mx,my,subbands.E,subbands.psi);
   else
      [E,ev]=schrsolv2D(pot,xp,yp,mx,my,subb);
   end
case QWX %y motion quantized, a quantum well in y-direction
   if (bitget(aquila_control.progress_check,7)>0)&(fl==1)&(~isempty(subbands))
      [E,ev]=schrtrack1D(pot,aquila_structure.xpos(xp),aquila_structure.ypos(yp),...
         my,subbands.E,subbands.psi);
   else
      [E,ev]=schrsolv1D(pot,aquila_structure.xpos(xp),aquila_structure.ypos(yp),my,subb);
   end
case QWY %x motion quantized, a quantum well in x-direction
   %this uses the same routine as in the QWX-case
   %so we must transpose the whole scenario to exchange x- and y-direction
   %and thereby froming a QWX scenario
   if (fl==1)&(~isempty(subbands))
      if aquila_control.mode==2
         psi=[];
         n=length(xp);
         for i_count=0:length(subbands.E(:,1))-1
            psi=[psi subbands.psi(:,i_count*n+1:(i_count+1)*n)'];
         end
      else
         psi=reshape(subbands.psi',length(xp),length(subbands.E));
      end
   end
   if (bitget(aquila_control.progress_check,7)>0)&(fl==1)&(~isempty(subbands))
      [E,ev]=schrtrack1D(pot',aquila_structure.ypos(yp),aquila_structure.xpos(xp),...
         mx',subbands.E,psi);
   else
      [E,ev]=schrsolv1D(pot',aquila_structure.ypos(yp),aquila_structure.xpos(xp),mx',subb);
   end
   %now we transpose the results to get back to the original QWY scenario
   if aquila_control.mode==2
      psi=[];
      n=length(yp);
      for i_count=0:length(E(:,1))-1
         psi=[psi ev(:,i_count*n+1:(i_count+1)*n)'];
      end
      ev=psi;
   else
      ev=ev(:)';
   end
end
