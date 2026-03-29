clc
clear
close all
tic

%% OTFS parameters
N = 23;                 % DD域矩阵行数（多普勒）
M = 50;                 % DD域矩阵列数（时延）
max_delay_tap = 4;      % 最大时延，即[0,4]
max_doppler_tap = 4;    % 最大多普勒频移，即[-4,4]
max_taps = 4;           % 最大路径个数
taps_random = 'False';  % 是否随机生成路径数量

% size of constellation
M_mod = 4;              % QPSK

N1 = 9;                 % 9导频
u = 5;                  % 与 N1 互素
n_zc = (0:N1-1).';
polit = exp(-1j*pi*u*n_zc.*(n_zc+1)/N1) * 5;

num_frames = 100;       % 仿真帧数

SNR_dB =0:5:20;            
SNR = 10.^(SNR_dB/10);

% 数据区与导频区
data_row_range = 3:21;
data_col_range = 24:48;

Pilot_row_index = [6,6,6,12,12,12,18,18,18];
Pilot_col_index = [6,12,18,6,12,18,6,12,18];

data_row_num = length(data_row_range);
data_col_num = length(data_col_range);

N_syms_perfram = data_row_num * data_col_num;

err_bits_sum = zeros(length(SNR),1);

% ===== NMSE与匹配路径统计 =====
nmse_sum = zeros(length(SNR),1);
match_count_sum = zeros(length(SNR),1);

% 保存首帧结果
true_delay_first = [];
true_dopp_first = [];
true_coef_first = [];
est_delay_first = [];
est_dopp_first = [];
est_coef_first = [];

