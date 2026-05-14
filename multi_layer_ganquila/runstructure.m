function runstructure

%RUNSTRUCTURE performs computation
%
%runstructure
%
%performs the self-consistent solution of Schroedinger and Poisson equation
%for the previously defined structure. If no PBOX is defined, no output
%during the  computation is generated. The result of this procedure are the
%global variables 'phi' and 'aquila_subbands' that contain the computed electrical
%potential and the wave functions and energies of the electrons in the quantum
%regions. See file 'structures' for a desription of aquila_subbands.

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

global phi aquila_control aquila_structure poimatrix

%tell the user, who we are
disp('AQUILA 1.0');
disp('(c) 1999 Martin Rother');

%we have to generate the structure first
buildstructure;

%get the size of the problem
nx=length(aquila_structure.xpos);
ny=length(aquila_structure.ypos);
n=nx*ny;

%generate the Poisson matrix. It does not change during the program run, so
%generate it only once. It is stored in the global variable 'poimatrix'.
genmatrixpoi
   
%redefine Fermi level in midgap of GaAs
%this is necessary, because the user may have changed the temperature
%after calling 'initaquila', where 'Efermi' has been computed before
aquila_control.Efermi=gaasmaterial(0,'E_c')-0.5*gaasmaterial(0,'E_G6G8');


%check, whether the given startpotential has correct size
%the potential 'phi' is already a all-zero matrix of correct size, generated in
%'buildstructure', which is used to start the iteration if no startpotential was given
if exist('aquila_control.phistart')
   if size(aquila_control.phistart)==size(phi) %size is OK
      phi=aquila_control.phistart; %set it as the startpotential
      if ~isempty(aquila_structure.qbox) %if we have QBOXes, enable the Schroedinger solver
         aquila_control.progress_check=bitset(aquila_control.progress_check,7);
      end
   else %size is wrong
      disp('runstructure: external startpotential has wrong size, using default all zero potential');
   end
end

%give some output, that the main thing is starting now
if aquila_control.verbose>0
   disp('runstructure: self-consistent classical Poisson solution')               
end

%if no QBOXes are defined then redefine values for stopping the iteration
if isempty(aquila_structure.qbox) 
   aquila_control.poisson.phitol=aquila_control.phitol;
   aquila_control.poisson.ftol=0.1*aquila_control.phitol;
   aquila_control.poisson.maxiter=aquila_control.maxiter;
end

%now we call the main solver
%The idea is: If we have no user-defined start potential, then use classical
%(non-linear Poisson equation) first. If the iteration has converged enough,
%then additionally incorporate the Schroedinger equation via a predictor-
%corrector scheme. If the user has given a startpotential, we expect it to
%be good enough the start the Schroedinger-Poisson solution immediately
%via the predictor-corrector scheme.
if ~exist('aquila_control.phistart') %we have no user-defined startpotential
   %some output
   if (aquila_control.verbose>1)|(~isempty(aquila_structure.pbox))
      os=sprintf('Classical computation');
      disp(os)
   end
   newton(1,[]); %perform classical computation first
else
   schrsolve(phi,0); %solve Schroedingers equation for the user-defined startpotential
   %some output
   if (aquila_control.verbose>1)|(~isempty(aquila_structure.pbox))
      os=sprintf('Schroedinger step 0');
      disp(os)
   end
   newton(0,phi); %perform Newton scheme. Same as classical computation, but already with
                  %quantum mechanical charge density
end
%if we do classical computation only, we are finished now

