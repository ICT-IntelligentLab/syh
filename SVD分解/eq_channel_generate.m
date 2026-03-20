function [Heq, FN, A] =eq_channel_generate(H, M, N)

% Heq = (FN \kron IM) * H * (FN' \kron IM)
MN = M * N;

% normalized DFT matrix
FN = dftmtx(N) / sqrt(N);

% identity matrix of size M
IM = eye(M);

% OTFS transform matrix
A = kron(FN, IM);

% equivalent channel
Heq = A * H * A';
end