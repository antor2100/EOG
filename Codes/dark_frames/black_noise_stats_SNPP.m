clear all
close all

%% DNB agg zones table
aggzone = [...
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

%% DNB day-night band
dnbfile = 'SVDNB_npp_d20170128_t1255482_e1301286_b27228_c20170128190129026938_noaa_ops.h5';

% DNB radiance
dnbdataset = '/All_Data/VIIRS-DNB-SDR_All/Radiance';
dnbdata = viirs_get_data(dnbfile, dnbdataset)' * 1e9;

Y_scale = 0.5;

figure()
histogram(dnbdata(:),50,'Binlimits',[-1,1])

%% Noise stats by agg zone
nz = size(aggzone,1);
ndnb = size(dnbdata,2);
zsigma = zeros(nz,1);
dzone = zeros(ndnb,1);
dzsigma = zeros(ndnb,1);
for i = 1:nz
    zrange = aggzone.Lower_pixel(i)+1:aggzone.Upper_pixel(i)+1;
    zmode = aggzone.Aggregation_Mode(i);
    dnbstripe = dnbdata(:,zrange);
    zsigma(i) = std(dnbstripe(:));
    dzone(zrange) = zmode;
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
[p,S] = polyfit(double(goodrange),dnbvar(goodrange)',2)
p = polyfit(double(goodrange),dnbvar(goodrange)',2)

% [polyvar,delta] = polyval(p,goodrange,S);
% [sigmanoise,sdelta] = polyval(p,1:4064,S);

p = [2.68761561326876e-08,-0.000101778246819055,0.134918217384128 + 0.01]
polyvar = polyval(p,goodrange);
sigmanoise = polyval(p,1:4064);

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
xlabel('SNPP DNB sample')
ylabel('STD by image column')

%%
SCALE = 1;
af3 = single(wiener2(dnbdata,[3 3],SCALE*sigmanoise));
af3(:,1:464) = 0;          % do not detect boats at the outskirts
af3(:,3328:4064) = 0;      % do not detect boats at the outskirts

%% Find SMI spikes
imgmed = medfilt2(af3,[3 3]);   % median filter image that has no spikes
imgfilt = (af3 - imgmed);   % subtracting median filter from weiner filter (which has spikes) gives only spikes and thus are candidates for boats

zsmimax = zeros(ndnb,1);
dzsmimax = zeros(ndnb,1);
for i = 1:nz
    zrange = aggzone.Lower_pixel(i)+1:aggzone.Upper_pixel(i)+1;
    smistripe = imgfilt(:,zrange);
    zsmimax(i) = max(smistripe(:));
    dzsmimax(zrange) = zsmimax(i);
end

dsmimax = zeros(ndnb,1);
for i = 1:size(dnbdata,2)
    dsmimax(i) = max(imgfilt(:,i));
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

[row,col] = find(imgfilt > spikethr);

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
