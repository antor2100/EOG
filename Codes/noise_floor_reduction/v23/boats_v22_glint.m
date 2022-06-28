function varargout = boats_v21_glint(fileDNB, fileLSM, fileEEZ, fileFLM, varargin)

[OUTPUT, fileVNF, fileFMZ, fileMPA, fileLTZ, fileRLP, fileRLV, ...
    MOONLIT, COVERAGE, PLOT, STRICT, DUMP, CHECKPOINT, METADATA, SMI, FLARE, SI, SHI, ...
    SOFT_LIGHTNING_LENGTH, SOUTH, NORTH, WEST, EAST, MAXSPIKE, LOCALMAX, XTRA] = ...
    process_options(varargin,'-output','','-vnf','','-fmz','','-mpa','','-ltz','','-rlp','','-rlv','',...
    '-moonlit',0.0001,'-coverage',0,'-plot',0,'-strict',0,'-dump',0,'-checkpoint',0,'-meta',0,'-smi',0.035,'-flare',0,'-si',0.4,'-shi',0.75,...
    '-lightning',8,'-south',-90,'-north',90,'-west',-180,'-east',180,'-maxspike',50000,'-localmax',0);

global FILLVALUE;
global MISSINGVALUE;

%% Memory monitor
rtime = java.lang.Runtime.getRuntime;
usedMemory = rtime.totalMemory - rtime.freeMemory
tmemprof(1).mem = usedMemory;
tmemprof(1).time = 0;
tmemprof(1).step = 'init';

%% Change log
% 20150203 - removed dependance from ROI in land-sea and flare masks
%            reprojection. Still need to fix "date change" meridian
% 20150519 - version 1.5 changes:
% 1) Record the flare mask file used in the csv.  Use column heading File_FlM.
% 2) Record the land/sea mask file used in the csv.  Use column heading File_LSM.
% 3) Record the Grings like we do in Nightfire.  Use column headings Lat_Gring and Lon_Gring.
% 4) Make a coverage png and add this step to the reduce software as well.  Again, like Nightfire.
% 5) Lowercase the satellite id in the id_key column.
% 6) Make the VNF csv OPTIONAL so we can run more quickly on the NRT system
% 7) Only run on nighttime data (solar zenith >96)
% 8) Fix bug that causes crash when covering -180/180 longitude discontinuity
% 9) Create "blank" output csv file in case of no detections, as we do for Nightfire.
% 10) Create new parameter for user to be able to adjust the maximum number of detections allowed to create an output file.  I think we decided we would abort after 10,000.  You can have this as a default, but please add this as an input parameter so we can adjust without having to create a new binary.
% 11) Change start of default output filename to VBD from VNB.
% 20150611 - changes in CLI option names
%          - added help function

varargout{1} = 0;

