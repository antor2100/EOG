function varargout = boats_v21(fileDNB, fileLSM, fileEEZ, fileFLM, varargin)

[OUTPUT, INPUT, fileVNF, fileFMZ, fileMPA, fileLTZ, fileRLP, fileRLV, fileTAI, fileSAA,...
    I05, MOONLIT, COVERAGE, PLOT, STRICT, DUMP, CHECKPOINT, METADATA, SMI, FLARE, SI, SHI, ...
    SOFT_LIGHTNING_LENGTH, SOUTH, NORTH, WEST, EAST, MAXSPIKE, LOCALMAX, XTRA] = ...
    process_options(varargin,'-output','','-input','','-vnf','','-fmz','','-mpa','','-ltz','','-rlp','','-rlv','','-tai','','-saa','',...
    '-i05',1,'-moonlit',0.0001,'-coverage',0,'-plot',0,'-strict',0,'-dump',0,'-checkpoint',0,'-meta',0,'-smi',0.035,'-flare',0,'-si',0.4,'-shi',0.75,...
    '-lightning',8,'-south',-90,'-north',90,'-west',-180,'-east',180,'-maxspike',50000,'-localmax',0);

global FILLVALUE;
global MISSINGVALUE;

%% Memory monitor
rtime = java.lang.Runtime.getRuntime;
usedMemory = rtime.totalMemory - rtime.freeMemory
stepnum = 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = 0;
tmemprof(stepnum).step = 'init';

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
    disp('-output <dir name>    - output directory nane, will be derived from the fileDNB name if missing');
    disp('-input <dir name>     - input directory nane for intermediate files like LI and SVI04-05, will be derived from the fileDNB name if missing');
    disp('-vnf <file name>      - input VNF flare detections CSV file, will be derived from the fileDNB name if missing (*.csv)');
    disp('-fmz <file name>      - fishery management zones vector file in SHP format (*.shp)');
    disp('-mpa <file name>      - marine protected areas vector file in SHP format (*.shp)');
    disp('-ltz <file name>      - local standard time zones vector file in SHP format (*.shp)');
    disp('-rlp <file name>      - recurring light points (NTL platforms) vector file in SHP format (*.shp)');
    disp('-rlv <file name>      - recurring light polygons (bridges) vector file in SHP format (*.shp)');
    disp('-tai <file name>      - leap second correction table from atomic to international time (*.txt)');
    disp('-saa <file name>      - cosmic ray anomalies polygons (SAA) vector file in SHP format  (*.shp)');
    disp('-i05 0/1              - use I05 or I04 IR bands to correlate with DNB for moonlit clouds, default value is 1');
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

boats_version = '23';
disp(['Detection ver. ',boats_version,' with threshols SMI=',num2str(SMI),' FLARE=',num2str(FLARE),' SI=',num2str(SI),' SHI=',num2str(SHI),' LIGHTNING_LENGTH=',num2str(SOFT_LIGHTNING_LENGTH)]);
disp(['Detection ROI SOUTH=',num2str(SOUTH),' NORTH=',num2str(NORTH),' WEST=',num2str(WEST),' EAST=',num2str(EAST)]);

FILLVALUE = 999999;
MISSINGVALUE = -999.3;

LIGHTNING_THR = -1.0;
GLINT_THR = -1.5;
STRAY_THR = 0.055;
STREAK_THR = -1.5;
STREAK_LENGTH = 12;

XCORR_WIN = 3; % I05 and DNB crosscorrelation window

SMI_DELTA = 0.1;
SMI_SHAPE_THR = -0.15; % threshld to decide between Xmass and lenticular
KNN_THR = 0.01; % SMI outliers in XCORR < -0.6 zone threshold
% LENT_KNN_THR = 0.01; % SMI outliers in linticular zone threshold
LENT_KNN_THR = 0.001; % SMI outliers in linticular zone threshold, lowered down after the Myanmar "glint" boats not detected
GLINT_KNN_THR = 0.01; % SMI outliers in glint zone threshold
% GLINT_KNN_THR = 0.00075; % SMI outliers in glint zone threshold
DNB_KNN_THR = 3; % DNB outliers in glint zone threshold

PLP_RADIUS = 1; % km, radius to search for recurring light point sources

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
HOTSPOT_FLAG = 262144;

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

useI05 = I05;
if useI05
    disp('Using band I05 to detect moonlit couds');
else
    disp('Using band I04 to detect moonlit couds');
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
saa = [];
eez = [];
fmz = [];
mpa = [];
ltz = [];
pfm = [];
brg = [];
tai = [];
if ~isempty(fileTAI)
    disp(['Using TAI leap seconds from ', fileTAI]);
    fid = fopen(fileTAI);
    chartai = fgetl(fid);
    i = 0;
    while ischar(chartai)
        i = i + 1;
%        tai(i).year = str2num(chartai(1:4));
%        tai(i).month = chartai(6:9);
%        tai(i).day = str2num(chartai(10:11));
        tai(i).date = chartai(1:12);
        tai_utc = chartai(37:48);
        tai(i).tai_utc = str2num(chartai(37:48));
        chartai = fgetl(fid);
    end

    fclose(fid);
else
    warning('No time correction from TAI to UTC')
end
% datenow = now();
% dateinfo = datestr(datenow)
% 
% datecorr = tai2utc(tai,datenow)
% 
% return


Xsaa = 1:4064;
Ysaa = 0.1 + 0.45 * ((Xsaa - 2032)/2032).^2;
if ~isempty(fileSAA)
    disp(['Using SAA vectors from ', fileSAA]);
    saa = shaperead(fileSAA);
