function bits = idx2bits_custom(data_idx, modOrder)

bitsPerSym = log2(modOrder);
numSym = length(data_idx);

bitsMat = zeros(numSym, bitsPerSym);

for i = 1:numSym
    val = data_idx(i);
    for b = bitsPerSym:-1:1
        bitsMat(i, b) = mod(val, 2);
        val = floor(val / 2);
    end
end

bits = reshape(bitsMat.', [], 1);
end