%otherwise we have a good potential now and are ready to switch on the Schroedinger solver
%if it has not already been switched on.
%This of course makes sense only, when QBOXes are defined
if ~isempty(aquila_structure.qbox)
   %tell the user, what we are doing
   if aquila_control.verbose>0
      disp('runstructure: starting self-consistent quantum Poisson solution')               
   end
   
   %prepare the predictor-corrector scheme
   
   phi_old=phi; %save the potential
   schrsolve(phi,0); %compute eigenvalues
   %tell the user
   if (aquila_control.verbose>1)|(~isempty(aquila_structure.pbox))
      os=sprintf('Schroedinger step %d',1);
      disp(os)
   end
   %set flag, indicating that we now have eigenvalues
   aquila_control.progress_check=bitset(aquila_control.progress_check,7); 
   newton(0,phi_old); %make some modified Newton steps with predictor charge density
   %we now have a new potential in 'phi'
   rho=max(max(abs(phi-phi_old))); %maximum change in potential
   
   %stop, if the iteration has converged enough
   %this happens at this early stage in the computation, if there is no charge in the
   %structure. The self-consistency is already reched at this point.
   if rho<aquila_control.phitol
      if aquila_control.verbose>1
         disp('runstructure: convergence reached by phitol');
      end
      return
   end

   %now comes the outer loop of the predictor-corrector scheme
   itr=1; %reset the iteration counter
   while itr<aquila_control.maxiter %too many iterations ?
      itr=itr+1;
      phi_old=phi;
      
      %now compute new eigenvalues
      %if the change in the potential is small, then use inverse vectoriteration
      %otherwise use MATLABs 'eigs' (Arnoldi algorithm ?)
      if rho>aquila_control.tracklimit
         schrsolve(phi,0);
      else
         schrsolve(phi,1);
      end
      %some output
      if (aquila_control.verbose>1)|(~isempty(aquila_structure.pbox))
         os=sprintf('Schroedinger step %d',itr);
         disp(os)
      end
      
      %we now have new eigenvalues (corrector step)
      %now lets do a few Newton steps with them (predictor step)
      newton(0,phi);
      
      %the maximum change in the potential
      rho=max(max(abs(phi-phi_old)));
            
      %stop, if the iteration has converged enough
      if rho<aquila_control.phitol
         if aquila_control.verbose>1
            disp('runstructure: convergence reached by phitol');
         end
         return
      end
   end
   
   %stop, we have no convergence
   disp('runstructure: no convergence reached at maxiter!');
end
return

%************************************
%some subroutines doing the main work
%************************************

function newton(qstop,phi_last)

%perform modified Newtons method
%in this iteration the error of non-linear Poissons equation is
%minimized. We do not directly minimize the error but the error squared
%thus giving global convergence.
%
%qstop is a flag. qstop=1 means, stop the iteration when the change in the
%potential becomes small enough to activate the Schroedinger solver
%
%phi_last is the potential from the last iteration. This is the potential
%for which the eigenvalues have been computed and is needed here to
%approximate the eigenvalues of the new potential during the iteration
%without a complete recomputation of the spectrum.
%
%the result of this routine is a new electric potential which
%is returned in the global variable phi

global phi aquila_control aquila_structure poimatrix

nx=length(aquila_structure.xpos);
ny=length(aquila_structure.ypos);
n=nx*ny;

%make the matrix of the nodes of the electric potential a vector

phi=phi';
phi=phi(:);
dphi=aquila_control.schrenable;

%compute the error of Poissons equation for potential phi
%fvec is the error vector itself, rho is 0.5*fvec'*fvec
%phi_last is the potential for wich the eigenvalues have been computed
%and is needed here to find an approximation of the eigenvalues of the
%actual potential phi
[rho,fvec]=fmin(phi,phi_last);
      
%reset the iteration counter and a flag
check=0;
itr=0;

