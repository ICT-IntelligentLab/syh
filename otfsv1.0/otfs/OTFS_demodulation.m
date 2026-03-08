function y = OTFS_demodulation(N,M,r)
%% OTFS demodulation: 1. Wiegner transform, 2. SFFT
r_mat = reshape(r,M,N); %重新生成8*8的接收符号
Y = fft(r_mat)/sqrt(M); % Wigner transform
Y = Y.';
y = ifft(fft(Y).').'/sqrt(N/M); % SFFT
end