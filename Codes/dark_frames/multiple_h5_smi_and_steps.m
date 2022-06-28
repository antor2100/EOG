%%
function [] = multiple_h5()
    SMI = 0.095;
    n = input('How many files: ');
    %filenames = strings([1,n]);
    
    legends = [];
   
    figure 
    hold on
    
    for i = 1:n
        filename = input(['enter filename ' num2str(i) ': ']);
        type = input(['enter satellite type: ']);
        degree = input('enter degree: ');
        YMD = input('enter year month day: ');
        legends = [legends; YMD];
        
        if type == "SNPP"
            aggr = [...
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

            nz = size(aggr,1)*2;
            ranges = zeros(2,64);
            ranges(:,1) = [4064 - aggr(1,4) + 1, 4064];
            ranges(:,33) = [2032 - aggr(1,4) + 1, 2032];

            for j=2:32
                ranges(1,32 + j) = ranges(1,32 + j - 1) - aggr(j,4);
                ranges(2,32 + j) = ranges(1,32 + j - 1) - 1;

                ranges(1,34 - j) = 4064 - ranges(2,32 + j - 1) + 1;
                ranges(2,34 - j) = 4064 - ranges(1,32 + j - 1);
            end

        elseif type == "J01"
            aggr  = [...
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

            nz = size(aggr,1);
            ranges = zeros(2,nz);

            for j=1:nz
                ranges(1,j) = aggr(j,3) + 1;
                ranges(2,j) = aggr(j,4) + 1;
            end

        else
            disp('wrong satellite name');
        end  
        
        %% SNPP DNB day-night band

        % DNB radiance
        dnbdataset = '/All_Data/VIIRS-DNB-SDR_All/Radiance';

        dnbdata = viirs_get_data(filename, dnbdataset)' * 1e9;

        Y_scale = 0.5;
        
        %% Noise stats by agg zone
        zsigma = zeros(nz,1);
        ndnb = size(dnbdata,2);
        dzsigma = zeros(ndnb(1),1);

        for j = 1:nz
            zrange = ranges(1,j):ranges(2,j);
            dnbstripe = dnbdata(:,zrange);
            zsigma(j) = std(dnbstripe(:));
            dzsigma(zrange) = zsigma(j);
        end
        
        %% fit polynomial to the DNB variance
        dnbvar = zeros(ndnb,1);

        for j = 1:size(dnbdata,2)
             dnbvar(j) = std(dnbdata(:,j));
        end
        
        if type == "SNPP"
            goodrange = 1:4064;
        else 
            goodrange = 464:3327;
        end

        p = polyfit(double(goodrange),dnbvar(goodrange)',degree);
        polyvar = polyval(p,goodrange);
        
        sigmanoiseSNPP = polyval(p,1:4064);
        
        %%
        SCALE = 1;
        af3 = single(wiener2(dnbdata,[3 3],SCALE*sigmanoiseSNPP));
        %af3(:,1:464) = 0;
        % af3(:,3328:4064) = 0;

        %% Find SMI spikes
        % did not understand quite what is going on here

        imgmed = medfilt2(af3,[3 3]);
        imgfiltSNPP = (af3 - imgmed);

        zsmimax = zeros(ndnb,1);
        dzsmimax = zeros(ndnb,1);
        for j = 1:nz
            zrange = ranges(1,j):ranges(2,j);
            smistripe = imgfiltSNPP(:,zrange);
            zsmimax(j) = max(smistripe(:));
            dzsmimax(zrange) = zsmimax(j);
        end

        dsmimax = zeros(ndnb,1);

        for j = 1:size(dnbdata,2)
            dsmimax(j) = max(imgfiltSNPP(:,j));
        end

        plot(goodrange,dsmimax(goodrange), 'DisplayName', YMD)

        %plot(goodrange,polyvar,'LineWidth',1.0, 'DisplayName', strcat(YMD," Degree: ", string(degree)))
        
        %%
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

        %if true
            %imgfilt = freadenvi('./boat_aggregate_for_paper/SVDNB_npp_d20140927_t1834358_e1840162_b15115_c20140928004016952044_noaa_ops.boats.smi');  % find this file (might be on eogdrive, but Misha will share it with me)
            %slval = freadenvi('./boat_aggregate_for_paper/SVDNB_npp_d20140927_t1834358_e1840162_b15115_c20140928004016952044_noaa_ops.boats.lwmask'); % these files were processed from h5 file. lwmask is land something mask as 
                                                                                                                                                      % as there might be islands. So, we only use pixels that are in water.
            %scrsz = get(0,'ScreenSize');
            %figure('Position',[1 1 scrsz(3) scrsz(4)]);

            %[Line_DNB,Sample_DNB] = find(slval > 0);

            %plot(Sample_DNB,imgfilt(slval > 0),'.')

            hold on

            %plot(sigmanoiseSNPP*2,'g--','LineWidth',4,'DisplayName','Wiener Sigma')
            %plot(spikeThreshFix,'LineWidth',2,'DisplayName','SMI threshold')

            %for j=2:32
            %    vline(ranges(2,j))                                 % Misha will send me the code for vline function. it will just draw vertical lines.
            %    vline(4064-ranges(2,j))
            %end
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

            %set(gca,'fontsize',24)

        %     zoom on
        %end



    end
    
    %% for loop ends
    hold off
    
    ylim([0,Y_scale])
    xlabel('SNPP DNB sample')
    ylabel('SMI by image column')
    
    for j=2:32
        vline(ranges(2,j))                                 % Misha will send me the code for vline function. it will just draw vertical lines.
        vline(4064-ranges(2,j))
    end
    
    [~, hobj, ~, ~] = legend(legends, 'NumColumns',2)
    hl = findobj(hobj,'type','line');
    set(hl,'LineWidth',2);
    
end
    
    
    
