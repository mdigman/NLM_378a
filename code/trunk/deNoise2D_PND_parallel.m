function [p] = deNoise2D_PND_parallel(nhoods,eig_val)
%
% function [p] = deNoise2D_PND_parallel(nhoods,eig_val)
%
% This function performs the "parallel" analysis to determine the number of
% Principal Components to use in PND.
%
% Input(s):
%   nhoods  -- M-by-N matrix containing M-pixel neighborhoods around N pixels
%   eig_val -- matrix of eigenvalues of PCA (in ascending order from 1,1)
% Output(s):
%   p       -- Number of Principal Components to use; argmax eig_val(p) >= beta(p)
%

% Initialize -- M = number of pixels in neighborhood; N = number of nhoods;
[M,N] = size(nhoods);

% Compute mean for each neighborhood
mu = 1/M.*sum(nhoods,1);

% Subtract neighborhood mean from each pixel in neighborhood
mu = repmat(mu,M,1);
nhoods_prime = nhoods - mu;

% Create Artificial Data Set
w = zeros(M,N);
for i = 1:M
    % Generate a random permutation of numbers from 1 to N
    indices = randperm(N);
    for j = 1:N
        w(i,j) = nhoods_prime(i,indices(j));
    end
end

% Perform PCA on w
[eig_vec_w,eig_val_w] = deNoise2D_PND_PCA(w);

% Compute first index where eig_val(p) < beta(p)
eig_val = sum(eig_val,2);
eig_val_w = sum(eig_val_w,2);
ind = find(eig_val >= eig_val_w,1,'first');

p = M-ind+1;