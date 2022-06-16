%% I05   

% generate the empty image, run the window, and save the file
% first have to read the image DNB and image I5, might also have to mask
% some missing values. 
% So, here we read two files, generate an output, analyze the output using
% -0.6 threshold, look at the histogram and go from there

if useI05
    fileCorr = strcat(outfile,'_xcorr');
else
    fileCorr = strcat(outfile,'_xcorr4');
end

if checkpointFlag && exist(fileCorr, 'file') == 2
    imageCorr = freadenvi(fileCorr);
else
    
    imageCorr = ones(size(imageI05)) * 2;
    
    disp_progress; % Just to show progress
    
    for i=1+XCORR_WIN:dnblines-XCORR_WIN
        disp_progress(i, dnblines);
        
        subimageI05 = imageI05(i-XCORR_WIN:i+XCORR_WIN,:);
        subimageDNB = imageDNB(i-XCORR_WIN:i+XCORR_WIN,:);
        subimageDNB(subimageDNB <= MISSINGVALUE) = NaN;
        
        [mm,nn] = size(subimageI05);
        
        colI05 = im2col(subimageI05,[2*XCORR_WIN+1,2*XCORR_WIN+1]);
        colDNB = im2col(subimageDNB,[2*XCORR_WIN+1,2*XCORR_WIN+1]);
        
        %         size(colI05)
        
        colCorr = corr_col(colI05,colDNB);
        subimageCorr = reshape(colCorr,mm-2*XCORR_WIN,nn-2*XCORR_WIN);
        
        %         size(subimageCorr)
        
        imageCorr(i,XCORR_WIN+1:end-XCORR_WIN) = subimageCorr;
    end
    
    % get rid of NaNs
    nanind = find(isnan(imageCorr));
    imageCorr(nanind) = 2;
    
    if checkpointFlag || dumpFlag
        info=enviinfo(single(imageCorr));
        enviwrite(single(imageCorr),info,fileCorr);
    end
end
