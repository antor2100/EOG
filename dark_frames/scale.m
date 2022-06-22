%%
function scImage = scale(origImage)

maxim = max(origImage(:))
minim = min(origImage(:))

scImage = double((origImage-minim)./(maxim-minim)) * 255;

end
