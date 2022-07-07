clear all
close all

SMI = 0.2;

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

dnbfile = 'Data/for_antor/june2022_anomaly/SVDNB_npp_d20220629_t1311331_e1312573_b55291_c20220629144840135289_oebc_ops.h5';

% DNB radiance
dnbdataset = '/All_Data/VIIRS-DNB-SDR_All/Radiance';
dnbdata = viirs_get_data(dnbfile, dnbdataset)' * 1e9;

m = mean(mean(dnbdata));

dnbdata(:,1) = m*ones(size(dnbdata,1),1);

Y_scale = 0.5;

figure()
histogram(dnbdata(:),50,'Binlimits',[-1,1])

%% Create another array with spikes removed

dnbdata_2 = dnbdata;

a = 224;
b = 3840;
trimmed_range = a:b;
%dnbdata_2 = dnbdata_2(trimmed_range);
dnbdata_2(:,1:a-1) = [];

dnbdata_2(:,(b+2-a):size(dnbdata_2,2)) = [];

m = mean(mean(dnbdata_2));

flag = 1;
j = 1;

goodrange = 1:4064;


goodrange_2 = trimmed_range;
%goodrange_2= goodrange;

while j <= size(dnbdata_2,2)
    i = 1;
    while i <= size(dnbdata_2,1)
        if dnbdata_2(i,j) > m + 1
            dnbdata_2(:,j) = [];
            goodrange_2(j) = [];
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

dnbvar = zeros(ndnb,1);

for i = 1:size(dnbdata,2)
    dnbvar(i) = std(dnbdata(:,i));   
end

dnbvar_2 = zeros(size(dnbdata_2,2),1);

for i = 1:size(dnbdata_2,2)
    dnbvar_2(i) = std(dnbdata_2(:,i));   
end

goodrange_3 = 1:size(dnbdata_2,2);

degree = 3;

p = polyfit(double(goodrange_2),dnbvar_2(goodrange_3)',degree);

polyvar = polyval(p,goodrange);

sigmanoiseSNPP = polyval(p,goodrange);

%% Find SMI spikes
% did not understand quite what is going on here

% with spikes
SCALE = 1;
af3 = single(wiener2(dnbdata,[3 3],SCALE*sigmanoiseSNPP));
af3(:,1:a) = 0;          % do not detect boats at the outskirts
af3(:,b:4064) = 0;      % do not detect boats at the outskirts

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

%% Plot SMI

scrsz = get(0,'ScreenSize');
figure('Position',[1 scrsz(4)/2-50 scrsz(3) scrsz(4)/2],'Name','DNB variance');

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

scrsz = get(0,'ScreenSize');
figure('Position',[1 scrsz(4)/2-50 scrsz(3) scrsz(4)/2],'Name','DNB variance');
legends = {};

plot(goodrange,dsmimax(goodrange))
legends{end+1} = 'SMI';
hold on
plot(goodrange,polyvar, 'Color', 'g')
legends{end+1} = 'polynomial';

for i=1:32
    vline(ranges(2,i)) 
    legends{end+1} = '';
    vline(4064-ranges(2,i))
    legends{end+1} = '';
end


hold on

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

hold on

plot(spikeThreshFix,'LineWidth',2,'DisplayName','SMI threshold')
legends{end+1} = 'step function';

%ylim([0,3.5])
xlim([0,4064])
%ylim([0,1.5])
xlabel('SNPP DNB sample')
ylabel('Max(SMI) by column')

a=sprintf('%.2f',SMI);
title(strcat('File: 20220629_t1320056_e1321297_b55291_c20220629144927620536, SMI: ', string(SMI), ' Degree: ', string(degree)))

%[~, hobj, ~, ~] = legend(legends, 'NumColumns',2)
%hl = findobj(hobj,'type','line');
%set(hl,'LineWidth',2);
    

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
plot(dnbvar)
hold on
plot(goodrange,polyvar,'Color', [0,0,0])

for i=1:32
    vline(ranges(2,i))                           
    vline(4064-ranges(2,i))
end

% plot(goodrange,polyvar+delta,'r.')
ylim([0,Y_scale])
xlim([0,4064])
ylim([0,1.2])
xlabel('SNPP DNB sample')
ylabel('STD by image column')