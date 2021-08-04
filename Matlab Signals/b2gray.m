function gray = b2gray(bin)
    gray = bitxor(bin,fix(bin/2));
end

