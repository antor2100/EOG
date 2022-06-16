function varargout = viirs_aurora(fileDNB, varargin)

[OUTPUT, PLOT, DUMP, METADATA, SOFT_LIGHTNING_LENGTH, XTRA] = ...
    process_options(varargin,'-output','','-plot',0,'-dump',0,'-meta',0,'-lightning',24);
%     process_options(varargin,'-output','','-plot',0,'-dump',0,'-meta',0,'-lightning',8);

global FILLVALUE;
global MISSINGVALUE;

%% Memory monitor
rtime = java.lang.Runtime.getRuntime;
usedMemory = rtime.totalMemory - rtime.freeMemory
tmemprof(1).mem = usedMemory;
tmemprof(1).time = 0;
tmemprof(1).step = 'init';
stepnum = 1;

varargout{1} = 0;

%%
helpind = strmatch('-h',XTRA)
nargin
if ~isempty(helpind) && helpind > 0 || nargin < 1
    disp('Matlab script "viirs_aurora" has to be called with the following command line parameters:');
    disp('    (required)');
    disp('fileDNB               - name of the input file list or a single SVNDB file in HDF5 format (SVDNB*.h5)');
    disp('-output <dir name>   - output directory nane, will be derived from the fileDNB name if missing');
    disp('-plot 0/1             - plot SI, SMI, SHI, lightning and boat detections (requires X-Windows), default value is 0');
    disp('-dump 0/1             - save SI, SMI, SHI and lightning detections as ENVI images, default value is 0');
    disp('-meta 0/1             - output one-line CSV with the processing metadata, default value is 0');
    disp('-lightning <number>   - lightning detector threshold (default value is -1)');
    disp('--force               - if present, disregard the NPP satellite mode (default is check for operational)');
    disp('-h                    - displays this help screen');
    return
end

boats_version = '23';
disp(['Detection ver. ',boats_version,' with threshols STREAK_LENGTH=',num2str(SOFT_LIGHTNING_LENGTH)]);

FILLVALUE = 999999;
MISSINGVALUE = -999.3;

useI05 = true;

LIGHTNING_THR = -1.0;
AURORA_THR = -1.5;
% STREAK_THR = -1.75;
% STREAK_LENGTH = 12;

straylightmask = int16(2^7);

forceFlag = false;
nextra = length(XTRA);
for i = 1:nextra
    char(XTRA{i});
    if strmatch('--force', strtrim(char(XTRA{i})))
        warning(['Using force mode, no exit on errors']);
        forceFlag = true;
    end
end

dumpFlag = DUMP;
disp(['Dump intermediate data into ENVI files: ',num2str(dumpFlag)]);

metaFlag = METADATA;
disp(['Dump detection metadata into CSV file: ',num2str(metaFlag)]);

visFlag = PLOT;
disp(['Interactive plots: ',num2str(visFlag)]);

tic

%% DNB image list

outdir = '.';
[infile_pathstr, infile_name, infile_ext] = fileparts(fileDNB);
if isempty(OUTPUT)
    outdir = infile_pathstr;
    outfile = fullfile(outdir,strcat(infile_name,'.boats'));
    warning(['Using default debug file names ',outfile]);
else
    outdir = OUTPUT;
    outfile = fullfile(outdir,strcat(infile_name,'.boats'));
    disp(['Debug file names ',outfile]);
end

