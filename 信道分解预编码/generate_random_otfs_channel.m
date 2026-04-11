function [delay_taps, doppler_taps, chan_coef] = ...
    generate_random_otfs_channel(num_paths, max_delay_tap, max_doppler_tap, path_power_profile)

    if nargin < 4 || isempty(path_power_profile)
        path_power_profile = ones(num_paths,1) / num_paths;
    end

    path_power_profile = path_power_profile(:);
    path_power_profile = path_power_profile / sum(path_power_profile);

    pair_list = [];

    while size(pair_list,1) < num_paths
        l = randi([0, max_delay_tap]);
        k = randi([-max_doppler_tap, max_doppler_tap]);

        candidate = [l, k];

        if isempty(pair_list)
            pair_list = candidate;
        else
            if ~ismember(candidate, pair_list, 'rows')
                pair_list = [pair_list; candidate];
            end
        end
    end

    delay_taps   = pair_list(:,1).';
    doppler_taps = pair_list(:,2).';

    chan_coef = sqrt(path_power_profile/2) .* ...
        (randn(num_paths,1) + 1j*randn(num_paths,1));
end