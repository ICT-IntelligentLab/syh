 
function s = OTFS_modulation(N,M,x)
%% OTFS Modulation: 1. ISFFT, 2. Heisenberg transform
X = fft(ifft(x).').'/sqrt(M/N); %%%ISFFT,其中.'表示转置，
s_mat = ifft(X.')*sqrt(M); % Heisenberg transform
s = s_mat(:);%(:)表示将矩阵重构为列向量：
end