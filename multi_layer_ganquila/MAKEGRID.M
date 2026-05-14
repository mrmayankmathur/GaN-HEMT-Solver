function [g,xs,ys]=makegrid(tp);

%MAKEGRID makes the grid
%
%[g,x,y]=makegrid(type)
%
%Returns a rectangular grid in matrix g and positions of the nodes in the
%vectors x and y according to the structure definition. Size and values
%of g depend on type of grid.
%This function is normally called by BUILDSTRUCTURE. The user can generate
%fields of the appropriate size by simply copying e.g. the global variables phi or
%the fields in the aquila_material structure.
%
%Example:
%global phi aquila_material
%newnodes=zeros(size(phi));
%newx=zeros(size(aquila_material.xcontent));
%
%type='nodes' : grid on node-points, values=0
%type='x': grid between node-points, values=x-content
%type='dop': grid between node-points, values=doping

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

global aquila_structure aquila_control

%check for correct calling sequence
if bitget(aquila_control.progress_check,2)==0
   error('makegrid: At least one materialbox must exist before running MAKEGRID!')
end

%output some information
if aquila_control.verbose>0
   disp('makegrid: creating grid and nodes')               
end

%create x-position of nodes first

%get all x-position defined in the MBOXes and QBOXes and corresponding resolution
x=[aquila_structure.mbox(:,1);aquila_structure.mbox(:,3)];
xres=[aquila_structure.mbox(:,1) aquila_structure.mbox(:,3) aquila_structure.mbox(:,5)];
if ~isempty(aquila_structure.qbox)
   x=[x;aquila_structure.qbox(:,1);aquila_structure.qbox(:,3)];
   xres=[xres;aquila_structure.qbox(:,1) aquila_structure.qbox(:,3) aquila_structure.qbox(:,5)];
end
if ~isempty(aquila_structure.bias)
   x=[x;aquila_structure.bias(:,1);aquila_structure.bias(:,3)];
   xres=[xres;aquila_structure.bias(:,1) aquila_structure.bias(:,3) abs(aquila_structure.bias(:,1)-aquila_structure.bias(:,3))];
end

%sort them and identify regions of the same resolution
x=sort(unique(x));
r=zeros(size(x));
for count=1:length(x)-1
   [ir1,ic1]=find(x(count)>=xres(:,1));
   [ir2,ic2]=find(x(count)<=xres(:,2));
   [ir3,ic3]=find(x(count+1)>=xres(:,1));
   [ir4,ic4]=find(x(count+1)<=xres(:,2));
   index=intersect(intersect(ir1,ir2),intersect(ir3,ir4));
   r(count)=min(xres(index,3));
end

%create the grid
xs=[];
for count=1:length(x)-1
   xs=[xs linspace(x(count),x(count+1),ceil((x(count+1)-x(count))/r(count))+1)];
end
xs=unique(xs);

%for 2D simulation create also node in y-direction, analog x-direction
if aquila_control.mode==2
   y=[aquila_structure.mbox(:,2);aquila_structure.mbox(:,4)];
   yres=[aquila_structure.mbox(:,2) aquila_structure.mbox(:,4) aquila_structure.mbox(:,6)];
   if ~isempty(aquila_structure.qbox)
      y=[y;aquila_structure.qbox(:,2);aquila_structure.qbox(:,4)];
      yres=[yres;aquila_structure.qbox(:,2) aquila_structure.qbox(:,4) aquila_structure.qbox(:,6)];
   end
   if ~isempty(aquila_structure.bias)
      y=[y;aquila_structure.bias(:,2);aquila_structure.bias(:,4)];
      yres=[yres;aquila_structure.bias(:,2) aquila_structure.bias(:,4) abs(aquila_structure.bias(:,2)-aquila_structure.bias(:,4))];
   end
   
   y=sort(unique(y));
   r=zeros(size(y));
   for count=1:length(y)-1
      [ir1,ic1]=find(y(count)>=yres(:,1));
      [ir2,ic2]=find(y(count)<=yres(:,2));
      [ir3,ic3]=find(y(count+1)>=yres(:,1));
      [ir4,ic4]=find(y(count+1)<=yres(:,2));
      index=intersect(intersect(ir1,ir2),intersect(ir3,ir4));
      r(count)=min(yres(index,3));
   end
   ys=[];
   for count=1:length(y)-1
      ys=[ys linspace(y(count),y(count+1),ceil((y(count+1)-y(count))/r(count))+1)];
   end
   ys=unique(ys);
else
   ys=0;
end

%check the requested type of the grid
switch tp
case 'nodes' %the nodes themself
   g=zeros(length(ys),length(xs));
case {'x','dop'} %grid between the nodes
   g=-2*ones(length(ys)-1,length(xs)-1); %predefine grid
   n=size(aquila_structure.mbox);
   for count=1:n(1) %insert material property into grid
      [i1,i2]=boxindex(xs,ys,aquila_structure.mbox(count,1:4));
      switch tp
      case 'x' %the x-content
         g(i2,i1)=aquila_structure.mbox(count,7);
      case 'dop' %or the doping
         g(i2,i1)=aquila_structure.mbox(count,8);
      end
   end
   i1=find(g==-2); %check for unassigned grid nodes
   if ~isempty(i1)
      disp('makegrid: there are unassigned nodes in the material properties');
   end
end
