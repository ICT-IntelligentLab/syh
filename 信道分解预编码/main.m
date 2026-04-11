clc;
clear;
close all;
tic;

rng(1);

%% =========================================================
% 1. 参数设置
%% =========================================================
N = 23;
M = 23;
MN = M * N;

modOrder = 16;
bitsPerSym = log2(modOrder);

snr_dB_list = 0:5:20;
numSNR = length(snr_dB_list);

num_total_frames = 300;      % 总帧数
pilot_period = 10;           % 每10帧一个块：第1帧导频，第2~10帧数据
num_blocks = num_total_frames / pilot_period;

Ns_fixed = 8;                % 固定发送流数

BER_Bob_list = zeros(numSNR, 1);
BER_Eve_list = zeros(numSNR, 1);

%% =========================================================
% 2. 随机信道参数
%% =========================================================
max_delay_tap = 4;
max_doppler_tap = 2;%这个参数以及检测手段受限在2，往上升效果会变差

num_paths_B = 3;
num_paths_E = 3;

path_power_profile_B = ones(num_paths_B,1) / num_paths_B;%每条路径功率平均分配
path_power_profile_E = ones(num_paths_E,1) / num_paths_E;

%% =========================================================
% 3. 9导频参数
%% =========================================================
% 9个导频位置：在 N=8, M=16 的网格里布成 3x3 小阵列
Pilot_row_index = [6 6 6 12 12 12 18 18 18];
Pilot_col_index = [6 12 18 6 12 18 6 12 18];
N1 = length(Pilot_row_index);

% 9导频序列：简单QPSK型复导频
pilot_seq = [ ...
    2+0j;
    0+2j;
   -2+0j;
    0-2j;
    2+0j;
    0+2j;
   -2+0j;
    0-2j;
    2+0j ];

%% =========================================================
% 4. 信道估计参数（适当放宽一点，但仍保持较严）
%% =========================================================
max_search_paths = 3;
threshold_score = 0.25;
local_win_k = 0;
local_win_l = 0;
min_sep_k = 0;
min_sep_l = 0;
rel_amp_th = 0.10;%相对幅度阈值
abs_amp_th = 0.03;%绝对幅度阈值

%% =========================================================
% 5. 预生成固定块信道
%% =========================================================
Bob_channels = cell(num_blocks, 1);
Eve_channels = cell(num_blocks, 1);

for blk = 1:num_blocks
    [delay_taps_B, doppler_taps_B, chan_coef_B] = ...
        generate_random_otfs_channel(num_paths_B, max_delay_tap, max_doppler_tap, path_power_profile_B);

    [delay_taps_E, doppler_taps_E, chan_coef_E] = ...
        generate_random_otfs_channel(num_paths_E, max_delay_tap, max_doppler_tap, path_power_profile_E);

    Bob_channels{blk}.delay_taps = delay_taps_B;
    Bob_channels{blk}.doppler_taps = doppler_taps_B;
    Bob_channels{blk}.chan_coef = chan_coef_B;
    Bob_channels{blk}.taps = length(delay_taps_B);

    Eve_channels{blk}.delay_taps = delay_taps_E;
    Eve_channels{blk}.doppler_taps = doppler_taps_E;
    Eve_channels{blk}.chan_coef = chan_coef_E;
    Eve_channels{blk}.taps = length(delay_taps_E);
end

%% =========================================================
% 6. 星座图缓存
%% =========================================================
mid_idx = ceil(numSNR);   % 最高SNR
d_show = [];
dB_show = [];
zE_show = [];