dnbmap = containers.Map();
llmap = containers.Map();
lltcmap = containers.Map();
if ~isempty(fileDNB)
    if strcmp('.h5',infile_ext)
        fnames = textscan(fileDNB,'%s');
    else
        fid = fopen(fileDNB);
        fnames = textscan(fid,'%s');
        fclose(fid);
    end
    nnames = cellfun(@length,fnames);

    useGDTCN = false;   
    for nf = 1:nnames
        gname = char(fnames{1}{nf});
        [pathstr, name, ext] = fileparts(gname);
        gparts = strread(name, '%s', 'delimiter', '_');
        compart = char(strcat(gparts(2),'_',gparts(3),'_',gparts(4),'_',gparts(5),'_',gparts(6)));
        [granFrom, granTo] = fname2dates(name);
        fprintf('Info: Granule #%d dates %s to %s\n', nf, datestr(granFrom), datestr(granTo));
        dnbmap(compart) = gname;

        prefix = 'GDNBO';
        llname = viirs_recent_file(pathstr,prefix,compart);
        llmap(compart) = llname;

        prefix = 'GDTCN';
        lltcname = viirs_recent_file(pathstr,prefix,compart);
        if useGDTCN || ~isempty(lltcname)
            useGDTCN = true;
            lltcmap(compart) = lltcname;
            % disp(['Found GDTCN file ', lltcname])
        else
            lltcmap(compart) = llname;
        end
    end
else
    error('Empty input file name, nothing to process');
end

%% Check for operational mode
opModeDataset = '/Data_Products/VIIRS-DNB-GEO';
opModeAttr = 'Operational_Mode';
grannames = llmap.values();
try
    gname = char(grannames(1));
    opMode = h5readatt(gname, opModeDataset, opModeAttr);
catch
    error('Missing GDNBO file')
end
% opMode = h5readatt(lldnbfile, opModeDataset, opModeAttr);

if ~strncmp(char(opMode),'NPP Normal Operations, VIIRS Operational ',20)
    warning(strcat('NPP satellite in wrong operational mode = ', char(opMode)));
    if ~forceFlag
        varargout{1} = 42;
        return
    end
end

%%
datasetDNB = '/All_Data/VIIRS-DNB-SDR_All/Radiance';

try
    imageDNB = viirs_aggregate_granules_simple(dnbmap, datasetDNB)' * 1e9;
catch
    error('Missing SVDNB file')
end

realDNB = imageDNB > MISSINGVALUE;
stretchDNB = stretch(imageDNB);

% copy DNB image and join the leap scans before sunlit masking for blur processing
testcol = max(imageDNB,[],2);
noleapscans = find(testcol > -999.25 | testcol < -999.35);
imageDNB1 = stretch(imageDNB(noleapscans,:));

qf2dataset = 'All_Data/VIIRS-DNB-SDR_All/QF2_SCAN_SDR';
qf2 = viirs_aggregate_granules_simple(dnbmap, qf2dataset);

