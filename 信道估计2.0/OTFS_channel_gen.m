function [taps, delay_taps, Doppler_taps, chan_coef] = ...
    OTFS_channel_gen(max_delay_tap, max_doppler_tap, max_taps, taps_random)

    if strcmpi(taps_random, 'True')
        taps = randi([1 max_taps]);
    else
        taps = max_taps;
    end

    low_doppler = -max_doppler_tap;
    up_doppler = max_doppler_tap;
    low_delay = 0;
    up_delay = max_delay_tap;

    flag = 1;
    while flag == 1
        Doppler_taps = randi([low_doppler, up_doppler], 1, taps);
        delay_taps   = randi([low_delay, up_delay], 1, taps);

        pairs = [Doppler_taps(:), delay_taps(:)];
        [~, ia, ~] = unique(pairs, 'rows');

        if length(ia) == taps
            flag = 0;
        end
    end

    pow_prof = (1/taps) * ones(1, taps);
    chan_coef = sqrt(pow_prof) .* ...
        (sqrt(1/2) * (randn(1,taps) + 1i*randn(1,taps)));
end