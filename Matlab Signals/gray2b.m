% TODO: this

function bin = gray2b(gray)
    mask = fix(gray/2);
    bin = gray;
    while mask ~= 0
        bin = bitxor(bin,mask);
        mask = fix(mask/2);
    end
end