stpmax=100*max(norm(phi),length(phi));   
%the iteration loop
while itr<aquila_control.poisson.maxiter %limit the number of iterations
   itr=itr+1;

   phix=reshape(phi,nx,ny)'; %store the potential in matrix form
   
   %display the progress of the iteration for the user
   if itr>1
      showprogress(phix,dphi,itr-1);
   end   
   
   %return if limit for Schrodinger solver is reached
   if (dphi<aquila_control.schrenable)&(bitget(aquila_control.progress_check,7)==0)&...
         (~isempty(aquila_structure.qbox))&(qstop==1)
      if aquila_control.verbose>1
         disp('runstructure: returning for Schroedinger solution');
      end
      phi=phix; %make phi a matrix again
      return
   end
   
   %compute derivative of the square of the error of the Poisson equation
   dF=poimatrix;
   
   %compute the derivative of the charge
   if bitget(aquila_control.progress_check,7)>0 %if already have wavefunctions
      ch=sumcharge(phix,phix-phi_last,1);%derivative of quantum charge
   else
      ch=sumcharge(phix,1);%derivative of charge
   end
   %generate the right hand side of Poissons equation and subtract it from the main diagonal
   dF=spdiags(spdiags(poimatrix,0)-genrhspoi(ch,1),0,dF);
   
   gradf=fvec'*dF; %the gradient
   
   deltaphi=-dF\fvec; %solve the system and compute the correction vector
         
   phiold=phi; %save phi
   %we adapt the length of the correction vector for the potential
   %by a line minimalization algorithm to emsure, that the error of
   %Poissons equation decreases.
   %The algorithm returns the new potential, the square of the error, the errorvector
   %and a flag
   if rho~=0
      [phi,rho,fvec,check]=linesearch(phi,rho,gradf,deltaphi,stpmax,phi_last);
   end
   
   %stop, if the error of Poissons equation has dropped below the desired limit
   if (max(abs(fvec))<aquila_control.poisson.ftol)&(itr>1)
      phi=reshape(phi,nx,ny)'; %make the potential a matrix again
      if aquila_control.verbose>1
         disp('runstructure: convergence reached by poisson.ftol');
      end
      return
   end
   
   %the flag is set. This means, that the algorithm has been trapped in a
   %local minimum and will not converge further. If this happens during the
   %predictor-corrector loop, then after the return from 'newton' new eigenvalues
   %are computed which normally cures the problem.
   if check==1
      temp=max(abs(gradf)'.*max(abs(phi),ones(size(phi)) ))/max(rho,0.5*n);
      if temp<1e-6
         check=1;
      else
         check=0;
      end
      phi=reshape(phi,nx,ny)';
      disp('runstructure: local minimum reached, no further progress!')
      return
   end
   
   %stop, if the change in the potential has dropped below the desired limit
   if (max(abs(phi-phiold)./max(abs(phi),ones(size(phi))))<aquila_control.poisson.phitol)&(itr>1)
      phi=reshape(phi,nx,ny)';
      if aquila_control.verbose>1
         disp('runstructure: convergence reached by poisson.phitol');
      end
      return
   end
   
   dphi=max(abs(phi-phiold));%save the change in the potential
   
   %again some output for the user
   if aquila_control.verbose>1
      os=sprintf('Poisson-Iteration %d, errf=%g, deltaphimax=%g',itr,rho,dphi);
      disp(os)
   end
end
%if we get here, we have not reached convergence
disp('runstructure: no convergence reached at poisson.maxiter!');
phi=reshape(phi,nx,ny)';
return

%***********************************
% here follow some helper routines
%***********************************

function showprogress(phix,dphi,itr)

%show progress information on screen

global aquila_structure aquila_control aquila_material
constants
sp=size(aquila_structure.pbox);
sp=sp(1);
%if we have output at all
if sp>0
   %textual output
   os=sprintf('Newton step %d: max(deltaphi)=%g eV',itr,dphi);
   disp(os)
   
   %graphical output
   %compute charge density, conduction band and valence band
   ch=sumcharge(phix);
   cb=aquila_material.ec-phix;
   vb=aquila_material.ev-phix;
   %how many plots do we need
   plotnr=length(unique([find(aquila_structure.pbox(:,1)-aquila_structure.pbox(:,3)==0)' ...
         find(aquila_structure.pbox(:,2)-aquila_structure.pbox(:,4)==0)']));
   for count=1:sp %for all PBOXes
      
      %PBOX is a slice in y-direction
      if (aquila_structure.pbox(count,1)==aquila_structure.pbox(count,3))&...
            (aquila_control.mode==2)
         %find positions
         ix=find(aquila_structure.xpos<=aquila_structure.pbox(count,1));
         ix=ix(end);
         iy=intersect(find(aquila_structure.pbox(count,2)<=aquila_structure.ypos),...
            find(aquila_structure.pbox(count,4)>=aquila_structure.ypos));         
         %plot the band diagram
         subplot(2,plotnr,count);
         pl=ones(length(iy),1)*aquila_control.Efermi-aquila_material.bias(iy,ix); %the Fermi energy
         if bitand(aquila_structure.pbox(count,5),CB)>0
            pl=[cb(iy,ix) pl]; %add conduction band to plot if desired
         end
         if bitand(aquila_structure.pbox(count,5),VB)>0
            pl=[pl vb(iy,ix)]; %add valence band to plot if desired
         end         
         plot(aquila_structure.ypos(iy),pl); %draw and label the plot     
         os=sprintf('bands at x=%d A',aquila_structure.pbox(count,1));
         title(os);
         xlabel('y-position [Angstrom]');
         ylabel('energy [eV]');
         %plot the charge density
         subplot(2,plotnr,count+plotnr);
         plot(aquila_structure.ypos(iy),ch(iy,ix)*1e24); %1e24 scales A^-3 to cm^-3
         os=sprintf('charge density at x=%d A',aquila_structure.pbox(count,1));
         title(os);
         xlabel('y-position [Angstrom]');
         ylabel('density [cm^-3]');
         %textual output of charge sheet density along slice
         %get correct width of the slice line
         if ix==1
            width=aquila_structure.hx(1)/2;
         elseif ix==length(aquila_structure.xpos)
            width=aquila_structure.hx(end)/2;
         else
            width=(aquila_structure.hx(ix)+aquila_structure.hx(ix-1))/2;
         end
         %integrate charge along slice line and form sheet density
         %factor 1e16 scales A^-2 to cm^-2
         tcharge=sum(ch(iy,ix).*aquila_structure.boxvol(iy,ix))/width*1e16;
         os=sprintf('%d<=y<=%d A at x=%d A sheet density %g cm^-2',...
            aquila_structure.pbox(count,2),aquila_structure.pbox(count,4),...
            aquila_structure.pbox(count,1),tcharge);
         disp(os);
         
         %PBOX is slice in x-direction or we have 1D simulation only
      elseif (aquila_structure.pbox(count,2)==aquila_structure.pbox(count,4))|...
            (aquila_control.mode==1)
         %find correct y-index and x-index
         if aquila_control.mode==2
            iy=find(aquila_structure.ypos<=aquila_structure.pbox(count,2));
            iy=iy(end);
         else
            iy=1;
         end
         ix=intersect(find(aquila_structure.pbox(count,1)<=aquila_structure.xpos),...
            find(aquila_structure.pbox(count,3)>=aquila_structure.xpos));
         %plot the band diagram
         subplot(2,plotnr,count);
         pl=ones(length(ix),1)*aquila_control.Efermi-aquila_material.bias(iy,ix)'; %Fermi energy
         if bitand(aquila_structure.pbox(count,5),CB)>0
            pl=[cb(iy,ix)' pl]; %add conduction band to plot if desired
         end
         if bitand(aquila_structure.pbox(count,5),VB)>0
            pl=[pl vb(iy,ix)']; %add valence band to plot if desired
         end         
         plot(aquila_structure.xpos(ix),pl); %draw and label the plot
         os=sprintf('bands at y=%d A',aquila_structure.pbox(count,2));
         title(os);
         xlabel('x-position [Angstrom]');
         ylabel('energy [eV]');
         %plot the charge density
         subplot(2,plotnr,count+plotnr);
         plot(aquila_structure.xpos(ix),ch(iy,ix)*1e24); %1e24 scales A^-3 to cm^-3
         if aquila_control.mode==2
            os=sprintf('charge density at y=%d A',aquila_structure.pbox(count,2));
         else
            os='charge density'; %for 1D simulation
         end
         title(os);
         xlabel('x-position [Angstrom]');
         ylabel('density [cm^-3]');
         %textual output of charge sheet density along slice
         %compute correct width
         if iy==1
            if aquila_control.mode==2
               width=aquila_structure.hy(1)/2;
            else
               width=1;
            end
         elseif iy==length(aquila_structure.ypos)
            width=aquila_structure.hy(end)/2;
         else
            width=(aquila_structure.hy(iy)+aquila_structure.hy(iy-1))/2;
         end
         %integrate along slice line
         %1e16 scales A^-2 to cm^-2
         tcharge=sum(ch(iy,ix).*aquila_structure.boxvol(iy,ix))/width*1e16;
         if aquila_control.mode==2
            os=sprintf('%d<=x<=%d A at y=%d A sheet density %g cm^-2',...
               aquila_structure.pbox(count,1),aquila_structure.pbox(count,3),...               
               aquila_structure.pbox(count,2),tcharge);
         else
            os=sprintf('%d<=x<=%d A sheet density %g cm^-2',...
               aquila_structure.pbox(count,1),aquila_structure.pbox(count,3),tcharge);
         end   
         disp(os);
      else
         %textual output only, if PBOX is a real box and not a slice
         ix=intersect(find(aquila_structure.pbox(count,1)<=aquila_structure.xpos),...
            find(aquila_structure.pbox(count,3)>=aquila_structure.xpos));
         iy=intersect(find(aquila_structure.pbox(count,2)<=aquila_structure.ypos),...
            find(aquila_structure.pbox(count,4)>=aquila_structure.ypos));
         %integrate over PBOX, 1e8 scales A^-1 to cm^-1
         tcharge=sum(sum(ch(iy,ix).*aquila_structure.boxvol(iy,ix)))*1e8;
         os=sprintf('%d<=x<=%d A, %d<=y<=%d A line density %g cm^-1',...
            aquila_structure.pbox(count,1),aquila_structure.pbox(count,3),...
            aquila_structure.pbox(count,2),aquila_structure.pbox(count,4),tcharge);
         disp(os);
      end
   end
   drawnow %draw the plot
end

%*****************************

function [phi,rho,fvec,check]=linesearch(phiold,rhoold,gradf,deltaphi,stpmax,phi_last)

%linesearch algorithm for Newtons method
%parts of this routine have been taken from Numerical Recipes

global aquila_control
check=0;
no=norm(deltaphi);
if no>stpmax
   deltaphi=deltaphi*(stpmax/no);
end
slope=gradf*deltaphi;
lambdamin=1e-8./max(abs(deltaphi)./max(abs(phiold),ones(size(phiold))));
lambda=1;
count=0;
while 1
   count=count+1;
   phi=phiold+lambda*deltaphi;%try full Newton step
   [rho,fvec]=fmin(phi,phi_last);
   if lambda<lambdamin
      phi=phiold;
      check=1;
      disp('linesearch: lambdamin reached');
      return
   elseif rho<rhoold+1e-4*lambda*slope %1e-4 incoporates average rate of decrease
      if aquila_control.verbose>1
         disp('linesearch: sufficient function decrease');
      end
      return
   else
      if lambda==1 %first iteration
         tmplambda=-slope/(2*(rho-rhoold-slope));%quadratic approximation
      else
         rhs1=rho-rhoold-lambda*slope;
         rhs2=rho2-rhoold2-lambda2*slope;
         a=(rhs1/lambda^2-rhs2/lambda2^2)/(lambda-lambda2);
         b=(-lambda2*rhs1/lambda^2+lambda*rhs2/lambda2^2)/(lambda-lambda2);
         if a==0
            tmplambda=-slope/(2*b);
         else
            tmplambda=(-b+sqrt(b*b-3*a*slope))/(3*lambda);
         end
         if tmplambda>0.5*lambda %no too big iteration steps
            tmplambda=0.5*lambda;
         end
      end
   end
   lambda2=lambda;
   rho2=rho;
   rhoold2=rhoold;
   lambda=max(tmplambda,0.1*lambda); %no too small iteration steps
   if aquila_control.verbose>1
      os=sprintf('It2=%d, err=%g, lambda=%g',count,rho,lambda);
      disp(os)
   end
end

%*****************************

function [ferr,F]=fmin(phi,phi_last)

%compute error in Poisson equation and is square

F=poierr(phi,phi_last);
ferr=0.5*norm(F)^2;

%*****************************

function F=poierr(phi,phi_last)

%compute error in Poisson equation

global aquila_structure aquila_control poimatrix
nx=length(aquila_structure.xpos);
ny=length(aquila_structure.ypos);
n=nx*ny;
phi=reshape(phi,nx,ny)'; %make phi a matrix again
%if we have eigenvalues, use predictor density, otherwise use classical density
if bitget(aquila_control.progress_check,7)>0
   ch=sumcharge(phi,phi-phi_last);
else
   ch=sumcharge(phi);
end
rhs=genrhspoi(ch); %form Poissons equation right hand side
phi=phi';
phi=phi(:);
F=poimatrix*phi-rhs; %the error of Poisson equation
