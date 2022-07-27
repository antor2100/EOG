clear all
close all

SMI = 0.035;

aggrSNPP = [...
    1 42 66 184 2.5326E-04;...
    2 42 64 72 2.4559E-04;... 
    3 41 62 88 2.3791E-04;... 
    4 40 59 72 2.2640E-04;... 
    5 39 55 80 2.1105E-04;... 
    6 38 52 72 1.9954E-04;... 
    7 37 49 64 1.8803E-04;... 
    8 36 46 64 1.7652E-04;... 
    9 35 43 64 1.6500E-04;... 
    10 34 40 64 1.5349E-04;... 
    11 33 38 64 1.4582E-04;... 
    12 32 35 80 1.3431E-04;... 
    13 31 33 56 1.2663E-04;... 
    14 30 30 80 1.1512E-04;... 
    15 29 28 72 1.0744E-04;... 
    16 28 26 72 9.9770E-05;... 
    17 27 24 72 9.2095E-05;... 
    18 27 23 32 8.8258E-05;... 
    19 26 22 48 8.4421E-05;... 
    20 26 21 32 8.0583E-05;... 
    21 25 20 48 7.6746E-05;... 
    22 25 19 40 7.2909E-05;... 
    23 24 18 56 6.9071E-05;... 
    24 24 17 40 6.5234E-05;... 
    25 23 16 72 6.1397E-05;... 
    26 23 15 24 5.7559E-05;... 
    27 22 15 32 5.7559E-05;... 
    28 22 14 64 5.3722E-05;... 
    29 21 13 64 4.9885E-05;... 
    30 21 12 64 4.6048E05;... 
    31 20 12 16 4.6048E-05;... 
    32 20 11 80 4.2210E-05]

nzSNPP = size(aggrSNPP,1)*2;
ranges = zeros(2,64);
ranges(:,1) = [4064 - aggrSNPP(1,4) + 1, 4064];
ranges(:,33) = [2032 - aggrSNPP(1,4) + 1, 2032];
for i=2:32
    ranges(1,32 + i) = ranges(1,32 + i - 1) - aggrSNPP(i,4);
    ranges(2,32 + i) = ranges(1,32 + i - 1) - 1;
 
    ranges(1,34 - i) = 4064 - ranges(2,32 + i - 1) + 1;
    ranges(2,34 - i) = 4064 - ranges(1,32 + i - 1);
end

%% SNPP DNB day-night band
% dnbfile = 'SVDNB_npp_d20170128_t1255482_e1301286_b27228_c20170128190129026938_noaa_ops.h5';
 dnbfile = 'Data/for_antor/h5_folder/SVDNB_npp_d20220708_t1028229_e1029471_b55417_c20220708155646366494_oeac_ops.h5';

% DNB radiance
dnbdataset = '/All_Data/VIIRS-DNB-SDR_All/Radiance';
dnbdata = viirs_get_data(dnbfile, dnbdataset)' * 1e9;

%disp(size(dnbdata))

Y_scale = 0.5;

figure()
histogram(dnbdata(:),50,'Binlimits',[-1,1])

%% Noise stats by agg zone
ndnb = size(dnbdata,2);
zsigma = zeros(nzSNPP,1);
dzsigma = zeros(ndnb,1);

for i = 1:nzSNPP
    zrange = ranges(1,i):ranges(2,i);
    dnbstripe = dnbdata(:,zrange);
    zsigma(i) = std(dnbstripe(:));
    dzsigma(zrange) = zsigma(i);
end

%% fit polynomial to the DNB variance

% mean_dnbvar = mean(dnbvar);
temp = zeros(ndnb,1);

for i = 1:size(dnbdata,2)
    temp(i) = std(dnbdata(:,i));
end

mean_dnbvar = mean(temp);

dnbvar = zeros(ndnb,1);

for i = 1:size(dnbdata,2)
    if std(dnbdata(:,i)) - mean_dnbvar > 10000
        dnbvar(i) = mean_dnbvar;
    else
        dnbvar(i) = std(dnbdata(:,i));
        
    end
end

