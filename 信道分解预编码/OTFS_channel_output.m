function r = OTFS_channel_output(N, M, taps, delay_taps, Doppler_taps, chan_coef, noiseVar, s)

    L = max(delay_taps);

    % 加CP
    s = [s(N*M-L+1:N*M); s];

    s_chan = zeros(length(s)+L, 1);

    for itao = 1:taps
        phase_term = exp(1j*2*pi/M * (-L:-L+length(s)-1) * Doppler_taps(itao) / N).';
        s_tmp = s .* phase_term;

        s_pad = [s_tmp; zeros(L,1)];
        s_shift = circshift(s_pad, delay_taps(itao));

        s_chan = s_chan + chan_coef(itao) * s_shift;
    end

    noise = sqrt(noiseVar/2) * (randn(size(s_chan)) + 1i*randn(size(s_chan)));
    r = s_chan + noise;

    % 去CP
    r = r(L+1 : L+N*M);
end