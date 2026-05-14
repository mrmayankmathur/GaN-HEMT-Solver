function genmatrixpoi

%GENMATRIXPOI compute matrix for Poisson solution in 2D and 1D
%
%H=genmatrixpoi
%
%returns the Poisson matrix according to the node positions and material definitions
%given in the global variables describing the structure

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

global aquila_structure aquila_control aquila_material poimatrix
constants

%check correct execution order
if bitget(aquila_control.progress_check,1)==0
   error('genmatrixpoi: INITAQUILA must be called before generating the Poisson matrix !')
end

%output, what is happening
if aquila_control.verbose>0
   disp('genmatrixpoi: setting up matrix for Poisson solver')
end
nx=length(aquila_structure.xpos)-2;
ny=length(aquila_structure.ypos)-2;

%now generate the matrix for Poisson solution
if aquila_control.mode==2 %2D-simulation
   
   %set up values for inner nodes only,
   %nodes on the border are incorporated via the boundary conditions
   
   %some useful definitions first
   bv=aquila_structure.boxvol(2:end-1,2:end-1);
   h2x=ones(ny+1,1)*aquila_structure.hx;
   h2y=aquila_structure.hy'*ones(1,nx+1);
   
   %we set up the coefficients on a matrix corresponding to the grid of the nodes
   %first and then construct the final Poisson matrix at the end
   
   % (d/dx)^2+(d/dy)^2, coefficients of the inner part of the structure
   f1=(aquila_material.epsilon(1:ny,2:nx+1).*h2y(1:ny,2:nx+1)+...
      aquila_material.epsilon(2:ny+1,2:nx+1).*h2y(2:ny+1,2:nx+1))./(h2x(1:ny,2:nx+1).*2);
   f2=(aquila_material.epsilon(1:ny,1:nx).*h2y(1:ny,1:nx)+...
      aquila_material.epsilon(2:ny+1,1:nx).*h2y(2:ny+1,1:nx))./(h2x(1:ny,1:nx).*2);
   f3=(aquila_material.epsilon(1:ny,1:nx).*h2x(1:ny,1:nx)+...
      aquila_material.epsilon(1:ny,2:nx+1).*h2x(1:ny,2:nx+1))./(h2y(1:ny,1:nx).*2);
   f4=(aquila_material.epsilon(2:ny+1,1:nx).*h2x(2:ny+1,1:nx)+...
      aquila_material.epsilon(2:ny+1,2:nx+1).*h2x(2:ny+1,2:nx+1))./(h2y(2:ny+1,1:nx).*2);
   d=f1+f2+f3+f4; %the diagonal of the poisson matrix
   d1=-f1; %1st superdiagonal
   d_1=-f2; %1st subdiagonal
   dn=-f4; %nth superdiagonal
   d_n=-f3; %nth subdiagonal
   
   %up to here the matrix is symmetric
   %now we insert the boundary conditions which usually will introduce
   %asymmetry. It should be possible to make the problem symmetric again
   %but it will make the program much more confusing
   
   %boundary conditions
   
   %add the necessary rows and column to the coefficient matrices
   %corresponding to the boundary nodes
   d=[zeros(1,nx+2);zeros(ny,1) d zeros(ny,1);zeros(1,nx+2)];
   d1=[zeros(1,nx+2);zeros(ny,1) d1 zeros(ny,1);zeros(1,nx+2)];
   d_1=[zeros(1,nx+2);zeros(ny,1) d_1 zeros(ny,1);zeros(1,nx+2)];
   dn=[zeros(1,nx+2);zeros(ny,1) dn zeros(ny,1);zeros(1,nx+2)];
   d_n=[zeros(1,nx+2);zeros(ny,1) d_n zeros(ny,1);zeros(1,nx+2)];
   
   %now set up the coefficients according to the boundary conditions
   
   %bottom
   %find all the boundary conditions at the bottom and care for overlapping regions
   btype=zeros(1,nx+2);
   bindex=find(aquila_structure.bcond(:,3)==BOTTOM);
   for i_count=1:length(bindex)
      ix=intersect(find(aquila_structure.bcond(bindex(i_count),1)<=aquila_structure.xpos),...
         find(aquila_structure.bcond(bindex(i_count),2)>=aquila_structure.xpos));
      btype(ix)=aquila_structure.bcond(bindex(i_count),4);
   end
   %now we have for every node at the bottom the type in 'btype'.
   %We don't need the value here, because it enters only on the
   %right hand side of Poissons equation which is constructed in 'genrhspoi'
   %find all the potential-type BCs and put a 1 on the diagonal
   ix=find(btype==POTENTIAL);
   if ~isempty(ix)
      d(1,ix)=ones(1,length(ix));
   end
   %find the field-type BCs and put a -1 on the diagonal and a 1 on the nth superdiagonal
   ix=find(btype==FIELD);
   if ~isempty(ix)
      d(1,ix)=-ones(1,length(ix));
      dn(1,ix)=ones(1,length(ix));
   end
   
   %now follows the same for the other boundarys
   
   %top
   btype=zeros(1,nx+2);
   bindex=find(aquila_structure.bcond(:,3)==TOP);
   for i_count=1:length(bindex)
      ix=intersect(find(aquila_structure.bcond(bindex(i_count),1)<=aquila_structure.xpos),...
         find(aquila_structure.bcond(bindex(i_count),2)>=aquila_structure.xpos));
      btype(ix)=aquila_structure.bcond(bindex(i_count),4);
   end
   ix=find(btype==POTENTIAL);
   if ~isempty(ix)
      d(end,ix)=ones(1,length(ix));
   end
   ix=find(btype==FIELD);
   if ~isempty(ix)
      d(end,ix)=-ones(1,length(ix));
      d_n(end,ix)=ones(1,length(ix));
   end
   
   %we need left and right boundary conditions,
   %if we don't have periodicity
   if aquila_control.periodic~=1
      %left
      btype=zeros(ny,1);
      bindex=find(aquila_structure.bcond(:,3)==LEFT);
      for i_count=1:length(bindex)
         iy=intersect(find(aquila_structure.bcond(bindex(i_count),1)<=aquila_structure.ypos(2:end-1)),...
            find(aquila_structure.bcond(bindex(i_count),2)>aquila_structure.ypos(2:end-1)));
         btype(iy)=aquila_structure.bcond(bindex(i_count),4);
      end
      iy=find(btype==POTENTIAL);
      if ~isempty(iy)
         d(iy+1,1)=ones(length(iy),1);
      end
      iy=find(btype==FIELD);
      if ~isempty(iy)
         d(iy+1,1)=-ones(length(iy),1);
         d1(iy+1,1)=ones(length(iy),1);
      end
      
      %right
      btype=zeros(ny,1);
      bindex=find(aquila_structure.bcond(:,3)==RIGHT);
      for i_count=1:length(bindex)
         iy=intersect(find(aquila_structure.bcond(bindex(i_count),1)<=aquila_structure.ypos(2:end-1)),...
            find(aquila_structure.bcond(bindex(i_count),2)>aquila_structure.ypos(2:end-1)));
         btype(iy)=aquila_structure.bcond(bindex(i_count),4);
      end
      iy=find(btype==POTENTIAL);
      if ~isempty(iy)
         d(iy+1,end)=ones(length(iy),1);
      end
      iy=find(btype==FIELD);
      if ~isempty(iy)
         d(iy+1,end)=-ones(length(iy),1);
         d_1(iy+1,end)=ones(length(iy),1);
      end
      
      %re-model the coefficients for boundaries,
      %if we have periodic boundary conditions in x-direction
   else
      
      %compute new coefficients on left border
      f1=(aquila_material.epsilon(1:ny,1).*h2y(1:ny,1)+...
         aquila_material.epsilon(2:ny+1,1).*h2y(2:ny+1,1))./(h2x(1:ny,1).*2);
      f2=(aquila_material.epsilon(1:ny,nx+1).*h2y(1:ny,nx+1)+...
         aquila_material.epsilon(2:ny+1,nx+1).*h2y(2:ny+1,nx+1))./(h2x(1:ny,nx+1).*2);
      f3a=(aquila_material.epsilon(1:ny,1).*h2x(1:ny,1))./(h2y(1:ny,1).*2);
      f3b=(aquila_material.epsilon(1:ny,nx+1).*h2x(1:ny,nx+1))./(h2y(1:ny,nx+1).*2);
      f4a=(aquila_material.epsilon(2:ny+1,1).*h2x(2:ny+1,1))./(h2y(2:ny+1,1).*2);
      f4b=(aquila_material.epsilon(2:ny+1,nx+1).*h2x(2:ny+1,nx+1))./(h2y(2:ny+1,nx+1).*2);
      
      %create additional diagonals
      dnx_1=zeros(size(d));
      d_nx=dnx_1;
      
      %insert new coefficients into the matrices
      d(2:end-1,1)=f1+f2+f3a+f3b+f4a+f4b;
      d1(2:end-1,1)=-f1;
      dnx_1(2:end-1,1)=-f2;
      d_n(2:end-1,1)=-f3a-f3b;
      dn(2:end-1,1)=-f4a-f4b;
      
      %set right border == left border
      d(:,end)=ones(ny+2,1);
      dn(:,end)=zeros(ny+2,1);
      d_n(:,end)=zeros(ny+2,1);
      d_nx(:,end)=-ones(ny+2,1);
   end
      
   %check for zeros on the main diagonal. If there are any, then there
   %is something wrong in the specification of the boundary conditions
   ix=find(d==0);
   if ~isempty(ix)
      disp('genmatrixpoi: some boundary points have not been assigned a boundary condition!');
      disp('genmatrixpoi: the poisson solution with this matrix will fail !');
   end
   
   %now construct the final Poisson matrix
   d=d';
   d1=d1';
   dn=dn';
   d_1=d_1';
   d_n=d_n';
   d=d(:);
   d1=d1(:);
   dn=dn(:);
   d_1=d_1(:);
   d_n=d_n(:);
   
   nx=nx+2;
   ny=ny+2;
   n=nx*ny;
   if aquila_control.periodic==1
      dnx_1=dnx_1';
      d_nx=d_nx';
      
      dnx_1=dnx_1(:);
      d_nx=d_nx(:);      
      poimatrix=spdiags([[d_n(1+nx:n);zeros(nx,1)] [d_nx(nx:n);zeros(nx-1,1)] ...
         [d_1(2:n);0] d [0;d1(1:n-1)] [zeros(nx-2,1);dnx_1(1:n-nx+2)]...
         [zeros(nx,1);dn(1:n-nx)]],[-nx -nx+1 -1 0 1 nx-2 nx],n,n);
   else
      poimatrix=spdiags([[d_n(1+nx:n);zeros(nx,1)] [d_1(2:n);0] d...
            [0;d1(1:n-1)] [zeros(nx,1);dn(1:n-nx)]],[-nx -1 0 1 nx],n,n);
   end
   