% size(qf2)
straylight = real(bitand(uint16(qf2),uint16(straylightmask)) > 0);
slightimg = repmat(kron(straylight,ones(1,16))',1,size(imageDNB,2));
% size(slightimg)

clear straylight qf2

satName = strtrim(viirs_get_attr(char(fnames{1}{nf}), '/','Platform_Short_Name'));

if ~useGDTCN
    dnbLATdataset = '/All_Data/VIIRS-DNB-GEO_All/Latitude_TC';
    dnbLONdataset = '/All_Data/VIIRS-DNB-GEO_All/Longitude_TC';
    disp('Using geolocation from GDNBO file')
else
    dnbLATdataset = '/All_Data/VIIRS-DNB-GEO-TC_All/Latitude';
    dnbLONdataset = '/All_Data/VIIRS-DNB-GEO-TC_All/Longitude';
%     dnbLATdataset = '/All_Data/VIIRS-DNB-GEO_All/Latitude';
%     dnbLONdataset = '/All_Data/VIIRS-DNB-GEO_All/Longitude';
    disp('Using geolocation from GDTCN file')
end

midtimedataset = '/All_Data/VIIRS-DNB-GEO_All/MidTime';                 % 1x192

solarazimuthdataset = '/All_Data/VIIRS-DNB-GEO_All/SolarAzimuthAngle';
solarzenithdataset = '/All_Data/VIIRS-DNB-GEO_All/SolarZenithAngle';

lunarazimuthdataset = '/All_Data/VIIRS-DNB-GEO_All/LunarAzimuthAngle';
lunarzenithdataset = '/All_Data/VIIRS-DNB-GEO_All/LunarZenithAngle';

satellitezenithdataset = '/All_Data/VIIRS-DNB-GEO_All/SatelliteZenithAngle';
satelliteazimuthdataset = '/All_Data/VIIRS-DNB-GEO_All/SatelliteAzimuthAngle';

try
    dnblats = viirs_aggregate_granules_simple(lltcmap, dnbLATdataset)';
    dnblons = viirs_aggregate_granules_simple(lltcmap, dnbLONdataset)';
catch
    error('Missing GDTCN or GDNBO file')
end

date1958 = datenum(1958, 1, 1);
try
    midtime = date1958 + double(viirs_aggregate_granules_simple(llmap, midtimedataset))/1000/1000/60/60/24;
catch
    error('Missing GDNBO file')
end

solarzenithdata = viirs_aggregate_granules_simple(llmap, solarzenithdataset)';
solarazimuthdata = viirs_aggregate_granules_simple(llmap, solarazimuthdataset)';

satellitezenithdata = viirs_aggregate_granules_simple(llmap, satellitezenithdataset)';
satelliteazimuthdata = viirs_aggregate_granules_simple(llmap, satelliteazimuthdataset)';

lunarzenithdata = viirs_aggregate_granules_simple(llmap, lunarzenithdataset)';
lunarazimuthdata = viirs_aggregate_granules_simple(llmap, lunarazimuthdataset)';

% sunlit = find (solarzenithdata < 105 & solarzenithdata > -999);
sunlit = find (solarzenithdata < 101 & solarzenithdata > -999);
imageDNB(sunlit) = 0;
stretchDNB(sunlit) = 0;
% ignore noisy edges
% stretchDNB(:,1:226) = 0;
% stretchDNB(:,3841:end) = 0;

%% check for day-night mode error
[dnblines, dnbcols] = size(imageDNB);
granedges = 0:dnblines/nnames:dnblines;

daynightDataset = '/Data_Products/VIIRS-DNB-SDR/VIIRS-DNB-SDR_Gran_0';
daynightAttr = 'N_Day_Night_Flag';
grannames = dnbmap.values();

ntdata = false;
for i = 1:nnames
    gname = char(grannames(i))
    daynight = deblank(char(h5readatt(gname, daynightDataset, daynightAttr)));
    if strncmp(daynight,'Day',3)
        warning(['NPP satellite Day_Night_Flag = ', daynight,' in granule ',gname]);
        imageDNB(granedges(i)+1:granedges(i+1),:) = 0;
        stretchDNB(granedges(i)+1:granedges(i+1),:) = 0;
    else
        ntdata = true;
    end
end
if ~ntdata && ~forceFlag
    varargout{1} = 42;
    return
end

%% MRB and Corners of the 5 min granula
dls = find(dnblats(:,1) > -999); % index all non-missing scan lines
ndls = length(dls);
ngranlines = 48 * 16; % 48 scanlines for VIIRS

granuleMode = true;
if ndls > ngranlines
    granuleMode = false;
end

cross180 = false;
if granuleMode
    disp('Granule mode')
    bounds = zeros(6,2);
    
    bounds(1,1) = dnblats(dls(1),1);
    bounds(1,2) = dnblons(dls(1),1);
    bounds(2,1) = dnblats(dls(1),round(dnbcols/2));
    bounds(2,2) = dnblons(dls(1),round(dnbcols/2));
    bounds(3,1) = dnblats(dls(1),dnbcols);
    bounds(3,2) = dnblons(dls(1),dnbcols);
    bounds(4,1) = dnblats(dls(end),dnbcols);
    bounds(4,2) = dnblons(dls(end),dnbcols);
    bounds(5,1) = dnblats(dls(end),round(dnbcols/2));
    bounds(5,2) = dnblons(dls(end),round(dnbcols/2));
    bounds(6,1) = dnblats(dls(end),1);
    bounds(6,2) = dnblons(dls(end),1);
    
    triangle1 = [bounds([1,4,6],2),bounds([1,4,6],1)];
    triangle2 = [bounds([1,3,4],2),bounds([1,3,4],1)];    
else
    ngrans = ceil(ndls / ngranlines); % number of granules in the aggregate
    disp(['Aggregate mode with ',num2str(ngrans),' granules'])
    
    bounds = zeros(6 + (ngrans-1) * 2,2); % 3 top line, 2 * (ngrans-1) on the sides, 3 bottom line
    
    bounds(1,1) = dnblats(dls(1),1); % top line
    bounds(1,2) = dnblons(dls(1),1);
    bounds(2,1) = dnblats(dls(1),round(dnbcols/2));
    bounds(2,2) = dnblons(dls(1),round(dnbcols/2));
    bounds(3,1) = dnblats(dls(1),dnbcols);
    bounds(3,2) = dnblons(dls(1),dnbcols);
    
    for ngr = 1:ngrans-1 %  right side
        bounds(3 + ngr,1) = dnblats(dls(round(ngr * ndls / ngrans)),dnbcols);
        bounds(3 + ngr,2) = dnblons(dls(round(ngr * ndls / ngrans)),dnbcols);
    end
    
    bounds(3 + ngrans,1) = dnblats(dls(end),dnbcols); % bottom line
    bounds(3 + ngrans,2) = dnblons(dls(end),dnbcols);
    bounds(4 + ngrans,1) = dnblats(dls(end),round(dnbcols/2));
    bounds(4 + ngrans,2) = dnblons(dls(end),round(dnbcols/2));
    bounds(5 + ngrans,1) = dnblats(dls(end),1);
    bounds(5 + ngrans,2) = dnblons(dls(end),1);
    
    for ngr = 1:ngrans-1 %  left side
        bounds(5 + ngrans + ngr,1) = dnblats(dls(round((ngrans - ngr) * ndls / ngrans)),1);
        bounds(5 + ngrans + ngr,2) = dnblons(dls(round((ngrans - ngr) * ndls / ngrans)),1);
    end
    
    triangle1 = [bounds([1,3 + ngrans,5 + ngrans],2),bounds([1,3 + ngrans,5 + ngrans],1)];
    triangle2 = [bounds([1,3,3 + ngrans],2),bounds([1,3,3 + ngrans],1)];
end

minDNBlon = min(dnblons(dnblons > -999));
maxDNBlon = max(dnblons(dnblons > -999));

% if true
if minDNBlon > maxDNBlon
    maxDNBlon = maxDNBlon + 360
    cross180 = true;
    warning('Aggregate is crossing 180 longitude');
end

minDNBlat = min(dnblats(dnblats > -999));
maxDNBlat = max(dnblats(dnblats > -999));

corners1 = convertdms(triangle1,'d','r');
corners2 = convertdms(triangle2,'d','r');

poles = [0,0;-90,90]';
positions = convertdms(poles,'d','r');
inflag=max(in_polysphere(positions,corners1),...
    in_polysphere(positions,corners2));

if inflag(1)
    warning('Aggregate is above the North Pole');
    maxDNBlat = 90;
elseif inflag(2)
    warning('Aggregate is above the South Pole');
    minDNBlat = -90;
end

disp('DNB input read')
usedTime = toc
usedMemory = rtime.totalMemory - rtime.freeMemory
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'dnb';

if dumpFlag
    info=enviinfo(stretchDNB);
    enviwrite(stretchDNB,info,[outfile '.stretch_dnb']);
end

if false
%% straylight streak detector
[nr,nc] = size(imageDNB);
streakDNB = zeros(size(imageDNB));
prodDNB1 = zeros(size(imageDNB));
prodDNB2 = zeros(size(imageDNB));

disp_progress; % Just to show progress

for ii = 2:1:nr-1

    disp_progress(ii, nr-2);
    
    if (ii == 1) || max(slightimg(ii,:)) == 0 || (max(imageDNB(ii-1,:)) <= MISSINGVALUE) || (max(imageDNB(ii,:)) <= MISSINGVALUE)
        prodline1 = zeros(size(imageDNB(ii,:)));
    else
        prodline1 = max(0,(stretchDNB(ii,:) - stretchDNB(ii-1,:))./stretchDNB(ii-1,:));
        if ~isreal(log10(prodline1))
            warning('log10 prodline1 is not real')
        end
    end
    
    if ii == nr-1 || max(slightimg(ii,:)) == 0 || max(imageDNB(ii,:)) <= MISSINGVALUE || max(imageDNB(ii+1,:)) <= MISSINGVALUE
        prodline2 = zeros(size(imageDNB(ii,:)));
    else
        prodline2 = max(0,(stretchDNB(ii,:) - stretchDNB(ii+1,:))./stretchDNB(ii+1,:));
        if ~isreal(log10(prodline2))
            warning('log10 prodline2 is not real')
        end
    end
    
    thrline = log10(prodline1) > STREAK_THR & log10(prodline2) > STREAK_THR ;
    
    bb = regionprops(thrline,'Boundingbox');
    bblbl = bwlabel(thrline);
    numberOfBlobs = length(bb);
    bbx = zeros(numberOfBlobs,1);
    lout = zeros(size(bblbl));
    for k = 1 : numberOfBlobs           % Loop through all blobs.
        % Find the bounding box of each blob.
        bbox = bb(k).BoundingBox;
        bbx(k) = bbox(3);
        if bbx(k) > STREAK_LENGTH
            lout = max(lout, (bblbl == k) * bbx(k));
        end
    end
    
    se = strel('line',STREAK_LENGTH*4,0);
    lout = imdilate(lout,se);
        
    % add short segments at the edges of the dilated "core" if they touch it
    for k = 1 : numberOfBlobs           % Loop through all blobs.
        lsegm = bblbl == k;
        if sum(lsegm & lout) > 0
%             lout = lout | lsegm;
            llength = max((lsegm & lout) .* lout);
            lout = (lout | lsegm) * llength;
        end
    end
    
    streakDNB(ii,:) = lout;
    
    prodDNB1(ii,:) = log10(prodline1)>STREAK_THR;
    prodDNB2(ii,:) = log10(prodline2)>STREAK_THR;
end

%% 
if visFlag
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','Straylight detector');
    
    subplot(2,2,1)
    image(stretchDNB*40)
    axis image
    colormap('gray');
    title('Input DNB image');
    freezeColors;
    
    subplot(2,2,2)
    imagesc(streakDNB > 0)
    colormap('gray');
    axis image
    title('Straylight detections');
    freezeColors;
    
    dtctrgb = zeros(size(stretchDNB,1),size(stretchDNB,2),3);
    dtctrgb(:,:,1) = min(stretchDNB*0.7,ones(size(stretchDNB)));
    dtctrgb(:,:,2) = min(stretchDNB*0.7,ones(size(stretchDNB))).*~streakDNB;
    dtctrgb(:,:,3) = min(stretchDNB*0.7,ones(size(stretchDNB)));
    
    subplot(2,2,3)
    image(dtctrgb)
    axis image
    colormap('gray');
    title('Detector and DNB image overlay');
    freezeColors;
    
    prodrgb = zeros(size(stretchDNB,1),size(stretchDNB,2),3);
    prodrgb(:,:,1) = prodDNB1;
    prodrgb(:,:,2) = prodDNB1;
    prodrgb(:,:,3) = prodDNB2;
    
    subplot(2,2,4)
    image(prodrgb)
    axis image
    colormap('gray');
    title('Scan edges');
    freezeColors;
    
    linkaxes
    zoom on
end

clear prodDNB1 prodDNB2 prodrgb dtctrgb

if dumpFlag
    info=enviinfo(single(streakDNB));
    enviwrite(single(streakDNB),info,[outfile '.streaks']);
    %     info=enviinfo(prodDNB1);
    %     enviwrite(prodDNB1,info,[outfile '.lightning_prod1']);
    %     info=enviinfo(prodDNB2);
    %     enviwrite(prodDNB2,info,[outfile '.lightning_prod2']);
end

disp('Streak detector')
usedTime = toc
usedMemory = rtime.totalMemory - rtime.freeMemory
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'streaks';

end

%% Aurora detector
LIGHTNING_LENGTH = 8;
if SOFT_LIGHTNING_LENGTH > LIGHTNING_LENGTH || SOFT_LIGHTNING_LENGTH < 2
    SOFT_LIGHTNING_LENGTH = LIGHTNING_LENGTH;
end

[nr,nc] = size(imageDNB);
austreakDNB = zeros(size(imageDNB));
prodDNB1 = zeros(size(imageDNB));
prodDNB2 = zeros(size(imageDNB));
stepDNB = zeros(size(imageDNB));
blobvalues = [];
bloblength = [];
blobpos = [];
blobcount = 0;

disp_progress; % Just to show progress

for ii = 1:16:nr-15
    
    disp_progress(ii, nr-2);
    
    if ii == 1 || max(imageDNB(ii-1,:)) <= MISSINGVALUE || max(imageDNB(ii,:)) <= MISSINGVALUE
        prodline1 = zeros(size(imageDNB(ii,:)));
    else
        prodline1 = max(0,(stretchDNB(ii,:) - stretchDNB(ii-1,:))./stretchDNB(ii-1,:));
        if ~isreal(log10(prodline1))
            warning('log10 prodline1 is not real')
        end
    end
    
    if ii == nr-15 || max(imageDNB(ii+15,:)) <= MISSINGVALUE || max(imageDNB(ii+16,:)) <= MISSINGVALUE
        prodline2 = zeros(size(imageDNB(ii,:)));

    else
        prodline2 = max(0,(stretchDNB(ii+15,:) - stretchDNB(ii+16,:))./stretchDNB(ii+16,:));
        if ~isreal(log10(prodline2))
            warning('log10 prodline2 is not real')
        end
    end
    
    thrline = log10(prodline1) > AURORA_THR;
    streakline = austreakDNB(ii,:);
    
    bb = regionprops(thrline,log10(prodline1),'Boundingbox','MaxIntensity');
    bblbl = bwlabel(thrline);
    numberOfBlobs = length(bb);
    bbx = zeros(numberOfBlobs,1);
    lout = zeros(size(bblbl));
    for k = 1 : numberOfBlobs           % Loop through all blobs.
        % Find the bounding box of each blob.
        bbox = bb(k).BoundingBox;
        bbx(k) = bbox(3);
        if bbx(k) > SOFT_LIGHTNING_LENGTH && sum((bblbl == k) .* streakline) == 0
            lout = max(lout, (bblbl == k) * bbx(k));
            blobcount = blobcount + 1;
            blobvalues(blobcount) = bb(k).MaxIntensity;
            bloblength(blobcount) = bbx(k);
            blobpos(blobcount) = bbox(1);
        end
    end
    
    thrline = log10(prodline2) > AURORA_THR;
    streakline = austreakDNB(ii+15,:);
    
    bb = regionprops(thrline,log10(prodline2),'Boundingbox','MaxIntensity');
    bblbl = bwlabel(thrline);
    numberOfBlobs = length(bb);
    bbx = zeros(numberOfBlobs,1);
    for k = 1 : numberOfBlobs           % Loop through all blobs.
        % Find the bounding box of each blob.
        bbox = bb(k).BoundingBox;
        bbx(k) = bbox(3);
        if bbx(k) > SOFT_LIGHTNING_LENGTH && sum((bblbl == k) .* streakline) == 0
            lout = max(lout, (bblbl == k) * bbx(k));
            blobcount = blobcount + 1;
            blobvalues(blobcount) = bb(k).MaxIntensity;
            bloblength(blobcount) = bbx(k);
            blobpos(blobcount) = bbox(1);
        end
    end

%     se = strel('line',LENGTH*2,0);
    se = strel('line',SOFT_LIGHTNING_LENGTH*4,0);
    lout = imdilate(lout,se);
        
%     % add short segments at the edges of the dilated "core" if they touch it
%     for k = 1 : numberOfBlobs           % Loop through all blobs.
%         lsegm = bblbl == k;
%         if sum(lsegm & lout) > 0
% %             lout = lout | lsegm;
%             llength = max((lsegm & lout) .* lout);
%             lout = (lout | lsegm) * llength;
%         end
%     end
    
    austreakDNB(ii:ii+15,:) = repmat(lout,16,1);
    
    prodDNB1(ii:ii+15,:) = repmat(log10(prodline1)>LIGHTNING_THR,16,1);
    prodDNB2(ii:ii+15,:) = repmat(log10(prodline2)>LIGHTNING_THR,16,1);
    
    stepDNB(ii:ii+15,:) = repmat(max(log10(prodline1),log10(prodline2)),16,1);
end

%% Mask glint specle detections only inside probable ellipse
% size(glintDNB)
% size(glint_map)
% glintDNB = glintDNB .* glint_map;

%% Check for single track hot spots
CC = bwconncomp(austreakDNB);
S = regionprops(CC,'BoundingBox','PixelIdxList');
bbox = cat(1, S.BoundingBox);
if size(bbox,1) > 0
    singleidx = find(bbox(:,4) == 16);
    % glintDNB(CC.PixelIdxList{singleidx}) = 0;
    for i = 1:length(singleidx)
       austreakDNB(CC.PixelIdxList{singleidx(i)}) = 0;
    end
    austreakDNB = imfill(austreakDNB,'holes');
end

if dumpFlag
    info=enviinfo(uint8(austreakDNB));
    enviwrite(uint8(austreakDNB),info,[outfile '.streak_dnb']);
end

if false
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 1 scrsz(3) scrsz(4)]);

    subplot(2,2,1)
    histogram(blobvalues,20)
    xlabel('Lightning Step')
    ylabel('Tally')

    subplot(2,2,2)
    histogram(bloblength)
    xlabel('Lightning Length')
    ylabel('Tally')

    subplot(2,2,3)
    plot(bloblength,blobvalues,'*')
    hold on
    plot(bloblength(blobpos < 2000),blobvalues(blobpos < 2000),'ko')

    xlabel('Lightning Length')
    ylabel('Lightning Step')