%%
helpind = strmatch('-h',XTRA);
if ~isempty(helpind) && helpind > 0 || nargin < 4
    disp('Matlab script "boats" has to be called with the following command line parameters:');
    disp('    (required)');
    disp('fileDNB               - name of the input file list or a single SVNDB file in HDF5 format (SVDNB*.h5)');
    disp('fileLSM               - name of the land-sea mask grid in ENVI format (binary file, not header)');
    disp('fileEEZ               - name of the exclusive economic zones vector file in SHP format (*.shp)');
    disp('fileFLM               - name of the flare mask grid in ENVI format (binary file, not header)');
    disp('    (optional)');
    disp('-output <dir name>   - output directory nane, will be derived from the fileDNB name if missing');
    disp('-vnf <file name>      - input VNF flare detections CSV file, will be derived from the fileDNB name if missing (*.csv)');
    disp('-fmz <file name>      - fishery management zones vector file in SHP format (*.shp)');
    disp('-mpa <file name>      - marine protected areas vector file in SHP format (*.shp)');
    disp('-ltz <file name>      - local standard time zones vector file in SHP format (*.shp)');
    disp('-rlp <file name>      - recurring light points (platforms) vector file in SHP format (*.shp)');
    disp('-rlv <file name>      - recurring light polygons (bridges) vector file in SHP format (*.shp)');
    disp('-coverage 0/1         - generate coverage maps in KML for Google Earth, default value is 0');
    disp('-plot 0/1             - plot SI, SMI, SHI, lightning and boat detections (requires X-Windows), default value is 0');
    disp('-strict 0/1           - output only boat detections (QF1, if strict == 1) or all QFs (if strict == 0, default)');
    disp('-localmax 0/1         - output only DNB local maxes (if localmax == 1) or all pixels above SMI threshold (if localmax == 0, default)');
    disp('-dump 0/1             - save SI, SMI, SHI and lightning detections as ENVI images, default value is 0');
    disp('-checkpoint 0/1       - save SI anc xCorr results from memory on disk to re-run the job faster, default value is 0');
    disp('-meta 0/1             - output one-line CSV with the processing metadata, default value is 0');
    disp('-smi <number>         - SMI detector threshold (default value is 0.035)');
    disp('-flare <number>       - minimum DNB brightness to convert boat to gas flare, if > 0 (default value is 0 => don''t do it)');
    disp('-si <number>          - SI detector threshold (default value is 0.4)');
    disp('-shi <number>         - SHI detector threshold (default value is 0.75)');
    disp('-lightning <number>   - lightning detector threshold (default value is -1)');
    disp('-moonlit <number>     - moonlit filter threshold (default value is 0, no mooonlit filter)');
    disp('-south <degrees>      - south latitude for the rectangular ROI (default value is -90)');
    disp('-north <degrees>      - north latitude for the rectangular ROI (default value is 90)');
    disp('-west <degrees>       - west longitude for the rectangular ROI (default value is -180)');
    disp('-east <degrees>       - east longitude for the rectangular ROI (default value is 180)');
    disp('-maxspike <number>    - maximum number of boat detections, error thrown if it is exceeded (default value is 10000)');
    disp('--force               - if present, disregard the NPP satellite mode (default is check for operational)');
    disp('-h                    - displays this help screen');
    return
end

boats_version = '22';
disp(['Detection ver. ',boats_version,' with threshols SMI=',num2str(SMI),' FLARE=',num2str(FLARE),' SI=',num2str(SI),' SHI=',num2str(SHI),' LIGHTNING_LENGTH=',num2str(SOFT_LIGHTNING_LENGTH)]);
disp(['Detection ROI SOUTH=',num2str(SOUTH),' NORTH=',num2str(NORTH),' WEST=',num2str(WEST),' EAST=',num2str(EAST)]);

FILLVALUE = 999999;
MISSINGVALUE = -999.3;

useI05 = true;

LIGHTNING_THR = -1.0;
GLINT_THR = -1.5;
STRAY_THR = 0.055;
STREAK_THR = -1.5;
STREAK_LENGTH = 12;

XCORR_WIN = 3; % I05 and DNB crosscorrelation window

SMI_DELTA = 0.1;
SMI_SHAPE_THR = -0.15; % threshld to decide between Xmass and lenticular
KNN_THR = 0.01; % SMI outliers in XCORR < -0.6 zone threshold
LENT_KNN_THR = 0.01; % SMI outliers in linticular zone threshold
GLINT_KNN_THR = 0.00075; % SMI outliers in glint zone threshold
DNB_KNN_THR = 3; % DNB outliers in glint zone threshold

PLP_RADIUS = 0.9; % km, radius to search for recurring light point sources

SMI_FLAG = 1;
FV_FLAG = 2;
FM_FLAG = 4;
VNF_FLAG = 8;
CR_FLAG = 16;
SI_FLAG = 32;
SHI_FLAG = 64;
LI_FLAG = 128;
ABS_FLAG = 256;
GLINT_FLAG = 512;
SIGMA_FLAG = 1024;
LOCALMAX_FLAG = 2048;
LIGHTNING_FLAG = 4096;
STRAYLIGHT_FLAG = 8192;
PERSIST_FLAG = 16384;
GLOW_FLAG = 32768;
FALSEQF1_FLAG = 65536;
BRIDGE_FLAG = 131072;

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

