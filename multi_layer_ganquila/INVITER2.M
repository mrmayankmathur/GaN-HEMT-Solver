function [ev,evec]=inviter2(A,nx,lambda,v);

%INVITER2 track eigenvalues in 2D
%
%[ev,evec]=inviter2(A,nx,lambda,v)
%
%refine/track eigenvalues/vectors by inverse vectoriteration in 2D.
%The given approximations must be close enough to the real eigenvalues.
%
%ev,evec = refined eigenvalues and vectors
%A = corresponding matrix (diagonals only)
%nx = is the position of the second superdiagonal given in the third
%     column of A
%lambda = vector of eigenvalues to refine
%v = matrix, in the columns the corresponding eigenvectors
%
%Note: the behavior can be controlled by the global variables
%   'aquila_control.inviter2.maxiter' and 'aquila_control.inviter2.tol', defined in INITAQUILA

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

%some output first
if aquila_control.verbose>0
   disp('inviter2: tracking 2D eigenvalues')
end

n=size(A(:,1));
%for all eigenvalues
for i_count=1:length(lambda)
   iter=0; %iteration counter
   rho=inviter2_tol+1;
   z=v(:,i_count); %the eigenvector to be corrected
   while (iter<aquila_control.inviter2.maxiter)&(rho>aquila_control.inviter2.tol)
      %form the matrix, subtract the eigenvalue from the diagonal
      H=spdiags([A(:,3) A(:,2) A(:,1)-lambda(i_count) [0;A(1:end-1,2)] [zeros(nx,1);A(1:end-nx,2)]],[-nx -1 0 1 nx],n,n);
      z=H\v(:,i_count); %solve the system
      rho=(z'*v(:,i_count))./(z'*z); %the correction for the eigenvalue
      lambda(i_count)=lambda(i_count)+rho;
      v(:,i_count)=z; %the new eigenvector
      iter=iter+1;
      if aquila_control.verbose>1
         os=sprintf('EVNR %d, It %d, Err %g, EV %g',i_count,iter,rho,lambda(i_count));
         disp(os)
      end
   end   
end
%in case something went wrong
if iter>=aquila_control.inviter2.maxiter
   disp('inviter2: iteration reached inviter1_maxiter!');
end
if rho>=aquila_control.inviter2.tol
   disp('inviter2: iteration did not converge to desired tolerance');
end
ev=lambda;
evec=v;
