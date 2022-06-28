function [imgspike,thr]  = spikes(imgin,spikeThresh)

imgmed = medfilt2(imgin,[3 3]);
imgfilt = (imgin - imgmed);

[im2,T] = dorosinthreshold(imgfilt(imgfilt<100 & imgfilt>0), 100);

imgspike = zeros(size(imgin));
imgspike(imgfilt > T & imgfilt > spikeThresh) = imgin(imgfilt > T & imgfilt > spikeThresh);

thr = T*spikeThresh;
disp(['Spike radiance threshold = ' num2str(thr)]);

if false
    figure
    [nelements,centers]  = hist(imgfilt(imgfilt<10 & imgfilt > 0),100);
    bar(centers,nelements);
    hold on
    plot([T*spikeThresh T*spikeThresh],[0 max(nelements)],'r')
    xlabel('Radiance','FontSize',12)
    ylabel('Tally','FontSize',12)
    set(gca,'FontSize',12)
    zoom on

    spval = imgspike(imgspike>0);
    sphgt = imgfilt(imgspike>0);
    nospval = imgspike(imgspike==0);
    nosphgt = imgfilt(imgspike==0);
    figure
    plot(nospval(:),nosphgt(:),'b.');
    hold on
    plot(spval(:),sphgt(:),'r.');
    zoom on
    
    scrsz = get(0,'ScreenSize');
%     figure('Position',[1 1 scrsz(3) scrsz(4)]);
%     figure('Position',[1 scrsz(4)/2-50 scrsz(3) scrsz(4)/2]);
%     subplot(1,2,1)
    figure
    plot(imgin(1567,2800:3300))
    hold on
    plot(imgmed(1567,2800:3300),'r')
    xlim([0,500])
    legend('DNB image profile','Median filter applied')
    ylabel('Radiance','FontSize',12)
    xlabel('Pixel','FontSize',12)
    set(gca,'FontSize',12)
    zoom on

    [pks,locs] = findpeaks(double(imgfilt(1567,2800:3300)).*double(imgfilt(1567,2800:3300) > T*spikeThresh))    
    
%     subplot(1,2,2)
    figure
    plot(imgfilt(1567,2800:3300))
    hold on
    plot([0,500],[T,T],'r')
    plot(locs,pks,'r^')
    legend('DNB and median filter difference','Rosin threshold','Detected spikes')
    xlim([0,500])
    ylabel('Radiance','FontSize',12)
    xlabel('Pixel','FontSize',12)
    set(gca,'FontSize',12)
    
    zoom on
%     linkaxes
    
    info = enviinfo(imgmed);
    enviwrite(imgmed,info,'median_filt.dat'); 

    info = enviinfo(imgfilt);
    enviwrite(imgfilt,info,'dnb-median_filt.dat'); 
end

% max(max(imgfilt))
% max(max(imgspike))

end