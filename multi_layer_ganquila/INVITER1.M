function [ev,evec]=inviter1(A,lambda,v);

%INVITER1 track eigenvalues in 1D
%
%[ev,evec]=inviter1(A,lambda,v)
%
%refine/track eigenvalues/vectors by inverse vectoriteration in 1D.
%The given approximations must be close enough to the real eigenvalues.
%
%ev,evec = refined eigenvalues and vectors
%A = corresponding matrix (diagonals only in the columns)
%lambda = vector of eigenvalues to refine
%v = matrix, in the columns the corresponding eigenvectors
%
%Note: the behavior can be controlled by the global variables
%   'aquila_control.inviter1.maxiter' and 'aquila_control.inviter1.tol', defined in INITAQUILA

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

global aquila_control

%tell the user, what is happening
if aquila_control.verbose>0
   disp('inviter1: tracking 1D eigenvalues')
end

n=length(A(:,1));
%for all eigenvalues
for i_count=1:length(lambda)
   iter=0; %iteration counter
   rho=aquila_control.inviter1.tol+1;
   z=v(:,i_count); %the eigenvector to be corrected
   while (iter<aquila_control.inviter1.maxiter)&(rho>aquila_control.inviter1.tol)
      %form the matrix, subtract the eigenvalue on the diagonal
      H=spdiags([A(:,2) A(:,1)-lambda(i_count) [0;A(1:end-1,2)]],[-1 0 1],n,n);
      z=H\v(:,i_count); %solve the system
      rho=(z'*v(:,i_count))./(z'*z); %correction for the eigenvalue
      lambda(i_count)=lambda(i_count)+rho;
      v(:,i_count)=z; %the new eigenvector
      iter=iter+1;
      if aquila_control.verbose>1 %some output
         os=sprintf('EVNR %d, It %d, Err %g, EV %g',i_count,iter,rho,lambda(i_count));
         disp(os)
      end
   end   
end
%in case something went wrong
if iter>=aquila_control.inviter1.maxiter
   disp('inviter1: iteration reached inviter1.maxiter!');
end
if rho>=aquila_control.inviter1.tol
   disp('inviter1: iteration did not converge to desired tolerance');
end

ev=lambda;
evec=v;
