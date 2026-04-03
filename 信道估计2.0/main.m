clc;
clear;
close all;
tic;

%% =========================
% 主程序参数
%% =========================
N = 23;                  % DD域矩阵行数（Doppler）
M = 50;                  % DD域矩阵列数（Delay）

max_delay_tap = 4;       % delay tap范围: [0,4]
max_doppler_tap = 4;     % doppler tap范围: [-4,4]
max_taps = 4;            % 最大路径数
max_num = 4;
taps_random = 'False';   % 是否随机路径数

M_mod = 4;               % QPSK

N1 = 9;                  % 9导频
u = 5;                   % 与N1互素
n = (0:N1-1).';
polit = exp(-1j*pi*u*n.*(n+1)/N1) * 5;   % 9个导频复数序列

num_frames = 80;          % 仿真帧数

SNR_dB = 0:5:20;             
SNR = 10.^(SNR_dB/10);

%% 数据区与导频区
data_row_range = 3:21;
data_col_range = 24:48;

Pilot_row_index = [6,6,6,12,12,12,18,18,18];
Pilot_col_index = [6,12,18,6,12,18,6,12,18];

data_row_num = length(data_row_range);
data_col_num = length(data_col_range);

N_syms_perfram = data_row_num * data_col_num;
err_bits_sum = zeros(length(SNR),1);
nmse_sum = zeros(length(SNR),1);
match_count_sum = zeros(length(SNR),1);
%% 估计器参数
threshold_score = 0.35;   % score_map阈值

local_win_k = 0;         % 局部峰窗口半径（doppler方向）
local_win_l = 0;         % 局部峰窗口半径（delay方向）
min_sep_k = 0;           % 峰值去重最小间隔（doppler方向）
min_sep_l = 0;           % 峰值去重最小间隔（delay方向）
% zeroTapDiffTh = 100;     % 0 tap 特判阈值（score_map现在量级接近0~1）

%% 用于保存首帧图像
score_map_first = [];
k_list_first = [];
l_list_first = [];
y_first = [];
x_first = [];
true_delay_first = [];
true_dopp_first = [];
true_coef_first = [];
est_delay_first = [];
est_dopp_first = [];
est_coef_first = [];

for t = 1:length(SNR)
    err_bits = 0;

    for frame_idx = 1:num_frames

        %% =========================
        % 1) 生成发送数据并填充DD域
        %% =========================
        data_bit = randi([0,1], N_syms_perfram*log2(M_mod), 1);

        x_temp = qammod(data_bit, M_mod, 'gray', 'InputType', 'bit');
        x_temp = reshape(x_temp, data_row_num, data_col_num);

        x = zeros(N, M);

        for i = 1:N1
            x(Pilot_row_index(i), Pilot_col_index(i)) = polit(i);
        end

        x(data_row_range, data_col_range) = x_temp;

        %% =========================
        % 2) OTFS调制
        %% =========================
        s = OTFS_modulation(N, M, x);

        noiseVar = mean(abs(s).^2) / SNR(t);

        %% =========================
        % 3) OTFS信道
        %% =========================
        [taps, delay_taps, Doppler_taps, chan_coef] = ...
            OTFS_channel_gen(max_delay_tap, max_doppler_tap, max_taps, taps_random);

        r = OTFS_channel_output(N, M, taps, delay_taps, Doppler_taps, chan_coef, noiseVar, s);

        %% =========================
        % 4) OTFS解调
        %% =========================
        y = OTFS_demodulation(N, M, r);

        %% =========================
        % 5) 9导频信道估计
[est_delay_tap, est_doppler_tap, est_chan_coef, score_map, k_list, l_list] = ...
    OTFS_channel_est_pilot_9_real( ...
        y, ...
        Pilot_row_index, Pilot_col_index, polit, ...
        max_delay_tap, max_doppler_tap, max_num, ...
        threshold_score, ...
        local_win_k, local_win_l, ...
        min_sep_k, min_sep_l);
%% ===== 自动配对真实路径与估计路径，并计算本帧NMSE =====
true_pairs = [delay_taps(:), Doppler_taps(:)];
est_pairs  = [est_delay_tap(:), est_doppler_tap(:)];

true_coef_col = chan_coef(:);
est_coef_col  = est_chan_coef(:);

frame_nmse_num = 0;
frame_nmse_den = 0;
frame_match_cnt = 0;

used_est = false(length(est_coef_col),1);

for ii = 1:size(true_pairs,1)
    d_true = true_pairs(ii,1);
    k_true = true_pairs(ii,2);

    match_idx = [];
    for jj = 1:size(est_pairs,1)
        if ~used_est(jj) && est_pairs(jj,1) == d_true && est_pairs(jj,2) == k_true
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

nmse_sum(t) = nmse_sum(t) + frame_nmse;
match_count_sum(t) = match_count_sum(t) + frame_match_cnt;
        % 如果一个峰都没检测到，给一个保底处理：取score_map最强峰
        if isempty(est_delay_tap)
            warning('本帧未检测到任何路径，启用保底策略：取score_map最强峰。');

            [~, idx_max] = max(score_map(:));
            [ik_max, il_max] = ind2sub(size(score_map), idx_max);

            est_doppler_tap = k_list(ik_max);
            est_delay_tap = l_list(il_max);

            rx_tmp = zeros(N1,1);
            for ii = 1:N1
                rr = Pilot_row_index(ii) + est_doppler_tap;
                cc = Pilot_col_index(ii) + est_delay_tap;
                if rr >= 1 && rr <= N && cc >= 1 && cc <= M
                    rx_tmp(ii) = y(rr,cc);
                end
            end
            est_chan_coef = (polit' * rx_tmp) / sum(abs(polit).^2);
        end

        %% =========================
        % 6) MP检测
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

        %% 保存首帧结果用于显示
        if t == 1 && frame_idx == 1
            score_map_first = score_map;
            k_list_first = k_list;
            l_list_first = l_list;
            y_first = y;
            x_first = x;
            true_delay_first = delay_taps;
            true_dopp_first = Doppler_taps;
            true_coef_first = chan_coef;
            est_delay_first = est_delay_tap;
            est_dopp_first = est_doppler_tap;
            est_coef_first = est_chan_coef;
        end
    end

    err_bits_sum(t) = err_bits / (N_syms_perfram * num_frames * log2(M_mod));
    nmse_sum(t) = nmse_sum(t) / num_frames;
    match_count_sum(t) = match_count_sum(t) / num_frames;
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

%% =========================
% 绘图
%% =========================
figure;
semilogy(SNR_dB, err_bits_sum, '-o', 'LineWidth', 1.5, 'MarkerSize', 8);
grid on;
title('BER vs. SNR');
xlabel('SNR');
ylabel('Bit Error Rate');
legend('OTFS');

figure;
subplot(1,3,1);
imagesc(abs(x_first));
colorbar;
title('|X_{DD}|');
xlabel('Delay index');
ylabel('Doppler index');
axis xy;

subplot(1,3,2);
imagesc(abs(y_first));
colorbar;
title('|Y_{DD}|');
xlabel('Delay index');
ylabel('Doppler index');
axis xy;

subplot(1,3,3);
imagesc(l_list_first, k_list_first, score_map_first);
colorbar;
hold on;
plot(est_delay_first, est_dopp_first, 'ro', 'LineWidth', 1.5, 'MarkerSize', 10);
title('score\_map + detected peaks');
xlabel('Delay tap');
ylabel('Doppler tap');
axis xy;

toc;