for t = 1:length(SNR)
    err_bits = 0;
    nmse_acc = 0;
    match_acc = 0;

    for frame_idx = 1:num_frames

        %% 数据生成填充DD域
        data_bit = randi([0,1], N_syms_perfram*log2(M_mod), 1);

        x_temp = qammod(data_bit, M_mod, 'gray', 'InputType', 'bit');
        x_temp = reshape(x_temp, data_row_num, data_col_num);

        x = zeros(N, M);
        for i = 1:N1
            x(Pilot_row_index(i), Pilot_col_index(i)) = polit(i);
        end
        x(data_row_range, data_col_range) = x_temp;

        %% OTFS_modulation
        s = OTFS_modulation(N, M, x);
        noiseVar = mean(abs(s).^2) / SNR(t);

        %% OTFS_channel
        [taps, delay_taps, Doppler_taps, chan_coef] = ...
            OTFS_channel_gen(max_delay_tap, max_doppler_tap, max_taps, taps_random);

        r = OTFS_channel_output(N, M, taps, delay_taps, Doppler_taps, chan_coef, noiseVar, s);

        %% OTFS_demodulation
        y = OTFS_demodulation(N, M, r);

      
       
        %% 信道估计=========================
        F = [];

        % 第一个数从前11行前11列按行依次取
        for r_idx = 1:11
            for c_idx = 1:11

                pos = [
                    r_idx,    c_idx;
                    r_idx,    c_idx+6;
                    r_idx,    c_idx+12;
                    r_idx+6,  c_idx;
                    r_idx+6,  c_idx+6;
                    r_idx+6,  c_idx+12;
                    r_idx+12, c_idx;
                    r_idx+12, c_idx+6;
                    r_idx+12, c_idx+12
                ];

                vals = zeros(1,9);
                for k = 1:9
                    vals(k) = y(pos(k,1), pos(k,2));
                end

                rx = vals;
                corr = filter(flipud(conj(polit)), 1, rx);
                rx_energy = filter(ones(length(polit),1), 1, abs(rx).^2);
                p_energy = sum(abs(polit).^2);

                metric = abs(corr).^2 ./ (rx_energy * p_energy + eps);
                F = [F, metric];
            end
        end

        [peaks, locs] = findpeaks(F, ...
            'MinPeakHeight', 0.78, ...
            'MinPeakDistance', 1);

        row = [];
        col = [];

        for i = 1:length(locs)
            row(i) = floor((locs(i)/9)/11) + 1;
            col(i) = mod(locs(i)/9, 11);
            if col(i) == 0
                row(i) = row(i) - 1;
            end
        end

        est_delay_tap = [];
        est_doppler_tap = [];
        est_chan_coef = [];

        for i = 1:length(locs)
            est_delay_tap(i) = col(i) - Pilot_col_index(1);
            est_doppler_tap(i) = row(i) - Pilot_row_index(1);
        end

        for i = 1:length(locs)
            r0 = row(i);
            c0 = col(i);
            est_chan_coef(i) = y(r0, c0) / 5;
        end

        est_delay_tap = est_delay_tap(:);
        est_doppler_tap = est_doppler_tap(:);
        est_chan_coef = est_chan_coef(:);

        %% =========================
        %路径匹配 + NMSE
        %% =========================
        true_pairs = [delay_taps(:), Doppler_taps(:)];
        est_pairs  = [est_delay_tap(:), est_doppler_tap(:)];

        true_coef_col = chan_coef(:);
        est_coef_col  = est_chan_coef(:);

        used_est = false(length(est_coef_col),1);

        frame_nmse_num = 0;
        frame_nmse_den = 0;
        frame_match_cnt = 0;

        for ii = 1:size(true_pairs,1)
            d_true = true_pairs(ii,1);
            k_true = true_pairs(ii,2);

            match_idx = [];
            for jj = 1:size(est_pairs,1)
                if ~used_est(jj) && ...
                   est_pairs(jj,1) == d_true && ...
                   est_pairs(jj,2) == k_true
                    match_idx = jj;
                    break;
                end
            end

            frame_nmse_den = frame_nmse_den + abs(true_coef_col(ii))^2;

            if ~isempty(match_idx)
                used_est(match_idx) = true;
                frame_nmse_num = frame_nmse_num + abs(est_coef_col(match_idx) - true_coef_col(ii))^2;
                frame_match_cnt = frame_match_cnt + 1;
            else
                % 没匹配到，按完全丢失处理
                frame_nmse_num = frame_nmse_num + abs(true_coef_col(ii))^2;
            end
        end

        frame_nmse = frame_nmse_num / (frame_nmse_den + eps);

        nmse_acc = nmse_acc + frame_nmse;
        match_acc = match_acc + frame_match_cnt;

        %% =========================
        %mp解调器
        %% =========================
        x_est = OTFS_mp_detector( ...
            N, M, M_mod, ...
            length(est_delay_tap), ...
            est_delay_tap, est_doppler_tap, est_chan_coef, ...
            noiseVar, y);

        x_otemp = x_est(data_row_range, data_col_range);
        x_out = x_otemp(:);

        data_out = qamdemod(x_out, M_mod, 'gray', 'OutputType', 'bit');
        err_bits = err_bits + sum(data_out ~= data_bit);

        %% 保存首帧结果
        if t == 1 && frame_idx == 1
            true_delay_first = delay_taps;
            true_dopp_first = Doppler_taps;
            true_coef_first = chan_coef;
            est_delay_first = est_delay_tap;
            est_dopp_first = est_doppler_tap;
            est_coef_first = est_chan_coef;
        end
    end

    err_bits_sum(t) = err_bits / (N_syms_perfram * num_frames * log2(M_mod));
    nmse_sum(t) = nmse_acc / num_frames;
    match_count_sum(t) = match_acc / num_frames;
end

%% =========================
% 打印结果
%% =========================
disp('BER结果:');
disp(err_bits_sum);

disp('真实 delay taps:');
disp(true_delay_first);

disp('真实 doppler taps:');
disp(true_dopp_first);

disp('真实 channel coef:');
disp(true_coef_first);

disp('估计 delay taps:');
disp(est_delay_first.');

disp('估计 doppler taps:');
disp(est_dopp_first.');

disp('估计 channel coef:');
disp(est_coef_first.');

disp('平均NMSE:');
disp(nmse_sum);

disp('平均每帧成功匹配路径数:');
disp(match_count_sum);

% 额外打印 NMSE(dB)，汇报更直观
nmse_dB = 10*log10(nmse_sum + eps);
disp('平均NMSE(dB):');
disp(nmse_dB);

%% =========================
% 绘制 BER vs. SNR 曲线
%% =========================
figure;
semilogy(SNR_dB, err_bits_sum, '-o', 'LineWidth', 1.5, 'MarkerSize', 8, 'Color', 'b');
title('BER vs. SNR');
xlabel('Eb/\sigma_Z^2 [dB]');
ylabel('Bit Error Rate');
grid on;
legend('OTFS');
hold off;