%% =========================================================
% 7. SNR扫描
%% =========================================================
for iSNR = 1:numSNR

    SNR_dB = snr_dB_list(iSNR);
    snr_linear = 10^(SNR_dB/10);

    fprintf('\n=====================================\n');
    fprintf('Running SNR = %d dB\n', SNR_dB);
    fprintf('=====================================\n');

    errBitBob = 0;
    errBitEve = 0;
    totalBits = 0;

    U_B_hat_s = [];
    V_B_hat_s = [];
    sig_B_hat_s = [];
    Ns = Ns_fixed;

    for blk = 1:num_blocks

        frame_pilot = (blk-1)*pilot_period + 1;

        delay_taps_B   = Bob_channels{blk}.delay_taps;
        doppler_taps_B = Bob_channels{blk}.doppler_taps;
        chan_coef_B    = Bob_channels{blk}.chan_coef;
        taps_B         = Bob_channels{blk}.taps;

        delay_taps_E   = Eve_channels{blk}.delay_taps;
        doppler_taps_E = Eve_channels{blk}.doppler_taps;
        chan_coef_E    = Eve_channels{blk}.chan_coef;
        taps_E         = Eve_channels{blk}.taps;

        fprintf('\n----- Block %d | pilot frame %d -----\n', blk, frame_pilot);
        fprintf('Bob delay_taps   = '); disp(delay_taps_B);
        fprintf('Bob doppler_taps = '); disp(doppler_taps_B);
        fprintf('Bob chan_coef    = '); disp(chan_coef_B.');

        fprintf('Eve delay_taps   = '); disp(delay_taps_E);
        fprintf('Eve doppler_taps = '); disp(doppler_taps_E);
        fprintf('Eve chan_coef    = '); disp(chan_coef_E.');

        %% -------------------------------------------------
        % Eve真值信道矩阵
        %% -------------------------------------------------
        H_E_true_DD = build_effective_DD_channel( ...
            N, M, delay_taps_E, doppler_taps_E, chan_coef_E);

        [U_E, S_E, ~] = svd(H_E_true_DD);
        sigma_E = diag(S_E);

        %% -------------------------------------------------
        % 导频帧：9导频估计 Bob 信道
        %% -------------------------------------------------
        x_pilot = zeros(N, M);
        for i = 1:N1
            x_pilot(Pilot_row_index(i), Pilot_col_index(i)) = pilot_seq(i);
        end%放置导频

        s_pilot = OTFS_modulation(N, M, x_pilot);%调制
        noiseVar_pilot = mean(abs(s_pilot).^2) / snr_linear;%计算噪声

        r_pilot_B = OTFS_channel_output( ...
            N, M, taps_B, delay_taps_B, doppler_taps_B, chan_coef_B, ...
            noiseVar_pilot, s_pilot);%经过信道

        y_pilot_B = OTFS_demodulation(N, M, r_pilot_B);%解调

        %信道估计部分
        [est_delay_tap_B, est_doppler_tap_B, est_chan_coef_B, score_map, k_list, l_list] = ...
            OTFS_channel_est_pilot_general( ...
                y_pilot_B, ...
                Pilot_row_index, Pilot_col_index, pilot_seq, ...
                max_delay_tap, max_doppler_tap, max_search_paths, ...
                threshold_score, ...
                local_win_k, local_win_l, ...
                min_sep_k, min_sep_l, ...
                rel_amp_th, abs_amp_th);

        % 保底
        if isempty(est_delay_tap_B)
            [~, idx_max] = max(abs(chan_coef_B));
            est_delay_tap_B   = delay_taps_B(idx_max);
            est_doppler_tap_B = doppler_taps_B(idx_max);
            est_chan_coef_B   = chan_coef_B(idx_max);
        end

        % Bob估计等效信道矩阵
        H_B_hat_DD = build_effective_DD_channel( ...
            N, M, est_delay_tap_B, est_doppler_tap_B, est_chan_coef_B);

        [U_B_hat, S_B_hat, V_B_hat] = svd(H_B_hat_DD);%信道分解
        sigma_B_hat = diag(S_B_hat);

        % Ns = min(Ns_fixed, length(sigma_B_hat));
        % Ns = min(Ns, MN);

        U_B_hat_s = U_B_hat(:,1:Ns);
        V_B_hat_s = V_B_hat(:,1:Ns);
        sig_B_hat_s = sigma_B_hat(1:Ns);

        fprintf('Pilot frame %3d: Ns = %d | est paths = %d\n', ...
            frame_pilot, Ns, length(est_delay_tap_B));

        %% -------------------------------------------------
        % 数据发送
        %% -------------------------------------------------
        for inner = 2:pilot_period

            frame = (blk-1)*pilot_period + inner;

            % ---------- 生成Ns路数据 ----------
            data_idx = randi([0 modOrder-1], Ns, 1);
            bits_tx = de2bi(data_idx, bitsPerSym, 'left-msb');
            bits_tx = bits_tx(:);

            d = qammod(data_idx, modOrder, 'gray', 'UnitAveragePower', true);

            % ---------- Bob估计信道预编码 ----------
            x_vec = V_B_hat_s * d;

            % 总发射能量归一化
            x_vec = sqrt(Ns / (sum(abs(x_vec).^2) + eps)) * x_vec;

            x_dd = reshape(x_vec, N, M);

            s = OTFS_modulation(N, M, x_dd);
            noiseVar = mean(abs(s).^2) / snr_linear;

            %% ================= Bob reception =================
            r_B = OTFS_channel_output( ...
                N, M, taps_B, delay_taps_B, doppler_taps_B, chan_coef_B, ...
                noiseVar, s);

            y_B = OTFS_demodulation(N, M, r_B);
            y_B_vec = y_B(:);

            z_B = U_B_hat_s' * y_B_vec;
            d_hat_B = z_B ./ (sig_B_hat_s + 1e-12);

            data_idx_hat_B = qamdemod(d_hat_B, modOrder, 'gray', 'UnitAveragePower', true);
            bits_hat_B = de2bi(data_idx_hat_B, bitsPerSym, 'left-msb');
            bits_hat_B = bits_hat_B(:);

            errBitBob = errBitBob + sum(bits_hat_B ~= bits_tx);

            %% ================= Eve reception =================
            r_E = OTFS_channel_output( ...
                N, M, taps_E, delay_taps_E, doppler_taps_E, chan_coef_E, ...
                noiseVar, s);

            y_E = OTFS_demodulation(N, M, r_E);
            y_E_vec = y_E(:);

            U_E_s = U_E(:,1:Ns);
            sig_E_s = sigma_E(1:Ns);

            y_E_tilde = U_E_s' * y_E_vec;
            z_E = y_E_tilde ./ (sig_E_s + 1e-12);

            data_idx_hat_E = qamdemod(z_E, modOrder, 'gray', 'UnitAveragePower', true);
            bits_hat_E = de2bi(data_idx_hat_E, bitsPerSym, 'left-msb');
            bits_hat_E = bits_hat_E(:);

            errBitEve = errBitEve + sum(bits_hat_E ~= bits_tx);

            totalBits = totalBits + Ns * bitsPerSym;

            %% 累积中间SNR星座图
            if iSNR == mid_idx
                d_show  = [d_show;  d];
                dB_show = [dB_show; d_hat_B];
                zE_show = [zE_show; z_E];
            end
        end
    end

    BER_Bob_list(iSNR) = errBitBob / totalBits;
    BER_Eve_list(iSNR) = errBitEve / totalBits;

    fprintf('SNR = %2d dB | Bob BER = %.6e | Eve BER = %.6e\n', ...
        SNR_dB, BER_Bob_list(iSNR), BER_Eve_list(iSNR));
end

%% =========================================================
% 8. 输出结果表
%% =========================================================
disp(' ');
disp('================ 最终结果汇总 ================');
disp(table(snr_dB_list(:), BER_Bob_list, BER_Eve_list, ...
    'VariableNames', {'SNR_dB', 'BER_Bob', 'BER_Eve'}));

%% =========================================================
% 9. BER曲线
%% =========================================================
figure;
semilogy(snr_dB_list, BER_Bob_list, '-o', 'LineWidth', 1.5, 'MarkerSize', 8); hold on;
semilogy(snr_dB_list, BER_Eve_list, '-s', 'LineWidth', 1.5, 'MarkerSize', 8);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
legend('Bob', 'Eve', 'Location', 'southwest');
title('BER Comparison: Bob vs Eve (9 pilots, fixed blocks for all SNR)');

%% =========================================================
% 10. 多帧累积星座图
%% =========================================================
figure;
subplot(1,3,1);
plot(real(d_show), imag(d_show), 'bo');
grid on;
axis equal;
title(['Original QAM, SNR=', num2str(snr_dB_list(mid_idx)), ' dB']);
xlabel('In-Phase');
ylabel('Quadrature');

subplot(1,3,2);
plot(real(dB_show), imag(dB_show), 'g.');
grid on;
axis equal;
title('Bob equalized symbols');
xlabel('In-Phase');
ylabel('Quadrature');

subplot(1,3,3);
plot(real(zE_show), imag(zE_show), 'r.');
grid on;
axis equal;
title('Eve equalized symbols');
xlabel('In-Phase');
ylabel('Quadrature');

toc;