function [H, pathPars] = channel_generate(M, N, numPaths, kmax, lmax)

MN = M * N;

%% --------------------- Base Matrices ----------------------
Pi = circshift(eye(MN), 1, 2);

n = (0:MN-1).';
omega = exp(1j * 2*pi / MN);
Delta = diag(omega .^ n);

%% --------------------- Random Paths -----------------------
h = (randn(numPaths,1) + 1j*randn(numPaths,1)) / sqrt(2*numPaths);

% delay tap
l = randi([0, lmax], numPaths, 1);

% Doppler tap
k = randi([-kmax, kmax], numPaths, 1);

%% --------------------- Build Channel ----------------------
H = zeros(MN, MN);

for p = 1:numPaths
    Pi_l = Pi^l(p);
    Delta_k = Delta^k(p);

    H = H + h(p) * Pi_l * Delta_k;
end

%% --------------------- Save Parameters --------------------
pathPars = table((1:numPaths).', h, l, k, ...
    'VariableNames', {'PathIndex','Gain','DelayTap','DopplerTap'});

end