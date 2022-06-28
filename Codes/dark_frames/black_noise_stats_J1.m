clear all
close all

%% DNB agg zones table
aggzone = readtable('DNB_agg_zones_J1_simplified.csv')

%% DNB day-night band
% dnbfile = 'j01_d20210209_t1158319_e1159564_b16729/SVDNB_j01_d20210209_t1158319_e1159564_b16729_c20210209122610876400_oeac_ops.h5';
% dnbfile = 'j01_d20210209_t1157061_e1158306_b16729/SVDNB_j01_d20210209_t1157061_e1158306_b16729_c20210209122546283013_oeac_ops.h5';
 dnbfile = 'j01_d20210209_t1159576_e1201204_b16729/SVDNB_j01_d20210209_t1159576_e1201204_b16729_c20210209122614367276_oeac_ops.h5';
% dnbfile = 'SVM07_npp_d20220214_t2241425_e2243067_b53381_c20220214234643876148_oebc_ops.h5';

%dnbfile = 'SVDNB_npp_d20180108_t0822167_e0827571_b32120_c20180108142757736055_noac_ops.h5';
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
%[p,S] = polyfit(double(goodrange),dnbvar(goodrange)',2)
%p = polyfit(double(goodrange),dnbvar(goodrange)',2)

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
xlabel('J1 DNB sample')
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
