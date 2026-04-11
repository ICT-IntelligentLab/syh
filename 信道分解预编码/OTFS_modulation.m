function s = OTFS_modulation(N, M, x)
    X = fft(ifft(x).').' / sqrt(M/N);
    s_mat = ifft(X.') * sqrt(M);
    s = s_mat(:);
end