end

% reconsrtuct DNB image marked with aurora streaks
imgAurora = imreconstruct(double(austreakDNB > 0),stretchDNB);
imgtmp = imgAurora;

% find valid pixels
sunlitflag = ones(size(imgAurora));
sunlitflag(sunlit) = 0;
% sunlitflag(:,1:226) = 0;
% sunlitflag(:,3841:end) = 0;

% find BW threshold
% thrAurora = graythresh(imgAurora) % Matlab implementation of Otsu
thrAurora = thrOtsu(imgAurora(sunlitflag > 0),512)
imgAurora = im2bw(imgAurora,thrAurora);

% remove isolated features less than P pixels
P = 20;
imgAurora = bwareaopen(imgAurora,P);

% fill small holes
% make structural element
se = strel('disk',5);
% dilate the image.
imgAurora = imdilate(imgAurora,se);
imgAurora = imfill(imgAurora,'holes');

disp('Aurora detection done')
usedTime = toc
usedMemory = rtime.totalMemory - rtime.freeMemory
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'aurora';

if visFlag
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','Glint specle detector');
    
    subplot(2,2,1)
    image(stretchDNB*40)
    axis image
    colormap('gray');
    title('Input DNB image');
    freezeColors;
    
    subplot(2,2,2)
    imagesc(austreakDNB > 0)
    colormap('gray');
    axis image
    title('Aurora specle detections');
    freezeColors;
    
    dtctrgb = zeros(size(stretchDNB,1),size(stretchDNB,2),3);