localmaxFlag = LOCALMAX;
disp(['Local maxima filter: ',num2str(localmaxFlag)]);

strictFlag = STRICT;
disp(['Strict boat detection output: ',num2str(strictFlag)]);

doCoverage = COVERAGE;
disp(['Generate coverage map: ',num2str(doCoverage)]);

dumpFlag = DUMP;
disp(['Dump intermediate data into ENVI files: ',num2str(dumpFlag)]);

checkpointFlag = CHECKPOINT;
disp(['Save intermediate arrays from memory on disk for hot restart: ',num2str(checkpointFlag)]);

metaFlag = METADATA;
disp(['Dump detection metadata into CSV file: ',num2str(metaFlag)]);

if MOONLIT > 0
    disp(['Apply moonlit filter threshold: ',num2str(MOONLIT)]);
end

visFlag = PLOT;
disp(['Interactive plots: ',num2str(visFlag)]);

%% latLonLimits are in the form of [southLat northLat westLon eastLon]
latLonLimits = [SOUTH, NORTH, WEST, EAST];

tic

%% EEZ boundaries
eez = [];
fmz = [];
mpa = [];
ltz = [];
pfm = [];
brg = [];

if ~isempty(fileEEZ)
    disp(['Using EEZ vectors from ', fileEEZ]);
    eez = shaperead(fileEEZ);
end

if ~isempty(fileFMZ)
    disp(['Using FMZ vectors from ', fileFMZ]);
    fmz = shaperead(fileFMZ);
end

if ~isempty(fileMPA)
    disp(['Using MPA vectors from ', fileMPA]);
    mpa = shaperead(fileMPA);
end

if ~isempty(fileLTZ)
    disp(['Using local time zone vectors from ', fileLTZ]);
    ltz = shaperead(fileLTZ);
end

if ~isempty(fileRLP)
    disp(['Using recurring lights vectors from ', fileRLP]);
    pfm = shaperead(fileRLP);
end

if ~isempty(fileRLV)
    disp(['Using bridge vectors from ', fileRLV]);
    brg = shaperead(fileRLV);
end

disp('EEZ, FMZ and MPA bounds read')
usedTime = toc
usedMemory = rtime.totalMemory - rtime.freeMemory
tmemprof(2).mem = usedMemory;
tmemprof(2).time = usedTime;
tmemprof(2).step = 'vectors';

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
limap = containers.Map();
i05map = containers.Map();
vnfmap = containers.Map();
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
                
        if isempty(fileVNF)
            prefix = 'VNFF';
            vnfpart = viirs_recent_file(pathstr,prefix,compart,'csv');
            if ~isempty(vnfpart)
                vnfmap(compart) = vnfpart;
            else
                vnfmap(compart) = '';
            end
%         elseif nf == 1 % just for the first granule
        else
            vnfmap(compart) = fileVNF;
        end
        
        % [pathstrli, nameli, extli] = fileparts(llname);
        % liname = fullfile(pathstrli, [llname, '.li']);
        liname = [llname, '_li'];
        limap(compart) = liname;

        if useI05 
            prefix = 'SVI05';
        else
            prefix = 'SVI04';            
        end
        i05name = viirs_recent_file(pathstr,prefix,compart,'dspace_rad');
%         [pathstrI05, nameI05, extI05] = fileparts(i05name);
%         i05name = fullfile(pathstrI05, [nameI05, '.dspace_rad']);
        i05map(compart) = i05name;
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

sunlit = find (solarzenithdata < 105 & solarzenithdata > -999);
imageDNB(sunlit) = 0;
stretchDNB(sunlit) = 0;

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
    warning('Aggregate is over the North Pole');
    maxDNBlat = 90;
elseif inflag(2)
    warning('Aggregate is over the South Pole');
    minDNBlat = -90;
end

disp('DNB input read')
usedTime = toc
usedMemory = rtime.totalMemory - rtime.freeMemory
tmemprof(3).mem = usedMemory;
tmemprof(3).time = usedTime;
tmemprof(3).step = 'dnb';

