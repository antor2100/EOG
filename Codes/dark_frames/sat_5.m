%%
function [p_1] = sat_5()
    
    n = input('How many files: ');
    
       
    figure 
    hold on
    
    for j = 1:n
        type = input(['enter satellite type: ']);
        name = input(['enter filename ' num2str(j) ': ']);
        degree = input('enter degree: ');

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
            ranges(:,1) = [4063 - aggr(1,4) + 1, 4063];
            ranges(:,33) = [2032 - aggr(1,4) + 1, 2032];

            for i=2:32
                ranges(1,32 + i) = ranges(1,32 + i - 1) - aggr(i,4);
                ranges(2,32 + i) = ranges(1,32 + i - 1) - 1;

                ranges(1,34 - i) = 4064 - ranges(2,32 + i - 1) + 1;
                ranges(2,34 - i) = 4064 - ranges(1,32 + i - 1);
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

            for i=1:nz
                ranges(1,i) = aggr(i,3) + 1;
                ranges(2,i) = aggr(i,4) + 1;
            end

        else
            disp('wrong satellite name');
        end

        %% SNPP DNB day-night band
        dnbfile_1 = name; % coordiate: 47.558231	177.357147

        % DNB radiance
        dnbdataset_1 = '/All_Data/VIIRS-DNB-SDR_All/Radiance';

        dnbdata_1 = viirs_get_data(dnbfile_1, dnbdataset_1)' * 1e9;
        
        dnbdata_1(:,1) = [];
        
        %% Create another array with spikes removed

        dnbdata_2 = dnbdata_1;

        m = mean(mean(dnbdata_2));
        flag = 1;
        k = 1;

        goodrange = 1:4063;
        goodrange_2 = goodrange;

        while k <= size(dnbdata_2,2)
            i = 1;
            while i <= size(dnbdata_2,1)
                if dnbdata_2(i,k) > m + 1
                    dnbdata_2(:,k) = [];
                    goodrange_2(k) = [];
                    flag = 0;
                    break;

                else
                    i = i + 1;
                    flag = 1;
                end
            end

            if flag == 1
                k = k + 1;
            end

        end

        %% Noise stats by agg zone
        zsigma = zeros(nz,1);
        ndnb = size(dnbdata_1,2);
        dzsigma_1 = zeros(ndnb,1);

        for i = 1:nz
            zrange = ranges(1,i):ranges(2,i);
            dnbstripe = dnbdata_1(:,zrange);
            zsigma(i) = std(dnbstripe(:));
            dzsigma_1(zrange) = zsigma(i);
        end

        %% fit polynomial to the DNB variance

        dnbvar_1 = zeros(ndnb,1);

        for i = 1:size(dnbdata_1,2)
            dnbvar_1(i) = std(dnbdata_1(:,i));   
        end

        dnbvar_2 = zeros(ndnb,1);

        for i = 1:size(dnbdata_2,2)
            dnbvar_2(i) = std(dnbdata_2(:,i));   
        end

        goodrange_3 = 1:size(dnbdata_2,2);

        p_1 = polyfit(double(goodrange_2),dnbvar_2(goodrange_3)',3);

        polyvar_1 = polyval(p_1,goodrange);
        
        opts = detectImportOptions('polynomials_3.csv','NumHeaderLines',0);
        output = readtable('polynomials_3.csv', opts);
        disp(output)

        coeff = "";

        for i = 2:(degree+1)
            coeff = strcat(coeff, string(p_1(i)), "; ");
        end

        name = split(name,"/");
        name = split(name(size(name,1)),"_");
        YMD = extractAfter(name(3),1);
        YMD = str2double(YMD);

        id = strcat(name(6), "_", name(7));

        row = {type, YMD, name(4), name(5), id, degree, coeff, 0};
        output = [output; row];
        writetable(output, 'polynomials_3.csv')
        
        
        p_1 = polyfit(double(goodrange),dnbvar_1(goodrange)',2);

        %output = readtable('polynomials_2.csv', 'PreserveVariableNames',true);

        %% plot STD

        plot(dnbvar_1)
        hold on
        plot(goodrange,polyvar_1,'LineWidth',1.0)
        hold on
        
    end
    
        
    %% for loop ends
    hold off
    
    xlabel('SNPP DNB sample')
    ylabel('STD by image column')
    xlim([0,4063])
    ylim([0,1.2])
    %legends = {'Line 1','','Line 3'};
    for j=2:32
        vline(ranges(2,j))                                 % Misha will send me the code for vline function. it will just draw vertical lines.
        vline(4063-ranges(2,j))
    end
    
    %[~, hobj, ~, ~] = legend(legends, 'NumColumns',2)
    %hl = findobj(hobj,'type','line');
    %set(hl,'LineWidth',2);
  
end