end

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

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'vectors';
disp(['EEZ, FMZ and MPA bounds read time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

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

        if isempty(INPUT)
            indir = pathstr;
            warning(['Using default directory for LI and SVI files ',indir]);
        else
            indir = INPUT;
            disp(['Input directory for LI and SVI files ',indir]);
        end        
        
        llprefix = 'GDNBO';
        llname = viirs_recent_file(pathstr,llprefix,compart);
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
%             vnfpart = viirs_recent_file(pathstr,prefix,compart,'csv');
            vnfpart = viirs_recent_file(indir,prefix,compart,'csv');
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
%         liname = [llname, '_li'];
        liname = viirs_recent_file(indir,llprefix,compart,'h5_li');
        limap(compart) = liname;

        if useI05 
            prefix = 'SVI05';
        else
            prefix = 'SVI04';            
        end
        %poyda i05name = viirs_recent_file(pathstr,prefix,compart,'dspace_rad');
        i05name = viirs_recent_file(indir,prefix,compart,'dspace_rad');
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
aggrDataset = '/Data_Products/VIIRS-DNB-SDR/VIIRS-DNB-SDR_Aggr';
aggrAttr = 'AggregateNumberGranules'

[dnblines, dnbcols] = size(imageDNB);
granedges = 0:dnblines/nnames:dnblines;

daynightDataset = '/Data_Products/VIIRS-DNB-SDR/VIIRS-DNB-SDR_Gran_';
daynightAttr = 'N_Day_Night_Flag';
grannames = dnbmap.values();

ntdata = 0; % number of nighttime granules
ndata = 0; % total number of granules to process
for i = 1:nnames
    gname = char(grannames(i));
    ngranules = int32(h5readatt(gname, aggrDataset, aggrAttr));
    ndata = ndata + ngranules
    for j = 0:ngranules-1
        daynight = deblank(char(h5readatt(gname, [daynightDataset,num2str(j)], daynightAttr)));
        if strncmp(daynight,'Day',3)
            warning(['NPP satellite Day_Night_Flag = ', daynight,' in granule ',gname]);
        %         imageDNB(granedges(i)+1:granedges(i+1),:) = 0;
        %         stretchDNB(granedges(i)+1:granedges(i+1),:) = 0;
        else
            ntdata = ntdata + 1;
        end
    end
end
if ntdata == 0 && ~forceFlag
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

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'dnb';
disp(['DNB image read time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

if dumpFlag
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
lwwin_lonmin = lwmaskmat(3);
lwwin_lonmax = lwmaskmat(3) + lwwin_width * lwwin_lonstep;
lwwin_latmax = min(90,lwmaskmat(4));
lwwin_latmin = max(-90,lwmaskmat(4) - lwwin_height * lwwin_latstep);

Rwin = makerefmat(lwwin_lonmin,lwwin_latmax,lwwin_lonstep,-lwwin_latstep);

% Sea-land mask values
slval = ltln2val(lwmask, Rwin, dnblats, dnblons, 'nearest');

if dumpFlag
    info=enviinfo(slval);
    enviwrite(slval,info,[outfile '.lwmask']);    
end

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'land-sea';
disp(['Land-sea mask read time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

% [lwrows,lwcols] = meshgrid(1:size(lwmask,2), 1:size(lwmask,1));
% lwlats = lwwin_latmin + lwrows * lwwin_latstep;
% lwlons = lwwin_lonmin + lwcols * lwwin_lonstep;
% size(lwlats)
% size(lwlons)
% geostretchDNB = griddata(stretchDNB,dnblats,dnblons,lwlats,lwlons,'nearest');
% size(geostretchDNB)
% 
% scrsz = get(0,'ScreenSize');
% figure('Position',[1 1 scrsz(3) scrsz(4)])
% % imagesc(slval)
% % title('Reprojected land-sea mask')
% % imagesc(lwmask)
% % title('Geographic land-sea mask')
% imagesc(geostretchDNB)
% title('Reprojected DNB')
% colormap('gray')
% colorbar
% axis image
% zoom on

%% aurora model
if false
aurora_file = '/Volumes/Shared/MyProjects/Boats/ovation_test.txt'
aurora_diff_tab = readtable(aurora_file,'ReadVariableNames',false);

nanind = find(isnan(aurora_diff_tab.Var3));
aurora_diff_tab.Var3(nanind) = 0;

aurora_mat = table2array(aurora_diff_tab);

vq = griddata(aurora_mat(:,1),aurora_mat(:,2),aurora_mat(:,3),dnblats,dnblons);

% figure
% imagesc(vq)
% geoshow(yq,xq,vq)

figure
histogram(aurora_mat(:,3))

if visFlag
    scrsz = get(0,'ScreenSize');
    blurfig = figure('Position',[1 1 scrsz(3) scrsz(4)]);
    
    dnbsubplot = subplot(1,2,1);
    imagesc(stretchDNB)
    set(gca,'xtick',[],'ytick',[])
    axis image
    colormap('gray');
    colorbar;
    title('DNB image');
    
    % s1_thr = min(s1_map(:) < 0.1);
    % s1_map(s1_thr) = 0;
    
    subplot(1,2,2)
    imagesc(vq)
%     imagesc(vq>0.1)
    set(gca,'xtick',[],'ytick',[])
    axis image
    colormap('gray');
    colorbar;
    title('Aurora model');
    
    linkaxes
    zoom on

    scrsz = get(0,'ScreenSize');
    blurfig = figure('Position',[1 1 scrsz(3) scrsz(4)]);
    
    dnbsubplot = subplot(1,2,1);
    image(stretchDNB*40)
%     set(gca,'xtick',[],'ytick',[])
    axis image
    colormap('gray');
%     colorbar;
    title('DNB image');
    
    % s1_thr = min(s1_map(:) < 0.1);
    % s1_map(s1_thr) = 0;
    
    subplot(1,2,2)
%     imagesc(vq)
    imagesc(vq>0.1)
%     set(gca,'xtick',[],'ytick',[])
    axis image
    colormap('gray');
%     colorbar;
    title('Aurora model');
    
    linkaxes
    zoom on
    
    dtctrgb = zeros(size(stretchDNB,1),size(stretchDNB,2),3);
    dtctrgb(:,:,1) = min(stretchDNB*0.9,ones(size(stretchDNB)));
    dtctrgb(:,:,2) = min(stretchDNB*0.9,ones(size(stretchDNB))).*~(vq>0.1);
    dtctrgb(:,:,3) = min(stretchDNB*0.9,ones(size(stretchDNB)));

    scrsz = get(0,'ScreenSize');
    figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','Aurora filter');
    image(dtctrgb)
    axis image
    title('Aurora filter')
    zoom on
end

disp('Aurora detector')
toc

return
end

%% flare mask
disp(['Using flare mask from ', fileFLM]);
[p,t,refmat] = frefvecenvi(fileFLM);

flmask_width = p(1);
flmask_height = p(2);
flmask_latstep = refmat(6);
flmask_lonstep = refmat(5);
flmask_lonmin = refmat(3);
flmask_lonmax = refmat(3) + flmask_width * flmask_lonstep;
flmask_latmax = min(90,refmat(4));
flmask_latmin = max(-90,refmat(4) - flmask_height * flmask_latstep);

R = makerefmat(flmask_lonmin,flmask_latmax,flmask_lonstep,-flmask_latstep);

[ylim,xlim] = latlon2pix(R,latlim,lonlim);

rectheight = round(ylim(1) - ylim(2));
rectwidth = round(xlim(2) - xlim(1));

if cross180 || rectwidth == 0
    rectwidth = lwmask_width;
    rectx = 1;
end

[flmask,flmaskp,flmaskt,flmaskmat]=fcutenvi(fileFLM,...
    ylim(2),xlim(1),rectheight,rectwidth);

flwin_width = flmaskp(1);
flwin_height = flmaskp(2);
flwin_latstep = flmaskmat(6);
flwin_lonstep = flmaskmat(5);
flwin_lonmin = flmaskmat(3);
flwin_lonmax = flmaskmat(3) + flwin_width * flwin_lonstep;
flwin_latmax = min(90,flmaskmat(4));
flwin_latmin = max(-90,flmaskmat(4) - flwin_height * flwin_latstep);

FLRwin = makerefmat(flwin_lonmin,flwin_latmax,flwin_lonstep,-flwin_latstep);

if false
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 1 scrsz(3) scrsz(4)])
    
    size(flmask)
    size(lwmask)
    
    imagesc((double(flmask) * 5 + double(lwmask)))
    % imagesc((double(flmask) * 5 + double(lwmask)))
    hold on
    % plot(col_fl1,row_fl1,'ro')
    % plot(col_fl2,row_fl2,'go')
    colormap('gray')
    colorbar
    axis image

    zoom on
end

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'flares';
disp(['Flare mask grid read time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

if dumpFlag
    info=enviinfo(imageDNB);
    enviwrite(imageDNB,info,[outfile '.image_dnb']);
end

%% lightning detector
LIGHTNING_LENGTH = 8;
if SOFT_LIGHTNING_LENGTH > LIGHTNING_LENGTH || SOFT_LIGHTNING_LENGTH < 2
    SOFT_LIGHTNING_LENGTH = LIGHTNING_LENGTH;
end

[nr,nc] = size(imageDNB);
% thndrDNB = zeros(size(imageDNB));
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
    
%     thrline = log10(prodline1) > LIGHTNING_THR | log10(prodline2) > LIGHTNING_THR ;
    thrline = log10(prodline1) > LIGHTNING_THR;
    
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
    
%     thndrind = find(bbx > LENGTH);
% %     thndrind = find(bbx > LIGHTNING_LENGTH);
% %     lout = ismember(bblbl,thndrind) .* bbx(thndrind);

    thrline = log10(prodline2) > LIGHTNING_THR;
    
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
    
    thndrDNB(ii:ii+15,:) = repmat(lout,16,1);
    
    prodDNB1(ii:ii+15,:) = repmat(log10(prodline1)>LIGHTNING_THR,16,1);
    prodDNB2(ii:ii+15,:) = repmat(log10(prodline2)>LIGHTNING_THR,16,1);
    
    stepDNB(ii:ii+15,:) = repmat(max(log10(prodline1),log10(prodline2)),16,1);
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

% figure
% histogram(thndrDNB(thndrDNB > 0)/16)
% min(thndrDNB(thndrDNB > 0))

if visFlag
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','Lightning detector');
    
    subplot(2,2,1)
    image(stretchDNB*40)
    axis image
    colormap('gray');
    title('Input DNB image');
    freezeColors;
    
    subplot(2,2,2)
    imagesc(thndrDNB > 0)
    colormap('gray');
    axis image
    title('Lightning detections');
    freezeColors;
    
    dtctrgb = zeros(size(stretchDNB,1),size(stretchDNB,2),3);
    dtctrgb(:,:,1) = min(stretchDNB*0.7,ones(size(stretchDNB)));
    dtctrgb(:,:,2) = min(stretchDNB*0.7,ones(size(stretchDNB))).*~thndrDNB;
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

if dumpFlag
    info=enviinfo(thndrDNB);
    enviwrite(thndrDNB,info,[outfile '.lightning']);

    info=enviinfo(stepDNB);
    enviwrite(stepDNB,info,[outfile '.scanstep']);
    %     info=enviinfo(prodDNB1);
    %     enviwrite(prodDNB1,info,[outfile '.lightning_prod1']);
    %     info=enviinfo(prodDNB2);
    %     enviwrite(prodDNB2,info,[outfile '.lightning_prod2']);
end

clear stepDNB prodDNB1 prodDNB2 prodrgb dtctrgb

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'lightning';
disp(['Lightning detector time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

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

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'streaks';
disp(['Streak detector time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

%% Lunar illuminance file
try
    limage = viirs_aggregate_granules_simple(limap, '')';
catch
    error('Missing LI file')
end

%% Moon glint model
GlintLim = 0.05;
HotspotLim = 500;
WindSpeed = 8; % m / s^2
% GlintLim = 0.3;
% WindSpeed = 1; % m / s^2
glintdata = abs(lunarglint(satellitezenithdata,lunarzenithdata,satelliteazimuthdata,lunarazimuthdata,WindSpeed));
glint_map = glintdata > GlintLim & limage > MOONLIT;

% disp('Made glint model')

if dumpFlag
%     info=enviinfo(glintdata.*glint_map);
%     enviwrite(glintdata.*glint_map,info,[outfile '.glint']);
    info=enviinfo(single(glintdata.*glint_map));
    enviwrite(single(glintdata),info,[outfile '.glint_nothr']);
end

% Glint hotspot detector
glintim = glint_map .* slval > 0;
hotspot = ((imageDNB > limage * HotspotLim) & (imageDNB < 1500) & glintim);
se = strel('disk',20);        
hotspot = imdilate(hotspot,se);

dodump = sum(glintim(:) > 0) > 0;
if dumpFlag && dodump
    info=enviinfo(uint8(glintim + 2 * hotspot));
    enviwrite(uint8(glintim + 2 * hotspot),info,[outfile '.glint_hotspot']);
end

clear stepDNB prodDNB1 prodDNB2 prodrgb dtctrgb glintspecl

if visFlag && dodump
    figlint = figure('Name','Glint map');
    imagesc(glintim + 2 * hotspot)
    axis image
    colorbar
    colormap('gray');
    print(figlint,'-dpng','-r0',[outfile,'.glint_specular.png']);
end

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'glint';
disp(['Glint detector time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

%% blur detector
PNOISE = [7.194118e-23, -8.837980e-19, 4.292086e-15, -1.046121e-11, 1.350611e-08, -8.960062e-06, 2.622827e-03];

sigmanoise = zeros(size(imageDNB1));
for j=1:size(imageDNB1,1)
    sigmanoise(j,1:4064) = polyval(PNOISE,1:4064)';
end

af3 = wiener2(imageDNB1,[3 3],2*sigmanoise);

clear imageDNB1 sigmanoise

fileSI = [outfile '.si'];
if checkpointFlag && exist(fileSI, 'file') == 2
    s1_map = freadenvi(fileSI);
else
    img = scale(af3);
    N = max(size(img));
    
    s1_map = spectral_map(img, 32, 16, 0);
    res_map = ones(size(imageDNB)) * 2; % missing value is 2
    res_map(noleapscans,:) = s1_map;
    s1_map = res_map;

    if checkpointFlag || dumpFlag
        info=enviinfo(single(s1_map));
        enviwrite(single(s1_map),info,fileSI);
    end
end
res_map = ones(size(imageDNB)) * 2; % missing value is 2
res_map(noleapscans,:) = af3;
af3 = res_map;

clear res_map img

if dumpFlag
    info=enviinfo(single(af3));
    enviwrite(single(af3),info,[outfile '.af3']);
end

if visFlag
    scrsz = get(0,'ScreenSize');
    blurfig = figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','Sharpness map');
    
    dnbsubplot = subplot(1,2,1);
    image(stretchDNB*40)
%     set(gca,'xtick',[],'ytick',[])
    axis image
    colormap('gray');
    colorbar;
    title('DNB image');
    
    % s1_thr = min(s1_map(:) < 0.1);
    % s1_map(s1_thr) = 0;
    
    subplot(1,2,2)
    % imagesc(tpmap)
    imagesc(s1_map)
%     set(gca,'xtick',[],'ytick',[])
    axis image
    colormap('gray');
    colorbar;
    title('Sharpness map');
    
    linkaxes
    zoom on
end

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'blur';
disp(['Blur detector time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

%% Find SMI spikes
imgmed = medfilt2(af3,[3 3]);
imgfilt = (af3 - imgmed);

clear imgmed af3

if dumpFlag
    info=enviinfo(single(imgfilt));
    enviwrite(single(imgfilt),info,[outfile '.smi']);
end

if visFlag && dodump % glint was detected
    glintlitmp = glintdata(slval > 0);
    smilitmp = imgfilt(slval > 0);

    figure('Name','Glint vs SMI scatterplot')
    plot(smilitmp,glintlitmp,'.')
    xlabel('SMI')
    ylabel('Glint')
end

%% Adaptive SMI vs xCorr thresholds
NLI = 7;
XcorrLim = -0.6;
WeakLim = -0.4;
XcorrPct = 0.25;
A = (1 - XcorrPct) / (WeakLim - 1);
B = XcorrPct - A;
Nmin4std =  3000;

imageCorr = ones(size(limage)) * 2;

lizones = zeros(size(limage));
thrzones = lizones;
loglimage = log10(limage);

%%
% glintind = find(glint_map > 0 & slval > 0 & imgfilt ~= 0 & limage ~= FILLVALUE & limage > MOONLIT);
glintind = find(hotspot & imgfilt ~= 0 & limage ~= FILLVALUE & limage > MOONLIT);
% length(glintind)
glinttailind = find(hotspot & imgfilt > 6 * std(imgfilt(glintind)) & limage ~= FILLVALUE & limage > MOONLIT);
% glinttailind = find(glint_map > 0 & slval > 0 & imgfilt > 6 * std(imgfilt(glintind)) & limage ~= FILLVALUE & limage > MOONLIT);
% length(glinttailind)
glinttop = 0;
% if false
if length(glintind) > Nmin4std
    imgtest = imgfilt(glinttailind);
    [knndx,ix] = sortdknn(imgtest,10);
    if length(find(knndx < GLINT_KNN_THR)) == 0 || max(knndx) < GLINT_KNN_THR
        glinttop = max(imgfilt(glintind));
        disp('Short tail distribution, thus using maximum as a threshold');
    else
        coresmi = find(knndx < GLINT_KNN_THR);
        glinttop = max(imgtest(ix(coresmi)));
    end        
%     glinttop = NsigmaGlint * std(imgfilt(glintind));
    disp(['Possible lunar glint with threshold ', num2str(glinttop) ])

    if false
        figure
        histogram(imgfilt(glintind));
        hold on
        vline(glinttop)
        vline(-glinttop)
    end
end

if visFlag && dodump % glint was detected
%     BWGlint = imregionalmax(imageDNB,4).*glint_map;
%     [r,c] = find(BWGlint);
    
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','Glint scatterplots');

    subplot(2,2,1)
    image(stretchDNB*40.*glint_map)
    hold on
%     plot(c,r,'r+')
    axis image
    colormap('gray');
    colorbar;
    title('Input image after stretch X 10');

    subplot(2,2,2)
    imagesc(glintdata.*glint_map.*limage)
    hold on
%     plot(c,r,'r+')
    axis image
    colormap('gray');
    colorbar;
    title('Glint image');

    subplot(2,2,3)
    plot(HotspotLim.*limage(glint_map),imageDNB(glint_map),'.')
    hold on
    hline(glinttop)
    title('LI / DNB scatter');
    xlabel('LI * Glint Hotspot Limit')
    ylabel('DNB radiance')

end

% return

%% Low moon thresholds
spikeThreshFix = ones(size(limage)) * SMI;

if true
spikeThreshFix(:,1:96) = spikeThreshFix(:,1:96) * 3.25;
spikeThreshFix(:,97:416) = spikeThreshFix(:,97:416) * 2.5;
spikeThreshFix(:,417:632) = spikeThreshFix(:,417:632) * 1.5;
spikeThreshFix(:,633:856) = spikeThreshFix(:,633:856) * 1.25;

spikeThreshFix(:,end-96+1:end) = spikeThreshFix(:,end-96+1:end) * 3.25;
spikeThreshFix(:,end-416+1:end-96) = spikeThreshFix(:,end-416+1:end-96) * 2.5;
spikeThreshFix(:,end-632+1:end-416) = spikeThreshFix(:,end-632+1:end-416) * 1.5;
spikeThreshFix(:,end-856+1:end-632) = spikeThreshFix(:,end-856+1:end-632) * 1.25;
end

spikeThreshStray = spikeThreshFix;

%% Straylight thresholds    
spikeThreshStray = ones(size(limage)) * STRAY_THR;

spikeThreshStray(:,1:96) = spikeThreshStray(:,1:96) * 3;
spikeThreshStray(:,97:416) = spikeThreshStray(:,97:416) * 2.5;
spikeThreshStray(:,417:632) = spikeThreshStray(:,417:632) * 2;
spikeThreshStray(:,633:856) = spikeThreshStray(:,633:856) * 1.75;
spikeThreshStray(:,857:1064) = spikeThreshStray(:,857:1064) * 1.5;
spikeThreshStray(:,1065:1272) = spikeThreshStray(:,1065:1272) * 1.25;

spikeThreshStray(:,end-96+1:end) = spikeThreshStray(:,end-96+1:end) * 3;
spikeThreshStray(:,end-416+1:end-96) = spikeThreshStray(:,end-416+1:end-96) * 2.5;
spikeThreshStray(:,end-632+1:end-416) = spikeThreshStray(:,end-632+1:end-416) * 2;
spikeThreshStray(:,end-856+1:end-632) = spikeThreshStray(:,end-856+1:end-632) * 1.75;
spikeThreshStray(:,end-1064+1:end-856) = spikeThreshStray(:,end-1064+1:end-856) * 1.5;
spikeThreshStray(:,end-1272+1:end-1064) = spikeThreshStray(:,end-1272+1:end-1064) * 1.25;

% rise no-moon threshold in straylight corrected region
spikeThreshFix = (1 - slightimg) .* spikeThreshFix + slightimg .* spikeThreshStray;

spikeThreshAbs = spikeThreshFix;
spikeThreshRel = spikeThreshFix;

limask = find(limage ~= FILLVALUE & limage > MOONLIT);

dnbspk = zeros(size(imgfilt)); % array to store SMI spike detections

%% Sigmoid threshold for mooonlit as default
spikeThreshAbs(limask) = max(spikeThreshFix(limask),0.05 + 0.55 * sigmf(loglimage(limask),[3 -1.7]));
lizones(spikeThreshFix < spikeThreshAbs) = NLI; % mark the sigmoid thresholded image
thrzones(limage ~= FILLVALUE & limage > MOONLIT & spikeThreshFix < spikeThreshAbs) = 1;

%% LI zones
pcts = linspace(0,100,NLI);
edges = zeros(size(pcts));
for i = 1:length(edges)
    edges(i) = percentile(loglimage(:),pcts(i));
end
edges(1) = edges(1) - eps;
edges(NLI) = edges(NLI) + eps;

metadata = [];

for i = 1:length(edges)-1
    metadata(i).lizone = i;
    metadata(i).minli = 10^edges(i);
    metadata(i).maxli = 10^edges(i+1);
    
    metadata(i).glint = 0;
    metadata(i).glintsmitop = -1;
    metadata(i).glintcount = 0;
    metadata(i).hotspotcount = 0;
    
    liindex = find(limage ~= FILLVALUE & log10(limage) >= edges(i) & log10(limage) < edges(i+1));    
    [lirow,licol] = ind2sub(size(loglimage),liindex);
    
    if any(glint_map(liindex))
        metadata(i).glint = 1;
        metadata(i).glintsmitop = glinttop;
        metadata(i).glintcount = sum(glint_map(liindex));
        metadata(i).hotspotcount = sum(hotspot(liindex));
    end
    
    metadata(i).minsample = min(licol(:));
    metadata(i).maxsample = max(licol(:));

    metadata(i).smitype = 0; % low moon
    metadata(i).smitop = FILLVALUE;
    metadata(i).smishape = FILLVALUE;
    metadata(i).lentictally = FILLVALUE;
end

%% Square mask for debugging
sqmask = zeros(size(imgfilt));
% % puffy 1
% sqmask(100:400,800:1600) = 1;
% % puffy 2
% sqmask(500:800,3000:3300) = 1;
% qf1-3_glint
% sqmask(50:150,650:750) = 1;
% QF1 diifference using I04 and I05
% sqmask(2760:2790,2230:2260) = 1;
% figure('Square mask ROI')
% imagesc(sqmask)
% title('Sqmask')

%% Read I05 or I04
try
    imageI05 = viirs_aggregate_granules_simple(i05map, '')';
catch
    if useI05 
        error('Missing SVI05 file')
    else
        error('Missing SVI04 file')
    end
end

if useI05 
    disp('Band I05 read')
else
    disp('Band I04 read')
end
    
%% High moon trhesholds
if numel(limask) > 0
% if true

%% I05
if useI05
    fileCorr = strcat(outfile,'_xcorr');
else
    fileCorr = strcat(outfile,'_xcorr4');
end

if checkpointFlag && exist(fileCorr, 'file') == 2
    imageCorr = freadenvi(fileCorr);
else
    
    imageCorr = ones(size(imageI05)) * 2;
    
    disp_progress; % Just to show progress
    
    for i=1+XCORR_WIN:dnblines-XCORR_WIN
        disp_progress(i, dnblines);
        
        subimageI05 = imageI05(i-XCORR_WIN:i+XCORR_WIN,:);
        subimageDNB = imageDNB(i-XCORR_WIN:i+XCORR_WIN,:);
        subimageDNB(subimageDNB <= MISSINGVALUE) = NaN;
        
        [mm,nn] = size(subimageI05);
        
        colI05 = im2col(subimageI05,[2*XCORR_WIN+1,2*XCORR_WIN+1]);
        colDNB = im2col(subimageDNB,[2*XCORR_WIN+1,2*XCORR_WIN+1]);
        
        %         size(colI05)
        
        colCorr = corr_col(colI05,colDNB);
        subimageCorr = reshape(colCorr,mm-2*XCORR_WIN,nn-2*XCORR_WIN);
        
        %         size(subimageCorr)
        
        imageCorr(i,XCORR_WIN+1:end-XCORR_WIN) = subimageCorr;
    end
    
    % get rid of NaNs
    nanind = find(isnan(imageCorr));
    imageCorr(nanind) = 2;
    
    if checkpointFlag || dumpFlag
        info=enviinfo(single(imageCorr));
        enviwrite(single(imageCorr),info,fileCorr);
    end
end

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'xcorr';   
disp(['DNB vs I05 correlator time ', num2str(usedTime), ' memory ', num2str(usedMemory)])

% figure
% histogram(imageCorr(:))

if visFlag
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','SMI tails by LI zone')
end

smitop = zeros(length(edges)-1,1);
knntop = zeros(length(edges)-1,1);
sigmasmi = zeros(length(edges)-1,1);
adaptXcorrLim = -0.6 * ones(length(edges)-1,1);
smitype = zeros(length(edges)-1,1); % 0 - low moon, 1 - sigmoid, 2 - adaptive, 3 - lenticular
smishape = zeros(length(edges)-1,1); % center of mass of the SMI cloud
for i = 1:length(edges)-1

%     lenticind = find(loglimage >= edges(i) & loglimage < edges(i+1) & slval > 0 & imgfilt < 0 & glint_map == 0 & imageCorr ~= 2);
    lenticind = find(loglimage >= edges(i) & loglimage < edges(i+1) & slval > 0 & imgfilt < 0 & hotspot == 0 & imageCorr ~= 2);
    sigmasmi(i) = 0.05 + 0.55 * sigmf(edges(i+1),[3 -1.7]);
    smishape(i) = sum(imgfilt(lenticind).^2.*imageCorr(lenticind)) / sum(imgfilt(lenticind).^2);
    if ~isnan(smishape(i))
        adaptXcorrLim(i) = smishape(i);
    end
    
%     cloudtopind = find(imageCorr < adaptXcorrLim(i) & loglimage >= edges(i) & loglimage < edges(i+1) & slval > 0 & imgfilt ~= 0 & limage > MOONLIT & glint_map == 0);
    cloudtopind = find(imageCorr < adaptXcorrLim(i) & loglimage >= edges(i) & loglimage < edges(i+1) & slval > 0 & imgfilt ~= 0 & limage > MOONLIT & hotspot == 0);
%     tailind = find(imageCorr < adaptXcorrLim(i) & loglimage >= edges(i) & loglimage < edges(i+1) & slval > 0 & imgfilt > 6 * std(imgfilt(cloudtopind)) & limage > MOONLIT & glint_map == 0);
    tailind = find(imageCorr < adaptXcorrLim(i) & loglimage >= edges(i) & loglimage < edges(i+1) & slval > 0 & imgfilt > 6 * std(imgfilt(cloudtopind)) & limage > MOONLIT & hotspot == 0);
%     length(tailind)
    cloudtopind1side = find(imgfilt < 0 & loglimage >= edges(i) & loglimage < edges(i+1) & slval > 0);
%     lentailind = find(loglimage >= edges(i) & loglimage < edges(i+1) & slval > 0 & imgfilt < -6 * std(imgfilt(cloudtopind1side)) & glint_map == 0);
    lentailind = find(loglimage >= edges(i) & loglimage < edges(i+1) & slval > 0 & imgfilt < -6 * std(imgfilt(cloudtopind1side)) & hotspot == 0);
    length(lentailind)

    imgtest = imgfilt(tailind);
    [knndx,ix] = sortdknn(imgtest,10);
    if isempty(cloudtopind) || length(cloudtopind) < round(numel(limage)/(NLI-1)/100) % less than 10 percent of the stripe
        smitop(i) = 0.05 + 0.55 * sigmf(edges(i+1),[3 -1.7]);
        smitype(i) = 1;
        fprintf('Sigmoid threshold %g for the LI zone %d\n',smitop(i),i);
    elseif smishape(i) > SMI_SHAPE_THR
        fprintf('Lenticular SMI vs xCorr scatterplot %g for the LI zone %d\n',smishape(i),i);
        imgtest = abs(imgfilt(lentailind));
        [knndx,ix] = sortdknn(imgtest,10);      
        if length(find(knndx < LENT_KNN_THR)) == 0 || max(knndx) < LENT_KNN_THR
            knntop(i) = max(imgfilt(lentailind)) * (1 + SMI_DELTA);
            fprintf('Max of scatterplot used for SMI threshold\n');
        else
            coresmi = find(knndx < LENT_KNN_THR);
            knntop(i) = max(imgtest(ix(coresmi))) * (1 + SMI_DELTA);
%             knnsmi = imgtest(ix);
%             knntable = table(knnsmi,knndx);
%             writetable(knntable,['local_density_li_', num2str(i), '.csv']);
        end

%         smitop(i) = NsigmaCloud * std(imgfilt(lenticind));
        smitop(i) = knntop(i) * (1 + SMI_DELTA);
        smitype(i) = 3;
        limask = find(limage ~= FILLVALUE & limage > MOONLIT & log10(limage) >= edges(i) & log10(limage) < edges(i+1) & spikeThreshFix < smitop(i));
        lizones(limask) = i;
        thrzones(limask) = smitype(i);
        spikeThreshAbs(limask) = smitop(i);
        fprintf('Lenticular threshold %g for the LI zone %d\n',smitop(i),i);
    else
        if length(find(knndx < KNN_THR)) == 0 || max(knndx) < KNN_THR
            knntop(i) = max(imgfilt(cloudtopind));
        else
            coresmi = find(knndx < KNN_THR);
            knntop(i) = max(imgtest(ix(coresmi)));
%             knnsmi = imgtest(ix);
%             knntable = table(knnsmi,knndx);
%             writetable(knntable,['local_density_li_', num2str(i), '.csv']);
        end

        smitop(i) = knntop(i) * (1 + SMI_DELTA);
        smitype(i) = 2;
        limask = find(limage ~= FILLVALUE & limage > MOONLIT & log10(limage) >= edges(i) & log10(limage) < edges(i+1) & spikeThreshFix < smitop(i));
        lizones(limask) = i;
        thrzones(limask) = smitype(i);
        spikeThreshAbs(limask) = smitop(i);
        fprintf('Adaptive threshold %g for the LI zone %d\n',smitop(i),i);
    end
    
    if visFlag
       subplot(2,(numel(edges)-1)/2,i)
       hist(imgfilt(cloudtopind),50)
%        histogram(imgfilt(cloudtopind),50,'Normalization','probability');
%         [histtally, histedges] = histcounts(imgfilt(cloudtopind))
%         histtally = [0,histtally]';
%         histedges = histedges';
%         histtab = table(histtally, histedges);
%         writetable(histtab,[outfile '_li_zone_' num2str(i) '.hist.csv'])
        hold on
        plot(imgtest(ix),10*knndx)
        vline(smitop(i),'k')
        vline(-smitop(i),'k')
        vline(sigmasmi(i),'b')
        vline(-sigmasmi(i),'b')
        vline(knntop(i),'r')
        vline(-knntop(i),'r')
        set(gca,'xlim',[0,0.5]);
        title(['log(LI) ' num2str(edges(i)) ' to ' num2str(edges(i+1))])
    end
    
    metadata(i).smishape = smishape(i);
    metadata(i).lentictally = length(lenticind);
end

% merge LI zones
for i = 1:length(edges)-1
    if smitype(i) == 1 && (i > 1 && smitype(i-1) == 2 || i < length(edges)-1 && smitype(i+1) == 2)      
        if i > 1 && smitype(i-1) == 2
            smitop(i) = smitop(i-1);
            smitype(i) = 2;
            limask = find(limage ~= FILLVALUE & limage > MOONLIT & log10(limage) >= edges(i) & log10(limage) < edges(i+1) & spikeThreshFix < smitop(i));
            lizones(limask) = i-1;
            metadata(i).lizone = (i-1)*10; % to indicate that the zone was merged
            spikeThreshAbs(limask) = smitop(i);
            disp(['merging with lower LI zone at ' num2str(i)])
        elseif i < length(edges)-1 && smitype(i+1) == 2
            smitop(i) = smitop(i+1)
            smitype(i) = 2;
            metadata(i).lizone = (i+1)*10; % to indicate that the zone was merged
            limask = find(limage ~= FILLVALUE & limage > MOONLIT & log10(limage) >= edges(i) & log10(limage) < edges(i+1) & spikeThreshFix < smitop(i));
            lizones(limask) = i+1;
            spikeThreshAbs(limask) = smitop(i);
            disp(['merging with upper LI zone at ' num2str(i)])
        end
    end 
    
    metadata(i).smitype = smitype(i);
    metadata(i).smitop = smitop(i);
end

spikeThreshRel = spikeThreshAbs;
corrmask = find(limage ~= FILLVALUE & limage > MOONLIT & imageCorr > XcorrLim & imageCorr < 2 & lizones < NLI & thrzones < 3);
spikeThreshRel(corrmask) = spikeThreshAbs(corrmask) .* (A * imageCorr(corrmask) + B);
spikeThreshRel(spikeThreshRel < spikeThreshFix) = spikeThreshFix(spikeThreshRel < spikeThreshFix);

dnbspk(imgfilt > spikeThreshRel) = 1;
dnbspk(imgfilt > spikeThreshAbs) = 2;

% ignore all detections for the moonlit imageCorr < -0.7
ignoremask = find(limage ~= FILLVALUE & limage > MOONLIT & imageCorr <= XcorrLim & lizones < NLI);
dnbspk(ignoremask) = 0;

clear ignoremask

if dumpFlag
    info=enviinfo(spikeThreshRel);
    enviwrite(spikeThreshRel,info,[outfile '.thr_adaptive']);
    
    info=enviinfo(spikeThreshAbs);
    enviwrite(spikeThreshAbs,info,[outfile '.thr_strong']);
    
    info=enviinfo(uint8(lizones));
    enviwrite(uint8(lizones),info,[outfile '.li_zones']);

    info=enviinfo(uint8(thrzones));
    enviwrite(uint8(thrzones),info,[outfile '.thr_zones']);
end

if visFlag
    x = -4:0.1:0;
    y = 0.05 + 0.55 * sigmf(x,[3 -1.7]);
    limli = limage(slval > 0) > MOONLIT;
    logli = log10(limage(slval > 0));
    spkli = dnbspk(slval > 0);
    smili = imgfilt(slval > 0);
    xcorli = imageCorr(slval>0);
%     size(glinttop)
%     size(imgfilt(slval > 0))
%     glintli = glint_map(slval > 0) & imgfilt(slval > 0) < glinttop & limli;
    if glinttop > 0
        glintli = glint_map(slval > 0) & ~hotspot(slval > 0) & imgfilt(slval > 0) < glinttop & limli;
        hotspotli = hotspot(slval > 0) & imgfilt(slval > 0) < glinttop & limli;
    else
        glintli = zeros(size(limli));
        hotspotli = zeros(size(limli));
    end
    
    sqli = sqmask(slval > 0);
    
    scrsz = get(0,'ScreenSize');
    figsigma = figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','SMI vs LI with thresholds');
    
    LT = 4;
    plot(logli,smili,'b.')
    hold on
    plot(x,y,'LineWidth', LT)
    plot(x,-y,'LineWidth', LT)
    for i = 1:length(edges)-1
        plot([edges(i),edges(i+1)],[smitop(i),smitop(i)],'LineWidth', LT)
        plot([edges(i),edges(i+1)],[-smitop(i),-smitop(i)],'LineWidth', LT)
    end
    set(gca,'xlim',[-4, -1]);
    xlabel('log10(LI)')
    ylabel('SMI')
    title(['Xcorr > ',num2str(XcorrLim)])
    print(figsigma,'-dpng','-r0',[outfile,'-xcorrsmiglint.png']);
    
    scrsz = get(0,'ScreenSize');
    figxcorrsmi = figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','xCorr vs SMI scatterplots');
    for i = 1:numel(edges)-1
        y = -1:0.1:1;
        %         x = smitop(i) * (-0.25 * y + 0.75);
        x = smitop(i) * (A * y + B);
        
        iind = find(logli > edges(i) & logli < edges(i+1));
        gliind = find(logli > edges(i) & logli < edges(i+1) & glintli);
        noiseind = find(logli > edges(i) & logli < edges(i+1) & spkli > 0);
        hotspotind = find(logli > edges(i) & logli < edges(i+1) & hotspotli);
        
        sqind = find(logli > edges(i) & logli < edges(i+1) & spkli > 0 & sqli > 0);
        
        subplot(1,numel(edges)-1,i)
        plot(smili(iind),xcorli(iind),'.')
        hold on
        plot(smili(gliind),xcorli(gliind),'g.')
        plot(smili(hotspotind),xcorli(hotspotind),'r.')
        
        plot(smili(sqind),xcorli(sqind),'ko')
        
        plot(x,y,'k--')
        plot(-x,y,'k--')
        vline(0.05 + 0.55 * sigmf(edges(i+1),[3 -1.7]),'b');
        vline(-0.05 - 0.55 * sigmf(edges(i+1),[3 -1.7]),'b');
        vline(smitop(i),'k');
        vline(-smitop(i),'k');
        vline(knntop(i),'r')
        vline(-knntop(i),'r')
        hline(XcorrLim,'r');
        hline(adaptXcorrLim(i),'k');
        set(gca,'xlim',[-0.5,0.5],'ylim',[-1,1])
        title(['COM = ' num2str(smishape(i))])
    end
    %     figxcorrsmi.PaperPositionMode = 'auto';
    set(gcf,'PaperPositionMode','auto');
    print(figxcorrsmi,'-dpng','-r0',[outfile,'-xcorrsmiglint.png']);
end

% return

if visFlag
    BW = zeros(size(imageDNB));
    if localmaxFlag
        BW = imregionalmax(imageDNB,4).*(dnbspk>0);
    elseif ndnbspk > 0
        BW = dnbspk > 0;
    end
%     BW = imregionalmax(stretchDNB.*(dnbspk > 0),4);
    [r,c] = find(BW);
    
    scrsz = get(0,'ScreenSize');
    figure('Position',[1 1 scrsz(3) scrsz(4)],'Name','Detector dashboard');
    
    subplot(2,2,1)
    imagesc(stretchDNB)
    hold on
    plot(c,r,'r+')
    axis image
    colormap('gray');
    colorbar;
    title('Input image after stretch X 10');
    
    subplot(2,2,2)
%     imagesc(s1_map)
    imagesc(lizones)
%     imagesc(thrzones)
%     imshow(imageCorr,[-1,1])
    axis image
    colormap('gray');
    colorbar;
%     title('Sharpnes map');
    title('LI zones');
%     title('Thresholding method zones');
%     title('xCorr');
    
    subplot(2,2,3)
    imagesc(spikeThreshRel)
    axis image
    colormap('gray');
    colorbar;
    title('SMI threshold');
    
    subplot(2,2,4)
    imagesc(glintdata.*glint_map)
    axis image
    colormap('gray');
    colorbar;
    title('Glint probability');
    
    linkaxes
    zoom on
end

if dumpFlag
    %     info=enviinfo(dnbspk);
    %     enviwrite(dnbspk,info,[outfile '.smi']);
    info=enviinfo(imgfilt);
    enviwrite(imgfilt,info,[outfile '.smi']);
end

if false
    smiset = imgfilt(sqmask & dnbspk > 0);
    glintset = glintdata(sqmask & dnbspk > 0);
    xcorrset = imageCorr(sqmask & dnbspk > 0);

    figure
    plot(smiset(:),glintset(:),'r.')
    hold on
    plot(smiset(glintset < 0.07),glintset(glintset < 0.07),'bo')
    xlabel('SMI')
    ylabel('Glint')
    title('Glint vs SMI')

    figure
    plot(smiset(:),xcorrset(:),'r.')
    hold on
    plot(smiset(glintset < 0.07),xcorrset(glintset < 0.07),'bo')
    xlabel('SMI')
    ylabel('Xcorr')
    title('Xcorr vs SMI')

    figure
    plot(glintset(:),xcorrset(:),'r.')
    hold on
    plot(glintset(glintset < 0.07),xcorrset(glintset < 0.07),'bo')
    xlabel('Glint')
    ylabel('Xcorr')
    title('Xcorr vs Glint')
    
end

else % low moon case
    
    dnbspk(imgfilt > spikeThreshAbs) = 2;
    
end % of high moon thresholding

%% ignore all detections at the terminator and missing scan boundary
se = strel('disk',2);        

sunlitmask = ones(size(dnbspk));
sunlitmask(sunlit) = 0;
sunlitmask = imerode(sunlitmask,se);
dnbspk(~sunlitmask) = 0;

clear sunlitmask sunlit

realDNB = dnblats > -999 & realDNB;
realDNB = imerode(realDNB,se);
dnbspk(~realDNB) = 0;

clear realDNB
% disp('Ignored detections at the terminator and missing scan boundaries')

ndnbspk = numel(find(dnbspk));
% ndnbspkcorr = numel(find(dnbspk == 1));
% ndnbspkabs = numel(find(dnbspk == 2));

if ndnbspk == 0
    warning('No SMI spikes found')
end

%% Build SHI map
% disp('Before SHI spikeind');
spike_map = spikeind(imageDNB);
% disp('After SHI spikeind');

if false
    figure
    hist(spike_map(spike_map > 0),100);
    xlabel('Spike Index')
    
    figure
    plot(imageDNB(spike_map > 0),spike_map(spike_map > 0),'.')
    xlabel('DNB radiance')
    ylabel('Spike Index')
    
end

if dumpFlag
    info=enviinfo(spike_map);
    enviwrite(spike_map,info,[outfile '.shi']);
end

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'shi';
disp(['Spike detector time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

%% Build VNF flare list
flare_map = zeros(size(imageDNB));
nvnfs = vnfmap.length();
if ndnbspk > 0 && nvnfs > 0
    TC = [];
    grannames = vnfmap.values();
    vnfname = '';
    for i = 1:nvnfs
        if ~cellfun('isempty',grannames(i)) && ~strcmp(char(grannames(i)),vnfname) % do not duplicate in the table
            vnfname = char(grannames(i));
            disp(['Using VNF detections from ', vnfname]);
            %         try
            C = csvimport(vnfname);
            csvhead = char(C(1,:));
            fprintf('Found %6d sources in CSV file %s\n',size(C,1)-1,vnfname);
            ndtct = size(C,1) - 1;
            % size(C)
            if(ndtct > 0) % not only header, has detections
                TC = [TC;C(2:ndtct+1,:)];
            end
            % disp('VNF CSV read')
        end
    end
    
    if ~isempty(TC) && size(TC,1) > 1
        idind = strmatch('id',csvhead,'exact');
        id =  cell2mat(TC(:,idind));
        
        idkeyind = strmatch('id_Key',csvhead,'exact');
        id_key = char(TC(:,idkeyind));
        
        lineind = strmatch('Line_M10',csvhead,'exact');
        line = cell2mat(TC(:,lineind));
        
        sampleind = strmatch('Sample_M10',csvhead,'exact');
        sample = cell2mat(TC(:,sampleind));
        
        linebtind = strmatch('Line_BT',csvhead,'exact');
        linebt = cell2mat(TC(:,linebtind));
        
        samplebtind = strmatch('Sample_BT',csvhead,'exact');
        samplebt = cell2mat(TC(:,samplebtind));
        
        linednbind = strmatch('Line_DNB',csvhead,'exact');
        linednb = cell2mat(TC(:,linednbind));
        
        samplednbind = strmatch('Sample_DNB',csvhead,'exact');
        samplednb = cell2mat(TC(:,samplednbind));
        
        latind = strmatch('Lat_GMTCO',csvhead,'exact');
        lat = cell2mat(TC(:,latind));
        
        lonind = strmatch('Lon_GMTCO',csvhead,'exact');
        lon = cell2mat(TC(:,lonind));
        
        qfdetectind = strmatch('QF_Detect',csvhead,'exact');
        qfdetect = cell2mat(TC(:,qfdetectind));
        
        qffitind = strmatch('QF_Fit',csvhead,'exact');
        qffit = cell2mat(TC(:,qffitind));
        
        m10ind = strmatch('Rad_M10',csvhead,'exact');
        m10 = cell2mat(TC(:,m10ind));
        
        rhiind = strmatch('RHI',csvhead,'exact');
        rhi = cell2mat(TC(:,rhiind));
        
        bbtempind = strmatch('Temp_BB',csvhead,'exact');
        bbtemp = cell2mat(TC(:,bbtempind));
        
        bkgtempind = strmatch('Temp_Bkg',csvhead,'exact');
        bkgtemp = cell2mat(TC(:,bkgtempind));
        
        rhind = strmatch('RH',csvhead,'exact');
        rh = cell2mat(TC(:,rhind));
        
        methaneind = strmatch('Methane_EQ',csvhead,'exact');
        methane = cell2mat(TC(:,methaneind));
        
        co2ind = strmatch('CO2_EQ',csvhead,'exact');
        co2 = cell2mat(TC(:,co2ind));
        
        footprintind = strmatch('Area_BB',csvhead,'exact');
        footprint = cell2mat(TC(:,footprintind));
        
        cloudind = strmatch('Cloud_Mask',csvhead,'exact');
        cloud = cell2mat(TC(:,cloudind));
        
        datemscanind = strmatch('Date_Mscan',csvhead,'exact');
        datemscan = char(TC(:,datemscanind));
        
        m10fileind = strmatch('File_M10',csvhead,'exact');
        m10file = char(TC(:,m10fileind));
        
        acfileind = strmatch('File_AC',csvhead,'exact');
        acfile = char(TC(:,acfileind));
        
        latgringind = strmatch('Lat_Gring',csvhead,'exact');
        latgring = char(TC(:,latgringind));
        
        longringind = strmatch('Lon_Gring',csvhead,'exact');
        longring = char(TC(:,longringind));
        
        cc = bwconncomp(dnbspk);
        ccprops = regionprops(cc, 'PixelList', 'Centroid');
        
        dnblist = [samplednb,linednb];
        vnflist = zeros(size(samplednb));
        % size(dnblist)
        
        for k = 1:cc.NumObjects
            ccprops(k).isIR = false;
            pixellist = ccprops(k).PixelList;
            [C,ia,ib] = intersect(dnblist,pixellist,'rows');
            %     if true
            if ~isempty(C)
                ccprops(k).isIR = true;
                vnflist(ia) = k;
                for l = 1:size(C,1)
                    flare_map(C(l,2),C(l,1)) = k;
                end
            end
        end
        
        isIR = [ccprops.isIR];
        ccLabel = labelmatrix(cc);
        ccIR = ismember(ccLabel,find(isIR));
        
        if false
            scrsz = get(0,'ScreenSize');
            figure('Position',[1 1 scrsz(3) scrsz(4)]);
            
            subplot(1,2,1)
            imagesc(stretchDNB)
            set(gca,'xtick',[],'ytick',[])
            axis image
            colormap('gray');
            freezeColors
            colorbar;
            title('DNB image');
            
            % s1_thr = min(s1_map(:) < 0.1);
            % s1_map(s1_thr) = 0;
            
            subplot(1,2,2)
            imagesc(flare_map)
            set(gca,'xtick',[],'ytick',[])
            axis image
            colormap('gray');
            freezeColors
            colorbar;
            title('Flare map');
            
            linkaxes
            zoom on
        end
        
    end
    
    usedTime = toc;
    usedMemory = rtime.totalMemory - rtime.freeMemory;
    stepnum = stepnum + 1;
    tmemprof(stepnum).mem = usedMemory;
    tmemprof(stepnum).time = usedTime;
    tmemprof(stepnum).step = 'vnf';
    disp(['Flares CSV parsed time ' num2str(usedTime) ' memory ' num2str(usedMemory)])
    
end

%% check for local max
BW = zeros(size(imageDNB));
% BWLM = imregionalmax(imageDNB.*(dnbspk>0),4);
BWLM = imregionalmax(imageDNB,4).*(dnbspk>0);
if ndnbspk > 0 && localmaxFlag
    BW = BWLM;
    disp('Checking for local maxima')
elseif ndnbspk > 0
    BW = dnbspk > 0;
end

%% debug output for a single pixel
if false
%    dsample = 134;
%    dline = 700;
   dsample = 2963;
   dline = 556;
   disp('Single pixel stats');
   sout = sprintf(' Pixel Line=%d',dline);
   disp(sout);
   sout = sprintf(' Sample=%d',dsample);
   disp(sout);
   sout = sprintf(' SMI=%d',imgfilt(dline,dsample));
   disp(sout);
   sout = sprintf(' spikeThreshAbs=%d',spikeThreshAbs(dline,dsample));
   disp(sout);
   sout = sprintf(' spikeThreshRel=%d',spikeThreshRel(dline,dsample));
   disp(sout);
   sout = sprintf(' SHI=%d',spike_map(dline,dsample));
   disp(sout);
   sout = sprintf(' SI=%d',s1_map(dline,dsample));
   disp(sout);
   sout = sprintf(' DNB=%d',imageDNB(dline,dsample));
   disp(sout);
   sout = sprintf(' Lat=%d',dnblats(dline,dsample));
   disp(sout);
   sout = sprintf(' Pixel Lon=%d',dnblons(dline,dsample));
   disp(sout);
   sout = sprintf(' L/S mask=%d',slval(dline,dsample));
   disp(sout);
   sout = sprintf(' LI=%d',limage(dline,dsample));
   disp(sout);
   sout = sprintf(' LI zone=%d',lizones(dline,dsample));
   disp(sout);
   sout = sprintf(' Glint=%d',glintdata(dline,dsample));
   disp(sout);
   sout = sprintf(' xCorr=%d',imageCorr(dline,dsample));
   disp(sout);
   sout = sprintf(' dnbspk=%d',dnbspk(dline,dsample));
   disp(sout);
%    return
end

%%
[r,c] = find(BW);
coords = zeros(length(r),26);
isOcean = zeros(length(r),1);
isBoat = zeros(length(r),1);
isFlare = zeros(length(r),1);
idkeys = cell(length(r),1);
bridgeid = cell(length(r),1);
eeznames = cell(length(r),1);
fmznames = cell(length(r),1);
mpanames = cell(length(r),1);
ltzones = ones(length(r),1) * FILLVALUE;
boattype = zeros(length(r),1);

%% fix glint map
if false
glintspikes = find(imgfilt < glinttop & glint_map > 0 & slval > 0 & BW);
length(glintspikes)
% glintspikes = find(imgfilt > 0.15 & glint_map > 0 & slval > 0);
glintDNBthr = FILLVALUE;
if ~isempty(glintspikes)
    glintDNBthr = max(imageDNB(glintspikes));
    
    dnbtest = imageDNB(glintspikes);
    [knndx,ix] = sortdknn(dnbtest,10);
    if length(find(knndx < DNB_KNN_THR)) == 0 || max(knndx) < DNB_KNN_THR
        disp('Short tail distribution, thus using maximum as a threshold');
    else
        corednb = find(knndx < DNB_KNN_THR);
        glintDNBthr = max(dnbtest(ix(corednb)));
    end        
    disp(['Found ',num2str(length(glintspikes)),' glint spikes with DNB max ',num2str(glintDNBthr)])
    
    if false
        figure('Name','Local density vs DNB')
        plot(dnbtest(ix),knndx)
        xlabel('DNB')
        ylabel('Local density')

        figure('Name','Glint vs DNB')
        plot(glintdata(glintspikes),imageDNB(glintspikes),'.')
        hold on
        hline(glintDNBthr)
        xlabel('Glint')
        ylabel('DNB')
    end
end
end

%% watershed
if true

% THR = 0.2;
THR = 2;
MAX_DNB_WS = 50;

imageLSM = slval;
imageSHI = spike_map;
nanind = find(isnan(imageLSM));
imageLSM(nanind) = 0; % fix NaN values in land-sea mask

imageIn = double((imageDNB) .* imageLSM);
imageBW = imageIn > 0;

% Create image for circles around large flares
imageSizeX = size(imageIn,2);
imageSizeY = size(imageIn,1);
[columnsInImage rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);

% check local minimums
imageDist = -imageIn;
locminBW = imextendedmin(imageDist,THR,8);
s  = regionprops(locminBW, 'centroid');
centroids = cat(1, s.Centroid);

% fprintf('Number of watershed centroinds = %d\n',size(centroids,1))
% round centroid coordinates
for i = 1:size(centroids,1)
    mlines(i) = round(centroids(i,2)) - 1;
    msamples(i) = round(centroids(i,1)) - 1;
end

imageDist = imimposemin(imageDist,locminBW);
imageLabel = uint16(watershed(imageDist,8));
linewts = [];
samplewts = [];
clear imageDist
imageLabel(~imageBW) = 0;
% background = find(imageLabel(:) < 2);
% bkgsum = sum(imageLabel(background))

if min(imageLabel(:)) == max(imageLabel(:))
    warning('No data in watershed output')
    imageLabel(:) = uint16(0);
else
    imageLabel(~imageBW)=0;
    [rlabel,clabel] = find((imageLabel > 0) & (locminBW ~= 0));
    imageLabelMask = uint16(bwselect(imageLabel, clabel, rlabel));
    imageLabel = imageLabelMask .* imageLabel;
    clear imageLabelMask
    
    % find cluster boundaries
    stats = regionprops(imageLabel,'PixelIdxList');
    
    nstats = length(stats);
    
    disp_progress;
    t = 0;
    for t1 = 1:nstats
        disp_progress(t1, nstats);
        
        %                 idxlist = stats(s+1).PixelIdxList;
        idxlist = stats(t1).PixelIdxList;
        if length(idxlist) == 0 || max(imageIn(idxlist)) < MAX_DNB_WS
            imageLabel(idxlist) = 0;
            continue
        end
        t = t+1;
        
        countm10(t) = length(idxlist);
        summ10(t) = sum(imageIn(idxlist));
        [maxtmp, indmaxtmp] = max(imageIn(idxlist));      
        maxm10(t) = maxtmp;
        [centerY,centerX] = ind2sub(size(imageIn),idxlist(indmaxtmp));
        
        radius = 3*log10(imageDNB(idxlist(indmaxtmp)))./imageSHI(idxlist(indmaxtmp));
        circlePixels = (rowsInImage - centerY).^2 ...
            + (columnsInImage - centerX).^2 <= radius.^2;
        % circlePixels is a 2D "logical" array.        
        
        imageLabel(idxlist) = imageLabel(idxlist) & circlePixels(idxlist);
        
        linewts(t) = centerY;
        samplewts(t) = centerX;
    end
end
% add boundaries to the watershed intersections with circles
boundaries = rangefilt(imageLabel,ones(5)) > 0;

maxqf2ind = sub2ind(size(imageLabel),linewts,samplewts);

imageLabel(maxqf2ind) = 0;
boundaries(maxqf2ind) = 0;

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'wtr';
disp(['Found ' num2str(max(imageLabel(:))) ' watershed label(s) time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

end

%%
if visFlag
    figure(blurfig);
    subplot(dnbsubplot);
    hold on;
end

count = 0;
disp_progress; % Just to show progress
ilimit = length(r);
for i = 1:ilimit
    disp_progress(i, ilimit);
    lat = dnblats(r(i),c(i));
    lon = dnblons(r(i),c(i));
    dnb = imageDNB(r(i),c(i));
    thr = dnbspk(r(i),c(i));
    if streakDNB(r(i),c(i)) == 0 && ...
            thndrDNB(r(i),c(i)) < LIGHTNING_LENGTH && ...
            r(i) > 1 && r(i) < dnblines && c(i) > 2 && c(i) < dnbcols && ...
            lat < latLonLimits(2) && lat > latLonLimits(1) && ...
            lon < latLonLimits(4) && lon > latLonLimits(3)
        % % %         val = ltln2val(Z, R, lat, lon);
        % % %         isOcean(i) = val == 2;
        %         val = ltln2val(lwmask, Rwin, lat, lon);
        val = slval(r(i), c(i));
        isOcean(i) = val > 0 ;
        if isOcean(i) == 1
            %         if true
            coords(i,1) = lat;
            coords(i,2) = lon;
            coords(i,3) = dnb;
            coords(i,5) = s1_map(r(i),c(i));
            coords(i,6) = spike_map(r(i),c(i));
            scan = idivide(int32(r(i)),16,'ceil');
            
%             coords(i,7) = midtime(scan);
            datecorr = tai2utc(tai,midtime(scan));
            coords(i,7) = datecorr;
            coords(i,8) = r(i);
            coords(i,9) = c(i);
            coords(i,10) = val;
            coords(i,11) = imgfilt(r(i),c(i));
            coords(i,12) = spikeThreshRel(r(i),c(i));
            coords(i,13) = coords(i,13) + SMI_FLAG;
            coords(i,14) = limage(r(i),c(i));
            if imageCorr(r(i),c(i)) < 2
                coords(i,15) = imageCorr(r(i),c(i));
            else
                coords(i,15) = FILLVALUE;
            end

            coords(i,20) = solarzenithdata(r(i),c(i));
            coords(i,21) = solarazimuthdata(r(i),c(i));
            coords(i,22) = satellitezenithdata(r(i),c(i));
            coords(i,23) = satelliteazimuthdata(r(i),c(i));
            coords(i,24) = lunarzenithdata(r(i),c(i));
            coords(i,25) = lunarazimuthdata(r(i),c(i));
            coords(i,26) = imageI05(r(i),c(i));
                        
            if imgfilt(r(i),c(i)) > glinttop && glint_map(r(i),c(i)) || ~glint_map(r(i),c(i))
                if thr == 2
                    coords(i,13) = coords(i,13) + ABS_FLAG;
                    boattype(i) = 2;
                else
                    boattype(i) = 1;
                end
            end
            
            saaflag = false;
            if ~isempty(saa) && imgfilt(r(i),c(i)) < Ysaa(c(i)) % check if the spike is inside SAA poligon
                saaid = interpshapefile(saa, coords(i,1), coords(i,2), 'ID', 'Y', 'X');
                saaflag = ~isnan(saaid);
            end
            if (spike_map(r(i),c(i)) >= 0.9995 || imgfilt(r(i),c(i)) > 2.4) && dnb > 1500 || saaflag 
                coords(i,13) = coords(i,13) + CR_FLAG;
            end
            
            if slightimg(r(i),c(i))
                coords(i,13) = coords(i,13) + STRAYLIGHT_FLAG;
            end
            
            if s1_map(r(i),c(i)) >= SI && s1_map(r(i),c(i)) < 2
                coords(i,13) = coords(i,13) + SI_FLAG;
            end
            
            if spike_map(r(i),c(i)) >= SHI
                coords(i,13) = coords(i,13) + SHI_FLAG;
            end
            
            if flare_map(r(i),c(i))
                coords(i,13) = coords(i,13) + VNF_FLAG;
            end
            
            if FLARE > 0 && dnb > FLARE
                coords(i,13) = coords(i,13) + FV_FLAG;
            end
            
            flareval = ltln2val(flmask, FLRwin, lat, lon);
            falsef1 = 0;
%             glow = 0;
            glow = imageLabel(r(i),c(i)) || boundaries(r(i),c(i));
            
            flareflag = 0;
            if ~isnan(flareval) && flareval
                falsef1 = bitand(uint32(flareval),uint32(2)); % bitflag 2 in the flaremap raster
                glow = glow || bitand(uint32(flareval),uint32(4)); % bitflag 4 in the flaremap raster
                flareflag = bitand(uint32(flareval),uint32(1)); % bitflag 1 in the flaremap raster
                if flareflag
                    coords(i,13) = coords(i,13) + FM_FLAG;
                end
                if falsef1
                    coords(i,13) = coords(i,13) + FALSEQF1_FLAG;                    
                end
                if glow
                    coords(i,13) = coords(i,13) + GLOW_FLAG;
                    % disp(['Glow pixel found with bitmask ' num2str(flareval)])
                end
            end
            if MOONLIT > 0 && limage(r(i),c(i)) ~= FILLVALUE && limage(r(i),c(i)) > MOONLIT
                coords(i,13) = coords(i,13) + LI_FLAG;
            end
            coords(i,16) = glintdata(r(i),c(i));
            if glint_map(r(i),c(i))
                coords(i,13) = coords(i,13) + GLINT_FLAG;
            end
            coords(i,17) = FILLVALUE;
            if hotspot(r(i),c(i))
                coords(i,13) = coords(i,13) + HOTSPOT_FLAG;
                if glinttop > 0            
                    coords(i,17) = glinttop;
                end
            end
            if lizones(r(i),c(i)) == NLI
                coords(i,13) = coords(i,13) + SIGMA_FLAG;
            end
            if BWLM(r(i),c(i))
                coords(i,13) = coords(i,13) + LOCALMAX_FLAG;
            end
            if thndrDNB(r(i),c(i)) > 0
                coords(i,13) = coords(i,13) + LIGHTNING_FLAG;
                coords(i,19) = thndrDNB(r(i),c(i));
            end
            
            if visFlag
                subplot(dnbsubplot);
            end
            if true
                if flare_map(r(i),c(i)) || FLARE > 0 && dnb > FLARE || ...
                        ~isnan(flareval) && flareflag
                    if visFlag
                        plot(c(i),r(i),'go')
                    end
                    % disp(['Flare flag with dnb ' num2str(dnb)])
                    coords(i,4) = 4; % IR source (flare)
                    isFlare(i) = 1; % real flare
                elseif (spike_map(r(i),c(i)) >= 0.9995 || imgfilt(r(i),c(i)) > 2.4) && dnb > 1500
                    if visFlag
                        plot(c(i),r(i),'mo')
                    end
                    coords(i,4) = 5; % strong cosmic ray                
                elseif hotspot(r(i),c(i)) && (imgfilt(r(i),c(i)) < glinttop)
                    if visFlag
                        plot(c(i),r(i),'co')
                    end
                    coords(i,4) = 6; % moon glint
                elseif saaflag
                    if visFlag
                        plot(c(i),r(i),'mo')
                    end
                    coords(i,4) = 5; % weak cosmic ray                
                elseif s1_map(r(i),c(i)) < SI && spike_map(r(i),c(i)) >=SHI
                    if visFlag
                        plot(c(i),r(i),'y^')
                    end
                    if glow
                        coords(i,4) = 7; % blurry in glow
                    else
                        coords(i,4) = 3; % blurry
                    end
                elseif spike_map(r(i),c(i)) < SHI && s1_map(r(i),c(i)) >= SI 
                    if visFlag
                        plot(c(i),r(i),'b*')
                    end
                    if glow
                        coords(i,4) = 7; % spiky in glow
                    else
                        coords(i,4) = 2; % spiky
                    end
                elseif spike_map(r(i),c(i)) >= SHI && s1_map(r(i),c(i)) >= SI 
                    if visFlag
                        plot(c(i),r(i),'r+')
                    end
                    if falsef1
                        coords(i,4) = 9; % crosstalk
                        % disp('Crosstalk flag')
                    else
                        coords(i,4) = 1;
                        isBoat(i) = 1; % real boat
                        count = count + 1;
                    end
                else
                    if visFlag
                        plot(c(i),r(i),'c+')
                    end
                    if glow
                        coords(i,4) = 7; % spiky in glow
                    else
                        coords(i,4) = 10; % SMI only
                    end
                end
            end
        end
    end
end

bind = find(coords(:,4)>0);
count = length(bind);
if count > MAXSPIKE
    error(['Number of detections ',num2str(count),' exceeds threshold ', num2str(MAXSPIKE)])
end

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'loop';
disp(['Found ' num2str(count) ' detections time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

%% search for recurring platforms
plpDist = ones(size(coords,1),1) * FILLVALUE;
if count > 0 && ~isempty(pfm)
    blats = coords(bind,1);
    blons = coords(bind,2);
    
    for i = 1:length(bind)
        % Point sources description (degrees are assumed)
        lon = [pfm.X];
        lat = [pfm.Y];
        label = [pfm.type];

        % Radius of Earth
        RE = 6371;

        % Convert the array of lat/lon coordinates to Cartesian vectors
        % NOTE: sph2cart expects radians
        % NOTE: use radius 1, so we don't have to normalize the vectors
        [X,Y,Z] = sph2cart( lon*pi/180,  lat*pi/180, 1);

        % Same for your point of interest    
        [xP,yP,zP] = sph2cart( blons(i)*pi/180, blats(i)*pi/180, 1);

        % The minimum distance, and the linear index where that distance was found
        % NOTE: force the dot product into the interval [-1 +1]. This prevents 
        % slight overshoots due to numerical artifacts
        dotProd = xP*X(:) + yP*Y(:) + zP*Z(:);
        [minDist, index] = min( RE*acos( min(max(-1,dotProd),1) ) );

        % Convert that linear index to 2D subscripts
        [ii,jj] = ind2sub(size(lon), index);

        if minDist < PLP_RADIUS
            plpDist(bind(i)) = minDist;
            coords(bind(i),13) = coords(bind(i),13) + PERSIST_FLAG;
%             if ismember(coords(bind(i),4), [1,2,3,10]) && label(index) == 2 ...
%                     && coords(bind(i),10) < 3;
            if ismember(coords(bind(i),4), [1,2,3,10]) && label(index) == 2;
                coords(bind(i),4) = 11; % QF11 for NTL recurring source
%                 disp('Found recurring light')
            elseif ismember(coords(bind(i),4), [1,2,3,10]) && label(index) == 1;
                coords(bind(i),4) = 8; % QF8 for VBD recurring source
%                 disp('Found recurring boat')
            end
        end
    end
    
    % figure('Name','Distance to platform hist')
    % hist(plpDist(plpDist >= 0))
    
    usedTime = toc;
    usedMemory = rtime.totalMemory - rtime.freeMemory;
    stepnum = stepnum + 1;
    tmemprof(stepnum).mem = usedMemory;
    tmemprof(stepnum).time = usedTime;
    tmemprof(stepnum).step = 'rlp';
    disp(['Recurring lights search done time ' num2str(usedTime) ' memory ' num2str(usedMemory)])
end

if count > 0 && ~isempty(brg)
    bind = find(coords(:,4)>0);
    bridgeid = interpshapefile(brg, coords(bind,1), coords(bind,2), 'ID', 'Y', 'X');
    brind = find(~isnan(bridgeid));
    coords(bind(brind),13) = coords(bind(brind),13) + BRIDGE_FLAG;
    brind123 = ismember(coords(bind,4), [1,2,3,8,10,11]) & ~isnan(bridgeid);
    coords(bind(brind123),4) = 11; % QF11 for recurring source in NTL, not a boat
    % may be just remove them later
    
    usedTime = toc;
    usedMemory = rtime.totalMemory - rtime.freeMemory;
    stepnum = stepnum + 1;
    tmemprof(stepnum).mem = usedMemory;
    tmemprof(stepnum).time = usedTime;
    tmemprof(stepnum).step = 'rlv';
    disp(['Bridge vectors search done time ' num2str(usedTime) ' memory ' num2str(usedMemory)])
    
%     for i=1:length(brind)
%        disp(['Bridge lat-lon ',num2str(coords(bind(brind(i)),1)),'/',num2str(coords(bind(brind(i)),2))]);
%        disp(['Bridge line-sample ',num2str(coords(bind(brind(i)),8)),'/',num2str(coords(bind(brind(i)),9))]);
%     end
end

% index to search for vector boundaries EZZ etc.
sind =  find(coords(:,4) == 1 | coords(:,4) == 2 | coords(:,4) == 3 | coords(:,4) == 4 |...
    coords(:,4) == 8 | coords(:,4) == 10 | coords(:,4) == 11);
if length(sind) > 0 && ~isempty(eez)
    eeznames(sind) = interpshapefile(eez, coords(sind,1), coords(sind,2), 'EEZ', 'Y', 'X');
    
    usedTime = toc;
    usedMemory = rtime.totalMemory - rtime.freeMemory;
    stepnum = stepnum + 1;
    tmemprof(stepnum).mem = usedMemory;
    tmemprof(stepnum).time = usedTime;
    tmemprof(stepnum).step = 'eez';
    disp(['EZZ name search done time ' num2str(usedTime) ' memory ' num2str(usedMemory)])
end

if length(sind) > 0 && ~isempty(fmz)
    fmznames(sind) = interpshapefile(fmz, coords(sind,1), coords(sind,2), 'CATEGORY', 'Y', 'X');
    
    usedTime = toc;
    usedMemory = rtime.totalMemory - rtime.freeMemory;
    stepnum = stepnum + 1;
    tmemprof(stepnum).mem = usedMemory;
    tmemprof(stepnum).time = usedTime;
    tmemprof(stepnum).step = 'fmz';
    disp(['FMZ name search done time ' num2str(usedTime) ' memory ' num2str(usedMemory)])
end

if length(sind) > 0 && ~isempty(mpa)
    mpanames(sind) = interpshapefile(mpa, coords(sind,1), coords(sind,2), 'CATEGORY', 'Y', 'X');
    
    usedTime = toc;
    usedMemory = rtime.totalMemory - rtime.freeMemory;
    stepnum = stepnum + 1;
    tmemprof(stepnum).mem = usedMemory;
    tmemprof(stepnum).time = usedTime;
    tmemprof(stepnum).step = 'mpa';
    disp(['MPA name search done time ' num2str(usedTime) ' memory ' num2str(usedMemory)])
end

dtctind = find(coords(:,4) > 0);
if ~isempty(dtctind) && ~isempty(ltz)
    ltzones(dtctind) = interpshapefile(ltz, coords(dtctind,1), coords(dtctind,2), 'ZONE', 'Y', 'X');
    
    usedTime = toc;
    usedMemory = rtime.totalMemory - rtime.freeMemory;
    stepnum = stepnum + 1;
    tmemprof(stepnum).mem = usedMemory;
    tmemprof(stepnum).time = usedTime;
    tmemprof(stepnum).step = 'ltz';
    disp(['Local time zones search done time ' num2str(usedTime) ' memory ' num2str(usedMemory)])
end

if false
    figure
    hist(coords(isBoat == 1,3),100)
end

% procdate = datestr(now,'yyyy/mm/dd HH:MM:SS');
procdate = local_time_to_utc( now, 31 );

[pathEEZ,nameEEZ,extEEZ] = fileparts(fileEEZ);
[pathFMZ,nameFMZ,extFMZ] = fileparts(fileFMZ);
[pathMPA,nameMPA,extMPA] = fileparts(fileMPA);
[pathFLM,nameFLM,extFLM] = fileparts(fileFLM);
[pathLSM,nameLSM,extLSM] = fileparts(fileLSM);
[pathLTZ,nameLTZ,extLTZ] = fileparts(fileLTZ);
[pathPLP,namePLP,extPLP] = fileparts(fileRLP);
[pathPLV,namePLV,extPLV] = fileparts(fileRLV);

dnbnames = dnbmap.values();
i05names = i05map.values();
vnfnames = vnfmap.values();
granList = strjoin(dnbmap.keys(),';');
llnames = llmap.values();
for nf = 1:nnames
    
    [pathDNB,nameDNB,extDNB] = fileparts(char(dnbnames(nf)));
    [pathI05,nameI05,extI05] = fileparts(char(i05names(nf)));
    [pathGeo,nameGeo,extGeo] = fileparts(char(llnames(nf)));
    if ~cellfun('isempty',vnfnames(nf))
        [pathCSV, nameCSV, extCSV] = fileparts(char(vnfnames(nf)));
    else
        pathCSV = '';
        nameCSV = '';
        extCSV = '';
    end
    
    if isempty(OUTPUT)
        csvname = fullfile(pathDNB,[nameDNB,'.csv']);
        lightname = fullfile(pathDNB,[nameDNB,'.metadata.csv']);
        kmlname = fullfile(pathDNB,nameDNB);
    else
        csvname = fullfile(outdir,[nameDNB,'.csv']);
        lightname = fullfile(outdir,[nameDNB,'.metadata.csv']);
        kmlname = fullfile(outdir,nameDNB);
    end
    disp(['Output file name for CSV ',csvname]);
    %     disp(['Output file name for KML ',kmlname]);
    
    csvfile = fopen(csvname,'w');
%     if metaFlag
%     % if SOFT_LIGHTNING_LENGTH ~= LIGHTNING_LENGTH
%         lightfile = fopen(lightname,'w');
%     end
    
    if useI05
        fprintf(csvfile,'id,id_Key,Date_Proc,Lat_DNB,Lon_DNB,Rad_DNB,Date_Mscan,Date_LTZ,Line_DNB,Sample_DNB,Rad_I05,QF_Detect,QF_Bitflag,');
    else
        fprintf(csvfile,'id,id_Key,Date_Proc,Lat_DNB,Lon_DNB,Rad_DNB,Date_Mscan,Date_LTZ,Line_DNB,Sample_DNB,Rad_I04,QF_Detect,QF_Bitflag,');
    end
    fprintf(csvfile,'SMI,Thr_SMI,SI,Thr_SI,SHI,Thr_SHI,LI,Thr_LI,Glint,Thr_Gl_SMI,Xcorr,');
    if useI05
        fprintf(csvfile,'Land_Mask,EEZ,FMZ,MPA,File_DNB,File_GDNB,File_I05,File_VNF,File_EEZ,File_FMZ,File_MPA,File_FLM,File_LSM,');
    else
        fprintf(csvfile,'Land_Mask,EEZ,FMZ,MPA,File_DNB,File_GDNB,File_I04,File_VNF,File_EEZ,File_FMZ,File_MPA,File_FLM,File_LSM,');
    end
    fprintf(csvfile,'File_LTZ,File_RLP,Dist_RLP,File_RLV,Lat_Gring,Lon_Gring,Gran_List,SOLZ_GDNBO,SOLA_GDNBO,SATZ_GDNBO,SATA_GDNBO,LUNZ_GDNBO,LUNA_GDNBO\n');
    
    if metaFlag
        for k = 1:length(metadata)
%             metadata(k).glintdnbtop = FILLVALUE;
%             if metadata(k).glint
%                 metadata(k).glintdnbtop = glintDNBthr;
%             end
            metadata(k).granname = char(nameDNB);
            if isnan(metadata(k).smishape)
                 metadata(k).smishape = FILLVALUE;
            end
        end
        
        % table utils are not available on Anchor
        % metatable = struct2table(metadata);
        % writetable(metatable,lightname);
        
        %// Extract field data
        fields = fieldnames(metadata);
        values = struct2cell(metadata);

        %// Convert all numerical values to strings
        idx = cellfun(@isnumeric, values); 
        values(idx) = cellfun(@num2str, values(idx), 'UniformOutput', 0);
        C = squeeze(values);

        %// Write fields to CSV file
        fid = fopen(lightname, 'wt');
        fmt_str = repmat('%s,', 1, size(C, 1));
        fprintf(fid, [fmt_str(1:end - 1), '\n'], fields{:});
        fprintf(fid, [fmt_str(1:end - 1), '\n'], C{:});
        fclose(fid);        
    end
    
    partdnblats = dnblats(granedges(nf)+1:granedges(nf+1),:);
    partdnblons = dnblons(granedges(nf)+1:granedges(nf+1),:);
    
    dls = find(partdnblats(:,1) > -999); % index all non-missing scan lines
    ndls = length(dls);
      
    ngrans = ceil(ndls / ngranlines); % number of granules in the aggregate
    disp(['Aggregate output with ',num2str(ngrans),' granules'])
    
    partbounds = zeros(6 + (ngrans-1) * 2,2); % 3 top line, 2 * (ngrans-1) on the sides, 3 bottom line
    
    partbounds(1,1) = partdnblats(dls(1),1); % top line
    partbounds(1,2) = partdnblons(dls(1),1);
    partbounds(2,1) = partdnblats(dls(1),round(dnbcols/2));
    partbounds(2,2) = partdnblons(dls(1),round(dnbcols/2));
    partbounds(3,1) = partdnblats(dls(1),dnbcols);
    partbounds(3,2) = partdnblons(dls(1),dnbcols);
    
    for ngr = 1:ngrans-1 %  right side
        partbounds(3 + ngr,1) = partdnblats(dls(round(ngr * ndls / ngrans)),dnbcols);
        partbounds(3 + ngr,2) = partdnblons(dls(round(ngr * ndls / ngrans)),dnbcols);
    end
    
    partbounds(3 + ngrans,1) = partdnblats(dls(end),dnbcols); % bottom line
    partbounds(3 + ngrans,2) = partdnblons(dls(end),dnbcols);
    partbounds(4 + ngrans,1) = partdnblats(dls(end),round(dnbcols/2));
    partbounds(4 + ngrans,2) = partdnblons(dls(end),round(dnbcols/2));
    partbounds(5 + ngrans,1) = partdnblats(dls(end),1);
    partbounds(5 + ngrans,2) = partdnblons(dls(end),1);
    
    for ngr = 1:ngrans-1 %  left side
        partbounds(5 + ngrans + ngr,1) = partdnblats(dls(round((ngrans - ngr) * ndls / ngrans)),1);
        partbounds(5 + ngrans + ngr,2) = partdnblons(dls(round((ngrans - ngr) * ndls / ngrans)),1);
    end    
    
    gringLat = '';
    gringLon = '';
    for j = 1:size(partbounds,1)
        gringLat = [gringLat sprintf('%f',partbounds(j,1))];
        gringLon = [gringLon sprintf('%f',partbounds(j,2))];
        if j ~= size(partbounds,1)
            gringLat = [gringLat ';'];
            gringLon = [gringLon ';'];
        end
    end
    
    id = 0;
    lightcount = 0;
    granind = find(coords(:,8) > granedges(nf) & coords(:,8) <= granedges(nf+1) &...
        ((coords(:,4) > 0 & ~strictFlag) | (coords(:,4) == 1 | coords(:,4) == 2 | coords(:,4) == 3 | coords(:,4) == 4)));
    for i=1:size(coords,1)
        if ismember(i,granind)
            
            id = id + 1;
            
            id_key = strcat('VBD_',lower(satName),'_',boatid(coords(i,7),coords(i,1),coords(i,2),coords(i,8)-granedges(nf),coords(i,9),boats_version));
            idkeys(id) = cellstr(id_key);
            
            dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
            if ltzones(i) ~= FILLVALUE
                coords(i,18) = coords(i,7) + ltzones(i)/24;
                localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
            else
                coords(i,18) = FILLVALUE;
                localdtstr = '';
            end
           
            waters = '';
            if ~isempty(eeznames{i})
                waters = char(eeznames{i});
            end
            
            fishery = '';
            if ~isempty(fmznames{i})
                fishery = char(fmznames{i});
            end
            
            protected = '';
            if ~isempty(mpanames{i})
                protected = char(mpanames{i});
            end
            
            % if  SOFT_LIGHTNING_LENGTH ~= LIGHTNING_LENGTH && coords(i,19) > 0 % short lightning detected
            if false
                lightcount = lightcount + 1;
                fprintf(lightfile,'%d,%s,%s,%f,%f,%s,%d,%d,%d\n',...
                    id,id_key,procdate,coords(i,1),coords(i,2),dtstr, ...
                    coords(i,8)-granedges(nf),coords(i,9),coords(i,19));
            end
            
%             fprintf(csvfile,'%d,%s,%s,%f,%f,%g,%s,%s,%d,%d,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%d,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%g,%s,%s,%s,%s,%g,%g,%g,%g,%g,%g\n',....
            fprintf(csvfile,'%d,%s,%s,%f,%f,%g,%s,%s,%d,%d,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%d,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%g,%s,%s,%s,%s,%g,%g,%g,%g,%g,%g\n',....
                id,id_key,procdate,coords(i,1),coords(i,2),coords(i,3),dtstr,localdtstr, ...
                coords(i,8)-granedges(nf),coords(i,9),coords(i,26),coords(i,4),coords(i,13),coords(i,11),coords(i,12),coords(i,5),SI,coords(i,6),SHI,coords(i,14),MOONLIT,coords(i,16),coords(i,17),coords(i,15),coords(i,10), ...
                waters,fishery,protected,[nameDNB,extDNB],[nameGeo,extGeo],[nameI05,extI05],[nameCSV,extCSV],[nameEEZ,extEEZ],[nameFMZ,extFMZ],[nameMPA,extMPA],...
                [nameFLM,extFLM],[nameLSM,extLSM],[nameLTZ,extLTZ],[namePLP,extPLP],plpDist(i),[namePLV,extPLV],...
                gringLat,gringLon,granList,...
                coords(i,20),coords(i,21),coords(i,22),coords(i,23),coords(i,24),coords(i,25));
        end
    end
        
    if id == 0 % no detections at all
        fprintf(csvfile,'%d,%s,%s,%f,%f,%g,%s,%s,%d,%d,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%d,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%g,%s,%s,%s,%s,%g,%g,%g,%g,%g,%g\n',....
            id,'',procdate,FILLVALUE,FILLVALUE,FILLVALUE,'','',FILLVALUE,FILLVALUE,FILLVALUE,...
            FILLVALUE,FILLVALUE,FILLVALUE,SMI,FILLVALUE,SI,FILLVALUE,SHI,FILLVALUE,MOONLIT,FILLVALUE,FILLVALUE,FILLVALUE,...
            FILLVALUE,'','','',[nameDNB,extDNB],[nameGeo,extGeo],[nameI05,extI05],[nameCSV,extCSV],[nameEEZ,extEEZ],[nameFMZ,extFMZ],[nameMPA,extMPA],...
            [nameFLM,extFLM],[nameLSM,extLSM],[nameLTZ,extLTZ],[namePLP,extPLP],FILLVALUE,[namePLV,extPLV],gringLat,gringLon,granList,...
            FILLVALUE,FILLVALUE,FILLVALUE,FILLVALUE,FILLVALUE,FILLVALUE);
    end
    
%     if metaFlag
%         fclose(lightfile);
%     end
    fclose(csvfile);
    
    if id == 0
        idvals = 0;
    else
        idvals = 1:id;
    end
    
    write_detection_kml_folders_v23(idvals,idkeys,coords(granind,:),eeznames(granind),fmznames(granind),mpanames(granind),...
        gringLat,gringLon,doCoverage,~strictFlag,FILLVALUE,kmlname,[],[nameDNB,extDNB],boats_version);
    
end

% if true
if dumpFlag
    % if count > 0 && verboseFlag
%     scount = numel(find(boattype == 2))
%     wcount = numel(find(boattype == 1))
%     if wcount > 0
%         shipsLatLon = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:wcount)', 'Lon', ...
%             num2cell(coords(boattype == 1,2)), 'Lat', num2cell(coords(boattype == 1,1)));
%         shapewrite(shipsLatLon,[outfile '.weak_boats_lat_lon_v20g.shp']);
%         shipsXY = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:wcount)', 'Y', ...
%             num2cell(r(boattype == 1)+0.5), 'X', num2cell(c(boattype == 1)+0.5));
%         shapewrite(shipsXY,[outfile '.weak_boats_line_sample_v20g.shp']);
%     end
%     
%     if scount > 0
%         shipsLatLon = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:scount)', 'Lon', ...
%             num2cell(coords(boattype == 2,2)), 'Lat', num2cell(coords(boattype == 2,1)));
%         shapewrite(shipsLatLon,[outfile '.strong_boats_lat_lon_v20g.shp']);
%         shipsXY = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:scount)', 'Y', ...
%             num2cell(r(boattype == 2)+0.5), 'X', num2cell(c(boattype == 2)+0.5));
%         shapewrite(shipsXY,[outfile '.strong_boats_line_sample_v20g.shp']);
%     end

    qflag = coords(:,4);
    gcount = numel(find(qflag == 6))
    qf1count = numel(find(qflag == 1))
    qf2count = numel(find(qflag == 2))
    qf3count = numel(find(qflag == 3))
    qf5count = numel(find(qflag == 5))
    
    if qf1count > 0
        shipsLatLon = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:qf1count)', 'Lon', ...
            num2cell(coords(qflag == 1,2)), 'Lat', num2cell(coords(qflag == 1,1)));
        shapewrite(shipsLatLon,[outfile '.qf1_lat_lon_v23.shp']);
        shipsXY = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:qf1count)', 'Y', ...
            num2cell(r(qflag == 1)+0.5), 'X', num2cell(c(qflag == 1)+0.5));
        shapewrite(shipsXY,[outfile '.qf1_line_sample_v23.shp']);
    end
    
    if qf2count > 0
        shipsLatLon = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:qf2count)', 'Lon', ...
            num2cell(coords(qflag == 2,2)), 'Lat', num2cell(coords(qflag == 2,1)));
        shapewrite(shipsLatLon,[outfile '.qf2_lat_lon_v23.shp']);
        shipsXY = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:qf2count)', 'Y', ...
            num2cell(r(qflag == 2)+0.5), 'X', num2cell(c(qflag == 2)+0.5));
        shapewrite(shipsXY,[outfile '.qf2_line_sample_v23.shp']);
    end
    
    if qf3count > 0
        shipsLatLon = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:qf3count)', 'Lon', ...
            num2cell(coords(qflag == 3,2)), 'Lat', num2cell(coords(qflag == 3,1)));
        shapewrite(shipsLatLon,[outfile '.qf3_lat_lon_v23.shp']);
        shipsXY = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:qf3count)', 'Y', ...
            num2cell(r(qflag == 3)+0.5), 'X', num2cell(c(qflag == 3)+0.5));
        shapewrite(shipsXY,[outfile '.qf3_line_sample_v23.shp']);
    end
    
    if gcount > 0
        shipsLatLon = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:gcount)', 'Lon', ...
            num2cell(coords(qflag == 6,2)), 'Lat', num2cell(coords(qflag == 6,1)));
        shapewrite(shipsLatLon,[outfile '.glint_lat_lon_v23.shp']);
        shipsXY = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:gcount)', 'Y', ...
            num2cell(r(qflag == 6)+0.5), 'X', num2cell(c(qflag == 6)+0.5));
        shapewrite(shipsXY,[outfile '.glint_line_sample_v23.shp']);
    end
    
    if qf5count > 0
        shipsLatLon = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:qf5count)', 'Lon', ...
            num2cell(coords(qflag == 5,2)), 'Lat', num2cell(coords(qflag == 5,1)));
        shapewrite(shipsLatLon,[outfile '.qf3_lat_lon_v23.shp']);
        shipsXY = struct('Geometry', 'MultiPoint', 'ID', num2cell(1:qf5count)', 'Y', ...
            num2cell(r(qflag == 5)+0.5), 'X', num2cell(c(qflag == 5)+0.5));
        shapewrite(shipsXY,[outfile '.qf5_line_sample_v23.shp']);
    end
end

usedTime = toc;
usedMemory = rtime.totalMemory - rtime.freeMemory;
stepnum = stepnum + 1;
tmemprof(stepnum).mem = usedMemory;
tmemprof(stepnum).time = usedTime;
tmemprof(stepnum).step = 'save';
disp(['Saved output. Job time ' num2str(usedTime) ' memory ' num2str(usedMemory)])

memprint = [tmemprof.mem];
tprint = [tmemprof.time];
steps = {tmemprof.step};

if visFlag

    figure('Name','Memory profile')
    bar(memprint/1024/1024)
    set(gca, 'XTickLabel',steps, 'XTick',1:numel(steps))
    rotateXLabels( gca(), 90 )
    xlabel('VBD steps')
    ylabel('Memory used, MB')

    figure('Name','Time profile')
    plot(tprint)
    hold on
    plot(tprint,'o')
    set(gca, 'XTickLabel',steps, 'XTick',1:numel(steps))
    rotateXLabels( gca(), 90 )
    xlabel('VBD steps')
    ylabel('Time elapsed, s')

end

if isdeployed
    close all
end