% if dumpFlag
if false
    info=enviinfo(stretchDNB);
    enviwrite(stretchDNB,info,[outfile '.stretch_dnb']);
end

%% land-water mask
disp(['Using land-sea mask from ', fileLSM]);
[p,t,refmat] = frefvecenvi(fileLSM);

lwmask_width = p(1);
lwmask_height = p(2);
lwmask_latstep = refmat(6);
lwmask_lonstep = refmat(5);
lwmask_lonmin = refmat(3);
lwmask_lonmax = refmat(3) + lwmask_width * lwmask_lonstep;
lwmask_latmax = min(90,refmat(4));
lwmask_latmin = max(-90,refmat(4) - lwmask_height * lwmask_latstep);

R = makerefmat(lwmask_lonmin,lwmask_latmax,lwmask_lonstep,-lwmask_latstep);

latlim = double([(minDNBlat), (maxDNBlat)]);
lonlim = double([(minDNBlon), (maxDNBlon)]);

[ylim,xlim] = latlon2pix(R,latlim,lonlim);

rectheight = round(ylim(1) - ylim(2));
rectwidth = round(xlim(2) - xlim(1));

if cross180 || rectwidth == 0
    rectwidth = lwmask_width;
    rectx = 1;
end

[lwmask,lwmaskp,lwmaskt,lwmaskmat]=fcutenvi(fileLSM,...
    ylim(2),xlim(1),rectheight,rectwidth);

lwwin_width = lwmaskp(1);
lwwin_height = lwmaskp(2);
lwwin_latstep = lwmaskmat(6);
lwwin_lonstep = lwmaskmat(5);
lwwin_lonmin = lwmaskmat(3)
lwwin_lonmax = lwmaskmat(3) + lwwin_width * lwwin_lonstep
lwwin_latmax = min(90,lwmaskmat(4))
lwwin_latmin = max(-90,lwmaskmat(4) - lwwin_height * lwwin_latstep)

size(lwmask)

Rwin = makerefmat(lwwin_lonmin,lwwin_latmax,lwwin_lonstep,-lwwin_latstep);

% Sea-land mask values
slval = ltln2val(lwmask, Rwin, dnblats, dnblons, 'nearest');

% if dumpFlag
if false
    info=enviinfo(slval);
    enviwrite(slval,info,[outfile '.lwmask']);    
end

disp('Land-sea mask read')
usedTime = toc
usedMemory = rtime.totalMemory - rtime.freeMemory
tmemprof(4).mem = usedMemory;
tmemprof(4).time = usedTime;
tmemprof(4).step = 'land-sea';

%% Lunar illuminance file
try
    limage = viirs_aggregate_granules_simple(limap, '')';
catch
    error('Missing LI file')
end

li_map = limage > MOONLIT;

%% Moon glint model
LiLim = 600;
GlintLim = 0.05;
WindSpeed = 8; % m / s^2
% GlintLim = 0.3;
% WindSpeed = 1; % m / s^2
glintdata = abs(lunarglint(satellitezenithdata,lunarzenithdata,satelliteazimuthdata,lunarazimuthdata,WindSpeed));
glint_map = glintdata > GlintLim & limage > MOONLIT;

disp('Made glint model')

% if dumpFlag
if false
    info=enviinfo(uint8(glint_map));
    enviwrite(uint8(glint_map),info,[outfile '.glint_mask']);
    info=enviinfo(single(glintdata));
    enviwrite(single(glintdata),info,[outfile '.glint_probability']);
end

%% Glint detector
LIGHTNING_LENGTH = 8;
if SOFT_LIGHTNING_LENGTH > LIGHTNING_LENGTH || SOFT_LIGHTNING_LENGTH < 2
    SOFT_LIGHTNING_LENGTH = LIGHTNING_LENGTH;
end

