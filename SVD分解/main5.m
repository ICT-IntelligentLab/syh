clc; clear; close all;


%% =========================================================
rng(1);

%% ===================== Parameters ========================
M = 16;
N = 8;
MN = M * N;
modOrder = 16;
bitsPerSym = log2(modOrder);

snr_dB_list = 0:5:40;
numFrames = 500;   

% Bob channel
bob.numPaths = 5;
bob.kmax = 2;
bob.lmax = 4;

% Eve channel
eve.numPaths = 3;
eve.kmax = 1;
eve.lmax = 4;

BER_B_list = zeros(length(snr_dB_list), 1);
BER_E_list = zeros(length(snr_dB_list), 1);

%% ===================== SNR Loop ==========================
for iSNR = 1:length(snr_dB_list)

    SNRdB = snr_dB_list(iSNR);
    snr_linear = 10^(SNRdB/10);
    noise_var = 1 / snr_linear;

    errBitBob = 0;
    errBitEve = 0;
    totalBits = 0;

    for frame = 1:numFrames

        %% -------- Generate channel --------
        [HB, ~] = channel_generate_v2(M, N, bob.numPaths, bob.kmax, bob.lmax);
        [HE, ~] = channel_generate_v2(M, N, eve.numPaths, eve.kmax, eve.lmax);

        [HB_eq, ~, ~] = eq_channel_generate(HB, M, N);
        [HE_eq, ~, ~] = eq_channel_generate(HE, M, N);

        %% -------- SVD --------
        [UB, SB, VB] = svd(HB_eq);
        [UE, SE, VE] = svd(HE_eq);

        %% -------- Data generation --------
        data_idx = randi([0 modOrder-1], MN, 1);
        bits_tx = idx2bits_custom(data_idx, modOrder);
        d = qam_mod_custom(data_idx, modOrder);

        %% -------- Precoding --------
        x = VB * d;

        %% -------- Noise --------
        nB = sqrt(noise_var/2) * (randn(MN,1) + 1j*randn(MN,1));
        nE = sqrt(noise_var/2) * (randn(MN,1) + 1j*randn(MN,1));

        %% -------- Bob reception --------
        yB = HB_eq * x + nB;
        yB_tilde = UB' * yB;

        sigmaB = diag(SB);
        thB = 1e-2;
        sigmaB_inv = zeros(size(sigmaB));
        sigmaB_inv(sigmaB > thB) = 1 ./ sigmaB(sigmaB > thB);

        dB_hat = diag(sigmaB_inv) * yB_tilde;
        data_idx_B_hat = qam_demod_custom(dB_hat, modOrder);
        bits_B_hat = idx2bits_custom(data_idx_B_hat, modOrder);

        %% -------- Eve reception --------
        yE = HE_eq * x + nE;
        yE_tilde = UE' * yE;

        sigmaE = diag(SE);
        thE = 1e-2;
        sigmaE_inv = zeros(size(sigmaE));
        sigmaE_inv(sigmaE > thE) = 1 ./ sigmaE(sigmaE > thE);

        dE_hat = VE * diag(sigmaE_inv) * yE_tilde;
        data_idx_E_hat = qam_demod_custom(dE_hat, modOrder);
        bits_E_hat = idx2bits_custom(data_idx_E_hat, modOrder);

        %% -------- Count BER --------
        errBitBob = errBitBob + sum(bits_B_hat ~= bits_tx);
        errBitEve = errBitEve + sum(bits_E_hat ~= bits_tx);
        totalBits = totalBits + MN * bitsPerSym;
    end

    BER_B_list(iSNR) = errBitBob / totalBits;
    BER_E_list(iSNR) = errBitEve / totalBits;

    fprintf('SNR = %2d dB | Bob BER = %.4e | Eve BER = %.4e\n', ...
        SNRdB, BER_B_list(iSNR), BER_E_list(iSNR));
end

%% ===================== Plot BER Curve ====================
figure;
semilogy(snr_dB_list, BER_B_list, '-o', 'LineWidth', 1.5); hold on;
semilogy(snr_dB_list, BER_E_list, '-s', 'LineWidth', 1.5);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
legend('Bob', 'Eve');
title('R-OTFS BER Performance');
ylim([1e-4 1e0]);