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
dnbfile_1 = 'SVDNB_npp_d20220430_t1334313_e1335555_b54440_c20220430150901529459_oebc_ops.h5';
h5_1 = '20220430';
% DNB radiance
dnbdataset_1 = '/All_Data/VIIRS-DNB-SDR_All/Radiance';

dnbfile_2 = 'for_misha/SVDNB_npp_d20141122_t1229070_e1234474_b15906_c20141122183448309762_noaa_ops.h5';
h5_2 = '20141122';

% DNB radiance
dnbdataset_2 = '/All_Data/VIIRS-DNB-SDR_All/Radiance';

dnbdata_1 = viirs_get_data(dnbfile_1, dnbdataset_1)' * 1e9;
dnbdata_2 = viirs_get_data(dnbfile_2, dnbdataset_2)' * 1e9;

Y_scale = 0.5;

disp(class(dnbdata_1));
disp(dnbdata_1(1));

figure()
histogram(dnbdata_1,50,'Normalization','probability', 'Binlimits',[-1,1])
hold on
histogram(dnbdata_2,50,'Normalization','probability', 'Binlimits',[-1,1])
legend(h5_1, h5_2)
xlabel('Radiance')
ylabel('Normalized Frequency')
%% Noise stats by agg zone
zsigma = zeros(nzSNPP,1);
ndnb = [size(dnbdata_1,2) size(dnbdata_2,2)];
dzsigma_1 = zeros(ndnb(1),1);
dzsigma_2 = zeros(ndnb(2),1);

for i = 1:nzSNPP
    zrange = ranges(1,i):ranges(2,i);
    dnbstripe = dnbdata_1(:,zrange);
    zsigma(i) = std(dnbstripe(:));
    dzsigma_1(zrange) = zsigma(i);
end

for i = 1:nzSNPP
    zrange = ranges(1,i):ranges(2,i);
    dnbstripe = dnbdata_2(:,zrange);
    zsigma(i) = std(dnbstripe(:));
    dzsigma_2(zrange) = zsigma(i);
end

%% fit polynomial to the DNB variance
dnbvar_1 = zeros(ndnb(1),1);
dnbvar_2 = zeros(ndnb(2),1);

for i = 1:size(dnbdata_1,2)
     dnbvar_1(i) = std(dnbdata_1(:,i));
end

for i = 1:size(dnbdata_2,2)
     dnbvar_2(i) = std(dnbdata_2(:,i));
end

goodrange = 1:4064;
size(goodrange)
size(dnbvar_1(goodrange))

degree_1 = 3;
p_1 = polyfit(double(goodrange),dnbvar_1(goodrange)',degree_1)
polyvar_1 = polyval(p_1,goodrange);

degree_2 = 7;
p_2 = polyfit(double(goodrange),dnbvar_2(goodrange)',degree_2)
polyvar_2 = polyval(p_2,goodrange);

%%

% why is dzsigma half width but dnbvar is full width

scrsz = get(0,'ScreenSize');
figure('Position',[1 scrsz(4)/2-50 scrsz(3) scrsz(4)/2],'Name','DNB variance');
subplot(1,2,1)
bar(dzsigma_1)
hold on
bar(dzsigma_2)
hold on
plot(goodrange,polyvar_1, 'g', 'LineWidth',2.0)
hold on
plot(goodrange,polyvar_2,'LineWidth',2.0)

ylim([0,Y_scale])
xlabel('SNPP DNB sample')
ylabel('STD by aggregation mode')
legend(strcat(h5_1," Degree: ", string(degree_1)), strcat(h5_2," Degree: ", string(degree_2)))

subplot(1,2,2)
plot(dnbvar_1,'g')
hold on
plot(dnbvar_2, 'b')
hold on
plot(goodrange,polyvar_1,'r','LineWidth',2.0)
hold on
plot(goodrange,polyvar_2,'LineWidth',2.0)
ylim([0,Y_scale])
xlabel('SNPP DNB sample')
ylabel('STD by image column')
legend(strcat(h5_1," Degree: ", string(degree_1)), strcat(h5_2," Degree: ", string(degree_2)))
