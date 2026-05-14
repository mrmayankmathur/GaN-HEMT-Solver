function rhs=genrhspoi(charge,varargin)

%GENRHSPOI form right hand side of Poisson equation
%
%rhs=genrhspoi(charge)
%rhs=genrhspoi(charge,flag)
%
%for a given charge distribution and the structure definition in the global variables
%computes the right hand side of non-linear Poisson equation (flag=0, default).
%If flag=1 then the right hand side of the boundary condition equations are 
%set to zero. This is needed for the generation of the Jacobian.

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

global aquila_structure aquila_control aquila_material
constants

%check for correct progress
if bitget(aquila_control.progress_check,6)==0
   error('genrhspoi: You must run BUILDSTRUCTURE before generating Poisson RHS !')
end

%some output for the user
if aquila_control.verbose>0
   disp('genrhspoi: setting up rhs for Poisson solver')
end

%the size of the structure
nx=length(aquila_structure.xpos)-2;
ny=length(aquila_structure.ypos)-2;

if aquila_control.mode==2 %2D-simulation   
   bv=aquila_structure.boxvol(2:end-1,2:end-1);
   
   %form the right hand side according to charge, its just this line
   rhs=4*pi*E0E0*charge(2:end-1,2:end-1).*bv;
   
   %now incorporate the boundary conditions
   %extend matrix by the boundary nodes
   rhs=[zeros(1,nx+2);zeros(ny,1) rhs zeros(ny,1);zeros(1,nx+2)];
   
   %set boundary conditions if necessary
   if (nargin==1)|((nargin==2)&(varargin{1}==0))      
      %bottom
      %find all the boundary conditions at the bottom and care for overlapping regions
      btype=zeros(size(aquila_structure.xpos));
      bval=btype;
      bindex=find(aquila_structure.bcond(:,3)==BOTTOM);
      for i_count=1:length(bindex)
         ix=intersect(find(aquila_structure.bcond(bindex(i_count),1)<=aquila_structure.xpos),...
            find(aquila_structure.bcond(bindex(i_count),2)>=aquila_structure.xpos));
         bval(ix)=aquila_structure.bcond(bindex(i_count),5);
         btype(ix)=aquila_structure.bcond(bindex(i_count),4);
      end
      %now we have for every node at the bottom the type in 'btype'.
      %find the field-type BCs and scale them by the grid spacing.
      %this is necessary to ensure correct physical units of the equation.
      ix=find(btype==FIELD);
      if ~isempty(ix)
         bval(ix)=bval(ix)*aquila_structure.hy(1);
      end
      %find the potential-type BCs and subtract the bias voltage
      %at the nodes. This is necessary, to ensure, that the surface potential
      %refers to the same original unbiased Fermilevel.
      ix=find(btype==POTENTIAL);
      if ~isempty(ix)
         bval(ix)=bval(ix)+aquila_material.bias(1,ix);
      end
      %finally set insert the values into the rhs-matrix
      rhs(1,:)=bval;
      
      %now follows the same for the other boundaries
      
      %top
      btype=zeros(size(aquila_structure.xpos));
      bval=btype;
      bindex=find(aquila_structure.bcond(:,3)==TOP);
      for i_count=1:length(bindex)
         ix=intersect(find(aquila_structure.bcond(bindex(i_count),1)<=aquila_structure.xpos),...
            find(aquila_structure.bcond(bindex(i_count),2)>=aquila_structure.xpos));
         bval(ix)=aquila_structure.bcond(bindex(i_count),5);
         btype(ix)=aquila_structure.bcond(bindex(i_count),4);
      end
      ix=find(btype==FIELD);
      if ~isempty(ix)
         bval(ix)=bval(ix)*aquila_structure.hy(end);
      end
      ix=find(btype==POTENTIAL);
      if ~isempty(ix)
         bval(ix)=bval(ix)+aquila_material.bias(end,ix);
      end
      rhs(end,:)=bval;
      
      %we also need BC's on the left and right side
      %if we don't have periodic boundary conditions in x-direction
      if aquila_control.periodic~=1
         
         %left
         btype=zeros(ny,1);
         bval=btype;
         bindex=find(aquila_structure.bcond(:,3)==LEFT);
         for i_count=1:length(bindex)
            iy=intersect(find(aquila_structure.bcond(bindex(i_count),1)<=aquila_structure.ypos(2:end-1)),...
               find(aquila_structure.bcond(bindex(i_count),2)>aquila_structure.ypos(2:end-1)));
            bval(iy)=aquila_structure.bcond(bindex(i_count),5);
            btype(iy)=aquila_structure.bcond(bindex(i_count),4);
         end
         iy=find(btype==FIELD);
         if ~isempty(iy)
            bval(iy)=bval(iy)*aquila_structure.hx(1);
         end
         iy=find(btype==POTENTIAL);
         if ~isempty(iy)
            bval(iy)=bval(iy)+aquila_material.bias(iy+1,1);
         end
         rhs(2:end-1,1)=bval;
         
         %right
         btype=zeros(ny,1);
         bval=btype;
         bindex=find(aquila_structure.bcond(:,3)==RIGHT);
         for i_count=1:length(bindex)
            iy=intersect(find(aquila_structure.bcond(bindex(i_count),1)<=aquila_structure.ypos(2:end-1)),...
               find(aquila_structure.bcond(bindex(i_count),2)>aquila_structure.ypos(2:end-1)));
            bval(iy)=aquila_structure.bcond(bindex(i_count),5);
            btype(iy)=aquila_structure.bcond(bindex(i_count),4);
         end
         iy=find(btype==FIELD);
         if ~isempty(iy)
            bval(iy)=bval(iy)*aquila_structure.hx(end);
         end
         iy=find(btype==POTENTIAL);
         if ~isempty(iy)
            bval(iy)=bval(iy)+aquila_material.bias(iy+1,end);
         end
         rhs(2:end-1,end)=bval;
         
         %if we have periodic boundary conditions in x-direction
      else
         rhs(2:end-1,1)=4*pi*E0E0*charge(2:end-1,1).*...
            (aquila_structure.boxvol(2:end-1,1)+aquila_structure.boxvol(2:end-1,end));
         rhs(:,end)=zeros(ny+2,1);
      end
   end
   %now simply make rhs a vector
   rhs=rhs';
   rhs=rhs(:);
   
else %1D-simulation
   
   bv=aquila_structure.boxvol(2:end-1);
   
   %form the right hand side according to charge
   rhs=4*pi*E0E0*charge(2:end-1).*bv;
   
   %incorporate the boundary conditions
   rhs=[0 rhs 0];
   
   %set BCs if necessary, this is basically the same as in the 2D-simulation part above
   if (nargin==1)|((nargin==2)&(varargin{1}==0))
      %left
      bindex=find(aquila_structure.bcond(:,3)==LEFT);
      if ~isempty(bindex)
         bindex=bindex(end);
         if aquila_structure.bcond(bindex,4)==FIELD
            rhs(1)=aquila_structure.bcond(bindex,5);
         else
            rhs(1)=(aquila_structure.bcond(bindex,5)+aquila_material.bias(1))/aquila_structure.hx(1);
         end   
      end
      
      %right
      bindex=find(aquila_structure.bcond(:,3)==RIGHT);
      if ~isempty(bindex)
         bindex=bindex(end);
         if aquila_structure.bcond(bindex,4)==FIELD
            rhs(end)=aquila_structure.bcond(bindex,5);
         else
            rhs(end)=(aquila_structure.bcond(bindex,5)+aquila_material.bias(end))/aquila_structure.hx(end);
         end   
      end
   end
   
   rhs=rhs';
end   

   