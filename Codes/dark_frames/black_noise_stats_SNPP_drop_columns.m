clear all
close all

%% SNPP DNB day-night band
% dnbfile = 'SVDNB_npp_d20170128_t1255482_e1301286_b27228_c20170128190129026938_noaa_ops.h5';
%dnbfile = 'for_antor/2014/SVDNB_npp_d20140101_t1215145_e1220549_b11295_c20140101182055342789_noaa_ops.h5';
dnbfile = 'for_antor/2022/SVDNB_npp_d20220430_t1334313_e1335555_b54440_c20220430150901529459_oebc_ops.h5';

% DNB radiance
dnbdataset = '/All_Data/VIIRS-DNB-SDR_All/Radiance';
dnbdata = viirs_get_data(dnbfile, dnbdataset)' * 1e9;

%disp(size(dnbdata))

Y_scale = 0.5;

figure()
histogram(dnbdata(:),50,'Binlimits',[-1,1])

%% Create another array with spikes removed

dnbdata_2 = dnbdata;

m = mean(mean(dnbdata));
flag = 1;
j = 120;

while j <= size(dnbdata,2) - 120
    i = 1;
    while i <= size(dnbdata,1)
        if dnbdata(i,j) > m + 1
            dnbdata(:,j) = [];
            flag = 0;
            break;
        
        else
            i = i + 1;
            flag = 1;
        end
    end
    
    if flag == 1
        j = j + 1;
    end
        
end


A =[2 16 3 13; 9 7 6 12; 4 14 14 17]
flag = 1;
j = 1;


while j <= size(A,2)
    %disp(j)
    i = 1;
    while i <= size(A,1)
        %disp(i)
        
        %disp('element')
        %disp(A(i,j))
        if A(i,j) > 15
            %dnbdata(i,j) = m;
            A(:,j) = [];
            flag = 0;
            break;
        
        else
            i = i + 1;
            flag = 1;
        end
    end
    
    if flag == 1
        j = j + 1;
    end
        
end
%A
%size(A)

%% 

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
ranges(:,1) = [size(dnbdata,2) - aggrSNPP(1,4) + 1, size(dnbdata,2)];
ranges(:,33) = [2032 - aggrSNPP(1,4) + 1, 2032];
for i=2:32
    ranges(1,32 + i) = ranges(1,32 + i - 1) - aggrSNPP(i,4);
    ranges(2,32 + i) = ranges(1,32 + i - 1) - 1;
 
    ranges(1,34 - i) = size(dnbdata,2) - ranges(2,32 + i - 1) + 1;
    ranges(2,34 - i) = size(dnbdata,2) - ranges(1,32 + i - 1);
end
        
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

zsigma = zeros(nzSNPP,1);
dzsigma_2 = zeros(ndnb,1);

for i = 1:nzSNPP
    zrange = ranges(1,i):ranges(2,i);
    dnbstripe = dnbdata_2(:,zrange);
    zsigma(i) = std(dnbstripe(:));
    dzsigma_2(zrange) = zsigma(i);
end


%% fit polynomial to the DNB variance

% mean_dnbvar = mean(dnbvar);
temp = zeros(ndnb,1);

dnbvar = zeros(ndnb,1);

for i = 1:size(dnbdata,2)
    dnbvar(i) = std(dnbdata(:,i));   
end

dnbvar_2 = zeros(ndnb,1);

for i = 1:size(dnbdata_2,2)
    dnbvar_2(i) = std(dnbdata_2(:,i));   
end

goodrange = 1:size(dnbdata,2);
% [p,S] = polyfit(double(goodrange),dnbvar(goodrange)',2)
p = polyfit(double(goodrange),dnbvar(goodrange)',2);

% [polyvar,delta] = polyval(p,goodrange,S);
% [sigmanoise,sdelta] = polyval(p,1:4064,S);

% p = [2.68761561326876e-08,-0.000101778246819055,0.134918217384128 + 0.01]
polyvar = polyval(p,goodrange);

%% Find SMI spikes
% did not understand quite what is going on here

% without spikes
SCALE = 1;
sigmanoiseSNPP = polyval(p,1:size(dnbdata,2));
af3 = single(wiener2(dnbdata,[3 3],SCALE*sigmanoiseSNPP));


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


% with spikes

sigmanoiseSNPP = polyval(p,1:size(dnbdata_2,2));
af3 = single(wiener2(dnbdata_2,[3 3],SCALE*sigmanoiseSNPP));

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

dsmimax_2 = zeros(ndnb,1);

for i = 1:size(dnbdata,2)
    dsmimax_2(i) = max(imgfiltSNPP(:,i));
end

%% Plot SMI

scrsz = get(0,'ScreenSize');
figure('Position',[1 scrsz(4)/2-50 scrsz(3) scrsz(4)/2],'Name','DNB variance');
subplot(1,2,1)
bar(dzsmimax)
hold on
plot(goodrange,polyvar,'Color', [0,0,0])

for i=1:32
    vline(ranges(2,i))                           
    vline(4064-ranges(2,i))
end

ylim([0,Y_scale])
xlabel('SNPP DNB sample')
ylabel('Max(SMI) by aggregation mode')

subplot(1,2,2)
plot(goodrange,dsmimax_2(goodrange))
hold on
plot(goodrange,dsmimax(goodrange))
hold on
plot(goodrange,polyvar, 'Color', [0,0,0])

for i=1:32
    vline(ranges(2,i))                           
    vline(4064-ranges(2,i))
end

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
%xlim([0 4000])
%ylim([-500 3000])
title('DNB after Wiener filter 20220430');
hold off

linkaxes([ax1, ax2])
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
plot(goodrange,polyvar,'Color', [0,0,0])
% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlabel('SNPP DNB sample')
ylabel('STD by aggregation mode')

subplot(1,2,2)
plot(dnbvar_2)
hold on
plot(dnbvar)
hold on
plot(goodrange,polyvar,'Color', [0,0,0])

for i=1:32
    vline(ranges(2,i))                           
    vline(4064-ranges(2,i))
end

% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlabel('SNPP DNB sample')
ylabel('STD by image column')