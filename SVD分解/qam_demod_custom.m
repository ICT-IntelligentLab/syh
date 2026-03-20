function data_idx_hat = qam_demod_custom(sym_hat, modOrder)
% ===========================================================
% Custom square-QAM hard demodulation
% Input:
%   sym_hat       : received symbols
%   modOrder      : 4, 16, 64, ...
% Output:
%   data_idx_hat  : detected integer symbols
% ===========================================================

L = sqrt(modOrder);
if abs(L - round(L)) > 1e-12
    error('modOrder must be a perfect square.');
end
L = round(L);

% 用理论星座点生成参考星座
ref_idx = (0:modOrder-1).';
ref_sym = qam_mod_custom(ref_idx, modOrder);

data_idx_hat = zeros(length(sym_hat), 1);

for k = 1:length(sym_hat)
    [~, idx_min] = min(abs(sym_hat(k) - ref_sym).^2);
    data_idx_hat(k) = ref_idx(idx_min);
end
end