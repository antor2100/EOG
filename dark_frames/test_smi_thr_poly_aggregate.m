clear all
close all

SMI = 0.035;

aggrJ01  = [...
           1          32           0           7;...
           2          21           8         463;...
           6          20         464         495;...
           8          19         496         543;...
          10          18         544         575;...
          12          17         576         647;...
          13          16         648         719;...
          14          15         720         791;...
          15          14         792         871;...
          16          13         872         927;...
          17          12         928        1007;...
          18          11        1008        1071;...
          19          10        1072        1135;...
          20           9        1136        1199;...
          21           8        1200        1263;...
          22           7        1264        1327;...
          23           6        1328        1399;...
          24           5        1400        1479;...
          25           4        1480        1551;...
          27           3        1552        1639;...
          29           2        1640        1711;...
          31           1        1712        2079;...
          35           2        2080        2151;...
          37           3        2152        2239;...
          39           4        2240        2311;...
          31           5        2312        2391;...
          42           6        2392        2463;...
          43           7        2464        2527;...
          44           8        2528        2591;...
          45           9        2592        2655;...
          46          10        2656        2719;...
          47          11        2720        2783;...
          48          12        2784        2863;...
          49          13        2864        2919;...
          50          14        2920        2999;...
          51          15        3000        3071;...
          52          16        3072        3143;...
          53          17        3144        3215;...
          54          18        3216        3247;...
          56          19        3248        3295;...
          58          20        3296        3327;...
          60          21        3328        4063];

nzJ01 = size(aggrJ01,1)
rangesJ01 = zeros(2,nzJ01);
for i=1:nzJ01
    rangesJ01(1,i) = aggrJ01(i,3) + 1;
    rangesJ01(2,i) = aggrJ01(i,4) + 1;
end

%% J01 DNB day-night band
% dnbfile = 'dark_frames/j01_d20210209_t1158319_e1159564_b16729/SVDNB_j01_d20210209_t1158319_e1159564_b16729_c20210209122610876400_oeac_ops.h5';
dnbfile = 'j01_d20210209_t1157061_e1158306_b16729/SVDNB_j01_d20210209_t1157061_e1158306_b16729_c20210209122546283013_oeac_ops.h5';
% dnbfile = 'dark_frames/j01_d20210209_t1159576_e1201204_b16729/SVDNB_j01_d20210209_t1159576_e1201204_b16729_c20210209122614367276_oeac_ops.h5';
% DNB radiance
dnbdataset = '/All_Data/VIIRS-DNB-SDR_All/Radiance';
dnbdata = viirs_get_data(dnbfile, dnbdataset)' * 1e9;

Y_scale = 0.5;

figure()
histogram(dnbdata(:),50,'Binlimits',[-1,1])

%% Noise stats by agg zone
ndnb = size(dnbdata,2);
zsigma = zeros(nzJ01,1);
dzsigma = zeros(ndnb,1);
for i = 1:nzJ01
    zrange = rangesJ01(1,i):rangesJ01(2,i);
    disp(zrange);
    dnbstripe = dnbdata(:,zrange);
    zsigma(i) = std(dnbstripe(:));
    dzsigma(zrange) = zsigma(i);
end

%% fit polynomial to the DNB variance
dnbvar = zeros(ndnb,1);
for i = 1:size(dnbdata,2)
    dnbvar(i) = std(dnbdata(:,i));
end

