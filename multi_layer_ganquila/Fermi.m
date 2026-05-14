function ret=fermi(order,x);

%FERMI complete Fermi integrals
%
%y=FERMI(order,x)
%
%these function computes the values of the complete Fermi-Dirac integrals
%of the order -3/2, -1/2, 1/2 and 3/2
%at the values defined in the vector/matrix x
%
%Reference:
%Aymerich,Humet, solid state electron. 24, 981 (1981)
%S. Hackenbuchner, Diploma thesis, WSI (1999)

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

global fermi_3_save

%precompute some points of FD-Integral order -3/2 by numerically differentiating
%FD-Integral order -1/2. We do this only once and save the result in a global
%array for later use.
if isempty(fermi_3_save)
   fermi_3_save=1; %avoid infinite recursion
   df=diff(fermi(-1/2,[-10:0.01:10]))/0.01;
   fermi_3_save=[df(1) (df(1:end-1)+df(2:end))/2 df(end)];
end

%which order do we need?
%use one of several interpolation schemes or approximations dependent on the order and x
switch order*2
   case 3,
      t=(2.5* 2.^2.5 *gamma(3.5))./((x+2.64+(abs(x-2.64).^2.25+14.9).^(1/2.25)).^2.5);
      ret=1./(exp(-x)+t);
   case 1,
      t=(1.5* 2.^1.5 *gamma(2.5))./((x+2.13+(abs(x-2.13).^2.4+9.6).^(1/2.4)).^1.5);
      ret=1./(exp(-x)+t);
   case -1,
      a=[1 -0.707107 0.577346 -0.499848 0.4445297 -0.381935 0.238611];
      b=[0.6048983 0.380116 5.924798e-2 -1.432051e-2 -4.55487e-3 1.636784e-3 1.377651e-4 -1.183038e-4 1.391864e-5];
      c=[0.4162655 0.7898693 -0.3246935 0.1893185 -7.263595e-2 1.707887e-2 -2.418336e-3 1.906250e-4 -6.451653e-6];
      d=[1.1283792 -0.4644314 -1.5891441 -121.5185 3262.095 -5256.636 -329073.72];
      a_=[0.9999729 -0.7061996 0.5674493 -0.4484073 0.2957803 -0.1309140 2.721918e-2];
      ret=zeros(size(x));
      ix=find(x<-2);
      re=zeros(size(ix));
      for r=1:7
         re=re+a(r)*exp(r*x(ix));
      end
      ret(ix)=re;
      ix=find((x>=-2)&(x<0));
      re=zeros(size(ix));
      for r=1:7
         re=re+a_(r)*exp(r*x(ix));
      end
      ret(ix)=re;
      ix=find((x>=0)&(x<2.5));
      re=zeros(size(ix));
      for r=1:9
         re=re+b(r)*(x(ix).^(r-1));
      end
      ret(ix)=re;
      ix=find((x>=2.5)&(x<5));
      re=zeros(size(ix));
      for r=1:9
         re=re+c(r)*(x(ix).^(r-1));
      end
      ret(ix)=re;
      ix=find(x>=5);
      re=zeros(size(ix));
      for r=1:7
         re=re+d(r)*(x(ix).^(2-2*r));
      end
      ret(ix)=(x(ix).^0.5).*re;
   case -3,
      ret=zeros(size(x));
      ix=find(x<-10);
      ret(ix)=exp(x(ix));
      ix=find(x>10);
      ret(ix)=1./sqrt(pi*x(ix));
      ix=find((x>=-10)&(x<=10));
      ret(ix)=interp1([-10:0.01:10],fermi_3_save,x(ix),'nearest');
   otherwise,      
      disp('fermi: this order is not implemented!');
   end
   


