function [corrsum,permdist,permmap] = sum_sign_permutator(data,permnum)
% Parameters:
% data - vector of values to sum
% permnum - number of permutations
% Output:
% corrsum - sum of unpermuted data
% permdist - permutation sums
% permmap - map of permutations (to reproduce)

% Get real correlation sum
corrsum = sum(data);

permlen = length(data);
permmap = zeros(permlen,permnum);
for p = 1:permnum
    % store the permutation
    tperm = ones(permlen,1);
    iperm = randi([0 1],permlen,1) * -2;
    tperm = tperm + iperm;
    permmap(:,p) = tperm;
    
    % get correlation sum
    permcorr = data.*permmap(:,p);
    permdist(p) = sum(permcorr);
end
