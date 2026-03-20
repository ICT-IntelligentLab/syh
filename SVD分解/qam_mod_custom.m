function sym = qam_mod_custom(data_idx, modOrder)
% ===========================================================
% Custom square-QAM modulation with unit average power
% For modOrder = 4, 16, 64, ...
% Input:
%   data_idx : integers in [0, modOrder-1]
% Output:
%   sym      : complex QAM symbols, normalized
% ===========================================================

L = sqrt(modOrder);
if abs(L - round(L)) > 1e-12
    error('modOrder must be a perfect square.');
end
L = round(L);

% 映射到二维坐标
I_idx = mod(data_idx, L);
Q_idx = floor(data_idx / L);

% 映射到 PAM 电平，例如 16QAM 时 -> [-3 -1 1 3]
I = 2 * I_idx - (L - 1);
Q = 2 * Q_idx - (L - 1);

% 为了让星座图更标准，上面为低，下面为高可改成负号
sym = I + 1j * Q;

% 单位平均功率归一化
sym = sym / sqrt(mean(abs(sym).^2));
end