[nr,nc] = size(imageDNB);
% glintDNB = zeros(size(imageDNB));
prodDNB1 = zeros(size(imageDNB));
prodDNB2 = zeros(size(imageDNB));
stepDNB = zeros(size(imageDNB));
blobvalues = [];
bloblength = [];
blobpos = [];
blobcount = 0;
for ii = 1:16:nr-15
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
    
    thrline = log10(prodline1) > GLINT_THR;
    
    bb = regionprops(thrline,log10(prodline1),'Boundingbox','MaxIntensity');
    bblbl = bwlabel(thrline);
    numberOfBlobs = length(bb);
    bbx = zeros(numberOfBlobs,1);
    lout = zeros(size(bblbl));
    for k = 1 : numberOfBlobs           % Loop through all blobs.
        % Find the bounding box of each blob.
        bbox = bb(k).BoundingBox;
        bbx(k) = bbox(3);
        if bbx(k) > SOFT_LIGHTNING_LENGTH
            lout = max(lout, (bblbl == k) * bbx(k));
            blobcount = blobcount + 1;
            blobvalues(blobcount) = bb(k).MaxIntensity;
            bloblength(blobcount) = bbx(k);
            blobpos(blobcount) = bbox(1);
        end
    end
    
    thrline = log10(prodline2) > GLINT_THR;
    
    bb = regionprops(thrline,log10(prodline2),'Boundingbox','MaxIntensity');
    bblbl = bwlabel(thrline);
    numberOfBlobs = length(bb);
    bbx = zeros(numberOfBlobs,1);
    for k = 1 : numberOfBlobs           % Loop through all blobs.
        % Find the bounding box of each blob.
        bbox = bb(k).BoundingBox;
        bbx(k) = bbox(3);
        if bbx(k) > SOFT_LIGHTNING_LENGTH
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
    
    glintDNB(ii:ii+15,:) = repmat(lout,16,1);
    
    prodDNB1(ii:ii+15,:) = repmat(log10(prodline1)>LIGHTNING_THR,16,1);
    prodDNB2(ii:ii+15,:) = repmat(log10(prodline2)>LIGHTNING_THR,16,1);
    
    stepDNB(ii:ii+15,:) = repmat(max(log10(prodline1),log10(prodline2)),16,1);
end

%% Mask glint specle detections only inside probable ellipse
% size(glintDNB)
% size(glint_map)
glintDNB = glintDNB .* glint_map;

%% Check for single track hot spots
CC = bwconncomp(glintDNB);
S = regionprops(CC,'BoundingBox','PixelIdxList');
bbox = cat(1, S.BoundingBox);
if size(bbox,1) > 0
    singleidx = find(bbox(:,4) == 16);
    % glintDNB(CC.PixelIdxList{singleidx}) = 0;
    for i = 1:length(singleidx)
        glintDNB(CC.PixelIdxList{singleidx(i)}) = 0;
    end
    glintDNB = imfill(glintDNB,'holes');
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
    imagesc(glintDNB > 0)
    colormap('gray');
    axis image
    title('Glint specle detections');
    freezeColors;
    
    dtctrgb = zeros(size(stretchDNB,1),size(stretchDNB,2),3);
    dtctrgb(:,:,1) = min(stretchDNB*0.7,ones(size(stretchDNB)));
    dtctrgb(:,:,2) = min(stretchDNB*0.7,ones(size(stretchDNB))).*~glintDNB;
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

glintim = glint_map .* slval > 0;
glintspecl = glintDNB .* slval > 0;
highrefl = ((imageDNB > limage * LiLim) & glintim);

doDump = sum(glintim(:) > 0) > 0
if dumpFlag && doDump
    info=enviinfo(uint8(glintim + 2 * glintspecl + 4 * highrefl));
    enviwrite(uint8(glintim + glintspecl),info,[outfile '.glint_specular']);
    
%     info=enviinfo(single(stepDNB));
%     enviwrite(single(stepDNB),info,[outfile '.glint_step']);    
end

clear stepDNB prodDNB1 prodDNB2 prodrgb dtctrgb