%     dtctrgb(:,:,1) = min(stretchDNB*0.7,ones(size(stretchDNB))).*~streakDNB;
%     dtctrgb(:,:,2) = min(stretchDNB*0.7,ones(size(stretchDNB))).*~austreakDNB;
%     dtctrgb(:,:,3) = min(stretchDNB*0.7,ones(size(stretchDNB))).*~imgAurora;

%     dtctrgb(:,:,1) = min(imgtmp*0.7,ones(size(stretchDNB))).*~streakDNB;
    dtctrgb(:,:,1) = min(imgtmp*0.7,ones(size(stretchDNB)));
    dtctrgb(:,:,2) = min(imgtmp*0.7,ones(size(stretchDNB))).*~austreakDNB;
    dtctrgb(:,:,3) = min(imgtmp*0.7,ones(size(stretchDNB))).*~imgAurora;
    
    subplot(2,2,3)
    image(dtctrgb)
    axis image
    colormap('gray');
    title('Aurora detector and DNB image overlay');
    freezeColors;
    
    prodrgb = zeros(size(stretchDNB,1),size(stretchDNB,2),3);
    prodrgb(:,:,1) = prodDNB1;
    prodrgb(:,:,2) = prodDNB1;
    prodrgb(:,:,3) = prodDNB2;

    subplot(2,2,4)
    imagesc(imgAurora)
    axis image
    colormap('gray');
    title('Otsu thresholded');
    freezeColors;
    
    linkaxes
    zoom on
