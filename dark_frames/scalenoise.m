%%
function scImage = scalenoise(origImage)

threshold = 1;

origImage(origImage < -threshold) = -threshold;
origImage(origImage > threshold) = threshold;

maxim = max(origImage(:))
minim = min(origImage(:))

scImage = double((origImage-minim)./(maxim-minim)) * 255;

end