% if visFlag
if doDump
%     figlint = figure('Name','Glint map');
% %     imagesc(glint_map .* slval > 0 + glintDNB)
%     imagesc(glintim + glintspecl)
%     colorbar
%     colormap('gray');
%     print(figlint,'-dpng','-r0',[outfile,'.glint_specular.png']);
    
    specind = find(glintspecl);
    data1 = limage(specind);
%     data2 = imageDNB(specind)./limage(specind);
    data2 = imageDNB(specind);
    nBins_x = 100;
    nBins_y = 100;
    [counts, bin_centers] = hist3([data1(:) data2(:)], [nBins_x nBins_y]);
    x_bin_centers = bin_centers{1};
    y_bin_centers = bin_centers{2};

%     fighist = figure('Name','Specular DNB vs LI');
%     imagesc(x_bin_centers, y_bin_centers, counts)    
%     colorbar
%     xlabel('LI');
%     ylabel('DBN');

%    heatscatter(data1, data2, LiLim, outdir, [infile_name '.DNB_vs_LI.glint.png'])
    
%     heatscatter(data1 .* glintdata(specind), data2, LiLim, [], 'dnb_vs_li')

    scrsz = get(0,'ScreenSize');
    figlint1 = figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','Reflectivity mask');
    subplot(2,2,1)
    image(stretchDNB*40)
    axis image
    colormap('gray');
    title('Input DNB image');
    freezeColors;

    dtctrgb = zeros(size(stretchDNB,1),size(stretchDNB,2),3);
    dtctrgb(:,:,1) = min(stretchDNB*0.7,ones(size(stretchDNB)));
    dtctrgb(:,:,2) = min(stretchDNB*0.7,ones(size(stretchDNB))).*~glintDNB;
    dtctrgb(:,:,3) = min(stretchDNB*0.7,ones(size(stretchDNB)));
    
    subplot(2,2,2)
    image(dtctrgb)
    axis image
    colormap('gray');
    title('Glint Streak Detector and DNB image overlay');
    freezeColors;

    dtctrgb = zeros(size(stretchDNB,1),size(stretchDNB,2),3);
    dtctrgb(:,:,1) = min(stretchDNB*0.7,ones(size(stretchDNB)));
    dtctrgb(:,:,2) = min(stretchDNB*0.7,ones(size(stretchDNB))).*~highrefl;
    dtctrgb(:,:,3) = min(stretchDNB*0.7,ones(size(stretchDNB)));
    
    subplot(2,2,3)
    image(dtctrgb)
    axis image
    colormap('gray');
    title('Glint Reflectivity Detector and DNB image overlay');
    freezeColors;
    
    subplot(2,2,4)
    imagesc(highrefl)
    axis image
    colormap('gray');
    title('Reflectivity map');
    freezeColors;
    
    linkaxes
    print(figlint1,'-dpng','-r0',[outfile,'.glint_specular.png']);    

    zoom on
end

disp('Glint detector')
usedTime = toc
usedMemory = rtime.totalMemory - rtime.freeMemory
tmemprof(8).mem = usedMemory;
tmemprof(8).time = usedTime;
tmemprof(8).step = 'glint';

glintname = [outfile '.glint_metadata.csv'];
if true
        % table utils are not available on Anchor
        % metatable = struct2table(metadata);
        % writetable(metatable,lightname);
    metadata.glint = sum(glintim(:) > 0);
    metadata.specular = sum(glintspecl(:) > 0);
    metadata.reflective = sum(highrefl(:) > 0);
        
    %// Extract field data
    fields = fieldnames(metadata);
    values = struct2cell(metadata);

    %// Convert all numerical values to strings
    idx = cellfun(@isnumeric, values); 
    values(idx) = cellfun(@num2str, values(idx), 'UniformOutput', 0);
    C = squeeze(values);

    %// Write fields to CSV file
    fid = fopen(glintname, 'wt');
    fmt_str = repmat('%s,', 1, size(C, 1));
    fprintf(fid, [fmt_str(1:end - 1), '\n'], fields{:});
    fprintf(fid, [fmt_str(1:end - 1), '\n'], C{:});
    fclose(fid);        
end

if isdeployed
    close all
end

end

