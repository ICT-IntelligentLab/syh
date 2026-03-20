function data_idx = bits2idx_custom(bits, modOrder)

bitsPerSym = log2(modOrder);

if mod(length(bits), bitsPerSym) ~= 0
    error('Length of bits must be a multiple of log2(modOrder).');
end

numSym = length(bits) / bitsPerSym;
bitsMat = reshape(bits, bitsPerSym, numSym).';

data_idx = zeros(numSym, 1);

for i = 1:numSym
    val = 0;
    for b = 1:bitsPerSym
        val = 2 * val + bitsMat(i, b);
    end
    data_idx(i) = val;
end
end