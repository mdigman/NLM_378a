function [eig_vec,eig_val] = deNoise2D_PND_PCA(nhoods)
%
% function [eig_vec,eig_val] = deNoise2D_PND_PCA(nhoods)
%
% This function performs Principal Component Analysis on the matrix nhoods
%
% Input(s):
%   nhoods  -- M-by-N matrix containing M-pixel neighborhoods around N pixels
% Output(s):
%   eig_vec -- M-by-M matrix of eigenvectors of covariance matrix
%   eig_val -- M-by-M matrix of eigenvalues (in ascending order from 1,1)
%

% Initialize -- M = number of pixels in neighborhood; N = number of nhoods;
[M,N] = size(nhoods);

% Compute y_bar
y_bar = 1/N.*sum(nhoods,2);

% Compute Covariance Matrix
C = zeros(M);
for i = 1:N
    C = C + (nhoods(:,i)-y_bar)*(nhoods(:,i)-y_bar)';
end
C = 1/N.*C;

% Compute Eigenvectors/Eigenvalues
[eig_vec,eig_val] = eig(C);