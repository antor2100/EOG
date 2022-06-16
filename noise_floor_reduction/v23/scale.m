%%
function [scImage, multiplier, offset] = scale(origImage)

maxim = max(origImage(:));
minim = min(origImage(:));

multiplier = NaN;
if maxim-minim > 0
    multiplier = double(1/(maxim-minim));
end

offset = double(minim);

scImage = double((origImage - offset) * multiplier) * 255;

end