%now follows the same stuff for the 1D simulation   
else %1D-simulation
   
   %here the same stuff happens as above, but it is much simpler here
   %because its only 1D, so I kept the comments short
   
   %useful definition
   bv=aquila_structure.boxvol(2:end-1);
   
   % (d/dx)^2 inner part   
   f1=aquila_material.epsilon(2:nx+1)./aquila_structure.hx(2:nx+1);
   f2=aquila_material.epsilon(1:nx)./aquila_structure.hx(1:nx);
   d=f1+f2; %main diagonal
   d1=-f1; %1st superdiagonal
   d_1=-f2; %1st subdiagonal
   
   %boundary conditions
   %enlarge the diagonals
   d=[0 d 0];
   d1=[0 d1 0];
   d_1=[0 d_1 0];
   
   %we can only have BCs for the rightmost and leftmost point
   %left
   bindex=find(aquila_structure.bcond(:,3)==LEFT);
   if ~isempty(bindex) %hopefully the user specified a BC
      bindex=bindex(end);
      if aquila_structure.bcond(bindex,4)==POTENTIAL
         d(1)=1/aquila_structure.hx(1); %1 on the diagonal, but scaled to ensure correct units
      end
      if aquila_structure.bcond(bindex,4)==FIELD
         d(1)=-1/aquila_structure.hx(1); %analog for field-BCs
         d1(1)=1/aquila_structure.hx(1);
      end
   else %the user forgot to specify a BC
      disp('genmatrixpoi: no boundary condition on left side !');
      disp('genmatrixpoi: the Poisson solution will fail !');
   end
   
   %now the same for the rightmost node
   %right
   bindex=find(aquila_structure.bcond(:,3)==RIGHT);
   if ~isempty(bindex)
      bindex=bindex(end);
      if aquila_structure.bcond(bindex,4)==POTENTIAL
         d(end)=1/aquila_structure.hx(end);
      end
      if aquila_structure.bcond(bindex,4)==FIELD
         d(end)=-1/aquila_structure.hx(end);
         d_1(end)=1/aquila_structure.hx(end);
      end
   else
      disp('genmatrixpoi: no boundary condition on left side !');
      disp('genmatrixpoi: the Poisson solution will fail !');
   end
      
   %and return the Poisson matrix
   d=d';   
   d1=d1';
   d_1=d_1';
   n=nx+2;
   poimatrix=spdiags([[d_1(2:n);0] d [0;d1(1:n-1)]],[-1 0 1],n,n);
   
end
