function y = OTFS_demodulation(N, M, r)
    r_mat = reshape(r, M, N);
    Y = fft(r_mat) / sqrt(M);
    Y = Y.';
    y = ifft(fft(Y).').'/sqrt(N/M);
end