end

info=enviinfo(uint8(imgAurora));
enviwrite(uint8(imgAurora),info,[outfile '.aurora']);

metaname = [outfile '.aurora_metadata.csv'];
if metaFlag
        % table utils are not available on Anchor
        % metatable = struct2table(metadata);
        % writetable(metatable,lightname);
    metadata.streak = sum(streakDNB(:) > 0);
    metadata.aurora = sum(imgAurora(:) > 0);
        
    %// Extract field data
    fields = fieldnames(metadata);
    values = struct2cell(metadata);

    %// Convert all numerical values to strings
    idx = cellfun(@isnumeric, values); 
    values(idx) = cellfun(@num2str, values(idx), 'UniformOutput', 0);
    C = squeeze(values);

    %// Write fields to CSV file
    fid = fopen(metaname, 'wt');
    fmt_str = repmat('%s,', 1, size(C, 1));
    fprintf(fid, [fmt_str(1:end - 1), '\n'], fields{:});
    fprintf(fid, [fmt_str(1:end - 1), '\n'], C{:});
    fclose(fid);        
end

if isdeployed
    close all
end

end

function [T] = thrOtsu(I,N)

% create histogram
nbins = N; 
[x,h] = hist(I(:),nbins);

% calculate probabilities
p = x./sum(x);

% initialisation
om1 = 0; 
om2 = 1; 
mu1 = 0; 
mu2 = mode(I(:));

for t = 1:nbins,
    om1(t) = sum(p(1:t));
    om2(t) = sum(p(t+1:nbins));
    mu1(t) = sum(p(1:t).*[1:t]);
    mu2(t) = sum(p(t+1:nbins).*[t+1:nbins]);
end

% sigma_b_squared_wiki = omega1 .* omega2 .* (mu2-mu1).^2; % Eq. (14)
% sigma_b_squared_otsu = (mu1(end) .* omega1-mu1) .^2 ./(omega1 .* (1-omega1)); % Eq. (18)

sigma = (mu1(nbins).*om1-mu1).^2./(om1.*(1-om1));
idx = find(sigma == max(sigma));
T = h(idx(1));

end