goodrange = 1:4064;
p = polyfit(double(goodrange),dnbvar(goodrange)',2);

polyvar = polyval(p,goodrange);
sigmanoiseSNPP = polyval(p,1:4064);

%%
SCALE = 1;
af3 = single(wiener2(dnbdata,[3 3],SCALE*sigmanoiseSNPP));

imwrite(double(af3), [dnbfile,'Wiener.tif'], 'Compression','none');

%af3(:,1:464) = 0;
% af3(:,3328:4064) = 0;

%% Find SMI spikes
% did not understand quite what is going on here

imgmed = medfilt2(af3,[3 3]);
imgfiltSNPP = (af3 - imgmed);

zsmimax = zeros(ndnb,1);
dzsmimax = zeros(ndnb,1);
for i = 1:nzSNPP
    zrange = ranges(1,i):ranges(2,i);
    smistripe = imgfiltSNPP(:,zrange);
    zsmimax(i) = max(smistripe(:));
    dzsmimax(zrange) = zsmimax(i);
end

dsmimax = zeros(ndnb,1);
for i = 1:size(dnbdata,2)
    dsmimax(i) = max(imgfiltSNPP(:,i));
end

scrsz = get(0,'ScreenSize');
figure('Position',[1 scrsz(4)/2-50 scrsz(3) scrsz(4)/2],'Name','DNB variance');
subplot(1,2,1)
bar(dzsmimax)
hold on
plot(goodrange,polyvar,'r')
% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlabel('SNPP DNB sample')
ylabel('Max(SMI) by aggregation mode')

subplot(1,2,2)
plot(goodrange,dsmimax(goodrange),'r')
hold on
plot(goodrange,polyvar,'r')
% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlabel('SNPP DNB sample')
ylabel('Max(SMI) by column')

%% SMI detector
spikethr = zeros(size(dnbdata));
onespike = ones(size(dnbdata));
% spikethr(:,goodrange) = onespike(:,goodrange) .* (polyvar + delta);
spikethr(:,goodrange) = onespike(:,goodrange) .* (polyvar);
figure
imagesc(spikethr)

[row,col] = find(imgfiltSNPP > spikethr);

%%
srgb =zeros(size(af3,1), size(af3,2), 3, 'uint8');
srgb(:,:,1)  = round(scalenoise(dnbdata));
srgb(:,:,2)  = round(scalenoise(af3));    % why Wiener filtered in the second and third dimension?
srgb(:,:,3)  = round(scalenoise(af3));
%srgb(10,10,:)
size(srgb)
red = srgb(:,:,3);
%histogram(red(:))
%imagesc(round(srgb));
imshow(srgb)

figure
plot(dnbdata(:,1), 'm')
hold on
plot(af3(:,1), 'b')
hold on
plot(dnbdata(:,2), 'g')
hold on
plot(af3(:,2))
ylim([-2,2])
xlabel('Lines')
ylabel('Radiance')
hold off
[~, hobj, ~, ~] = legend('original image column 1', 'Wiener filtered image column 1', 'original image column 2', 'Wiener filtered image column 2','location', 'north', 'NumColumns',2)
hl = findobj(hobj,'type','line');
set(hl,'LineWidth',2);
title('20141122')
%%
class(dnbdata)

sdnbdata = scale(dnbdata);
%image(dnbdata*5*1e2);
image(sdnbdata);
size(dnbdata)
colormap('gray');
axis off
axis image
ax = gca;

exportgraphics(ax,'myplot3.tif','Resolution',1000)
%saveas(gca, 'myplot3.tif');
%export_fig ('myplot3.tif', '-native')

image(af3);
colormap('gray');
axis off
plot(col,row,'r+')
ax =gca;

exportgraphics(ax,'myplot.tif','Resolution',1000)
% plot(cdnbdnb(cdnbdnb ~= fillvalue),rdnbdnb(rdnbdnb ~= fillvalue),'r+');
%xlim([0 4000])
%ylim([-500 3000])
hold off

zoom on

%%
scrsz = get(0,'ScreenSize');
figure('Position',[1 1 scrsz(3) scrsz(4)]);
    
[Line_DNB,Sample_DNB] = find(imgfiltSNPP > -1000);

plot(Sample_DNB,imgfiltSNPP(imgfiltSNPP > -1000),'.')

hold on

plot(SCALE * sigmanoiseSNPP,'g--','LineWidth',4,'DisplayName','Wiener Sigma')

%for i=1:nzSNPP-1
%    vline(ranges(2,i))
%end

ylim([-0.1,0.2])
xlim([0,4100])

%     xlabel('Sample position in image')
%     ylabel('SMI')
xlabel('SNPP VIIRS DNB sample')
ylabel('SMI threshold')

set(gca,'fontsize',24)

%     zoom on

%%

% why is dzsigma half width but dnbvar is full width

scrsz = get(0,'ScreenSize');
figure('Position',[1 scrsz(4)/2-50 scrsz(3) scrsz(4)/2],'Name','DNB variance');
subplot(1,2,1)
bar(dzsigma)
hold on
plot(goodrange,polyvar,'r')
% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlabel('SNPP DNB sample')
ylabel('STD by aggregation mode')

subplot(1,2,2)
plot(dnbvar)
hold on
plot(goodrange,polyvar,'r')
% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlabel('SNPP DNB sample')
ylabel('STD by image column')