%%
function strImage = stretch(origImage)

global FILLVALUE

maxim = max(origImage(:));
missim = find(origImage < -999);
% numel(missim)
origImage(missim) = maxim + 10;
minim = min(origImage(:));
origImage(missim) = minim;

logImage = log10(max(origImage + 3,0));
% logmin = min(logImage(:))
% logmax = max(logImage(:))

% strImage = double((logImage-logmin)./(logmax-logmin)) * 255;
% strImage = double((origImage-minim)./(maxim-minim)) * 255;
strImage = logImage;
logImage(missim) = FILLVALUE;

end