goodrange = 464:3327;
size(goodrange)
size(dnbvar(goodrange))
% [p,S] = polyfit(double(goodrange),dnbvar(goodrange)',2)
% p = polyfit(double(goodrange),dnbvar(goodrange)',2)

% [polyvar,delta] = polyval(p,goodrange,S);
% [sigmanoise,sdelta] = polyval(p,1:4064,S);

p = [2.68761561326876e-08,-0.000101778246819055,0.134918217384128 + 0.01]
polyvar = polyval(p,goodrange);
sigmanoiseJ01 = polyval(p,1:4064);

%%
SCALE = 1;
af3 = single(wiener2(dnbdata,[3 3],SCALE*sigmanoiseJ01));
af3(:,1:464) = 0;
af3(:,3328:4064) = 0;

%% Find SMI spikes
imgmed = medfilt2(af3,[3 3]);
imgfiltJ01 = (af3 - imgmed);

zsmimax = zeros(ndnb,1);
dzsmimax = zeros(ndnb,1);
for i = 1:nzJ01
    zrange = rangesJ01(1,i):rangesJ01(2,i);
    smistripe = imgfiltJ01(:,zrange);
    zsmimax(i) = max(smistripe(:));
    dzsmimax(zrange) = zsmimax(i);
end

dsmimax = zeros(ndnb,1);
for i = 1:size(dnbdata,2)
    dsmimax(i) = max(imgfiltJ01(:,i));
end

scrsz = get(0,'ScreenSize');
figure('Position',[1 scrsz(4)/2-50 scrsz(3) scrsz(4)/2],'Name','DNB variance');
subplot(1,2,1)
bar(dzsmimax)
hold on
plot(goodrange,polyvar,'r')
% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlabel('J1 DNB sample')
ylabel('Max(SMI) by aggregation mode')

subplot(1,2,2)
plot(goodrange,dsmimax(goodrange),'r')
hold on
plot(goodrange,polyvar,'r')
% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlabel('J1 DNB sample')
ylabel('Max(SMI) by column')

%% SMI detector
spikethr = zeros(size(dnbdata));
onespike = ones(size(dnbdata));
% spikethr(:,goodrange) = onespike(:,goodrange) .* (polyvar + delta);
spikethr(:,goodrange) = onespike(:,goodrange) .* (polyvar);
figure
imagesc(spikethr)

[row,col] = find(imgfiltJ01 > spikethr);

%%
scrsz = get(0,'ScreenSize');
gid3 = figure('Position',[1 scrsz(4)/5-50 scrsz(3) scrsz(4)/5],'Name','DNB image');

ax1 = subplot(1,2,1)
image(dnbdata*5*1e2);
colormap('gray');
axis equal
% hold on
% plot(cdnbdnb(cdnbdnb ~= fillvalue),rdnbdnb(rdnbdnb ~= fillvalue),'r+');
title('DNB original');
hold off

ax2 = subplot(1,2,2)
image(af3*1e2);
colormap('gray');
axis equal
hold on
plot(col,row,'r+')
% plot(cdnbdnb(cdnbdnb ~= fillvalue),rdnbdnb(rdnbdnb ~= fillvalue),'r+');
title('DNB after Wiener filter');
hold off

linkaxes([ax1, ax2])
zoom on

%%
scrsz = get(0,'ScreenSize');
figure('Position',[1 1 scrsz(3) scrsz(4)]);
    
[Line_DNB,Sample_DNB] = find(imgfiltJ01 > -1000);

plot(Sample_DNB,imgfiltJ01(imgfiltJ01 > -1000),'.')

hold on

plot(SCALE * sigmanoiseJ01,'g--','LineWidth',4,'DisplayName','Wiener Sigma')

for i=1:nzJ01-1
    vline(rangesJ01(2,i))
end

ylim([-0.1,0.2])
xlim([0,4100])

%     xlabel('Sample position in image')
%     ylabel('SMI')
xlabel('J01 VIIRS DNB sample')
ylabel('SMI threshold')

set(gca,'fontsize',24)

%     zoom on

%%
scrsz = get(0,'ScreenSize');
figure('Position',[1 scrsz(4)/2-50 scrsz(3) scrsz(4)/2],'Name','DNB variance');
subplot(1,2,1)
bar(dzsigma)
hold on
plot(goodrange,polyvar,'r')
% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlabel('J1 DNB sample')
ylabel('STD by aggregation mode')

subplot(1,2,2)
plot(dnbvar)
hold on
plot(goodrange,polyvar,'r')
% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlabel('J1 DNB sample')
ylabel('STD by image column')

%%
aggrDNB = [...
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
    30 21 12 64 4.6048E-05;... 
    31 20 12 16 4.6048E-05;... 
    32 20 11 80 4.2210E-05]

ranges = zeros(2,32);
ranges(:,1) = [2032 - aggrDNB(1,4) + 1, 2032];  % the ranges for SNPP is half width, for J1 it is full width (because J1 is assymetric)
for i=2:32
    ranges(1,i) = ranges(1,i-1) - aggrDNB(i,4);
    ranges(2,i) = ranges(1,i-1) - 1;
end

%%
PNOISE = [7.194118e-23, -8.837980e-19, 4.292086e-15, -1.046121e-11, 1.350611e-08, -8.960062e-06, 2.622827e-03];

sigmanoise = polyval(PNOISE,1:4064)';

spikeThreshFixOld = ones(4064,1) * SMI;
spikeThreshFixOld(1:224) = spikeThreshFixOld(1:224) * 2;
spikeThreshFixOld(225:632) = spikeThreshFixOld(225:632) * 1.5;
spikeThreshFixOld(3841:end) = spikeThreshFixOld(3841:end) * 2;
spikeThreshFixOld(3433:3840) = spikeThreshFixOld(3433:3840) * 1.5;

spikeThreshFix = ones(4064,1) * SMI;                    % changed
spikeThreshFix(1:96) = spikeThreshFix(1:96) * 3;
spikeThreshFix(97:416) = spikeThreshFix(97:416) * 2;
spikeThreshFix(417:632) = spikeThreshFix(417:632) * 1.5;
spikeThreshFix(633:856) = spikeThreshFix(633:856) * 1.25;

spikeThreshFix(end-96+1:end) = spikeThreshFix(end-96+1:end) * 3;
spikeThreshFix(end-416+1:end-96) = spikeThreshFix(end-416+1:end-96) * 2;
spikeThreshFix(end-632+1:end-416) = spikeThreshFix(end-632+1:end-416) * 1.5;
spikeThreshFix(end-856+1:end-632) = spikeThreshFix(end-856+1:end-632) * 1.25;

if true
    imgfilt = freadenvi('./boat_aggregate_for_paper/SVDNB_npp_d20140927_t1834358_e1840162_b15115_c20140928004016952044_noaa_ops.boats.smi');  % find this file (might be on eogdrive, but Misha will share it with me)
    slval = freadenvi('./boat_aggregate_for_paper/SVDNB_npp_d20140927_t1834358_e1840162_b15115_c20140928004016952044_noaa_ops.boats.lwmask'); % these files were processed from h5 file. lwmask is land something mask as 
                                                                                                                                              % as there might be islands. So, we only use pixels that are in water.
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 1 scrsz(3) scrsz(4)]);
        
    [Line_DNB,Sample_DNB] = find(slval > 0);

    plot(Sample_DNB,imgfilt(slval > 0),'.')

    hold on

    plot(sigmanoise*2,'g--','LineWidth',4,'DisplayName','Wiener Sigma')
    plot(spikeThreshFix,'r','LineWidth',4,'DisplayName','SMI threshold')

    for i=2:32
        vline(ranges(2,i))                                 % Misha will send me the code for vline function. it will just draw vertical lines.
        vline(4064-ranges(2,i))
    end
                                                           % We will
                                                           % introduce the
                                                           % new file from
                                                           % deep ocean
                                                           % that Chris
                                                           % found to this
                                                           % code. Misha
                                                           % will also dig
                                                           % the original
                                                           % image Kim was
                                                           % working on.
                                                           
                                                           % we also try
                                                           % the code on
                                                           % low moon and
                                                           % other
                                                           % conditions.
                                           
    ylim([-0.1,0.2])
    xlim([0,4100])
    
%     xlabel('Sample position in image')
%     ylabel('SMI')
    xlabel('VIIRS DNB sample')
    ylabel('SMI threshold')

    set(gca,'fontsize',24)

%     zoom on
end
