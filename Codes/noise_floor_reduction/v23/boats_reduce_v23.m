function varargout = boats_reduce_v23(FILELIST,varargin)
%
% 20140919  - first version
% 20141030  - changed KML ouput to have folders for boats etc.
% 20150519  - changed CSV format for ver 1.5
%           - changed KML output adding coverage maps
% 20150612  - renamed verbose CLI option to strict
%           - added help output
% 20150619  - added sort by file option in KML

% FILELIST = 'reduce_input_list_v21.txt'
% OUTPUT = 'reduce_output_v21.csv'
% MAP = 1
% COVERAGE = 0
% STRICT = 0
% SORT = 0

[OUTPUT, MAP, COVERAGE, STRICT, SORT, XTRA] = ...
    process_options(varargin,'-output','','-map',1,'-coverage',0,'-strict', 0,'-sort',0);

varargout{1} = 0;

%%
helpind = strmatch('-h',XTRA);
% if false
if ~isempty(helpind) && helpind > 0 || nargin < 1
    disp('Matlab script ?boats_reduce? has to be called with the following command line parameters:');
    disp('    (required)');
    disp('fileList              - name of text file with list of filenames of VBD SCVs to be reduced (merged)');
    disp('    (optional)');
    disp('-output <file name>   - output CSV file nane, will be derived from the fileDNB name if missing (*.csv)');
    disp('-map 0/1              - generate boat detection KML map for Google Earth, default value is 1');
    disp('-coverage 0/1/2       - generate coverage maps for KML for Google Earth (1), or link an external coverage image(2), default value is no coverage (0)');
    disp('-strict 0/1           - output only boat detections (QF1, if strict == 1) or all QFs (if strict == 0, default)');
    disp('-sort 0/1             - if 1, make subfolders for each file in the list, default is 0');
    disp('-h                    - displays this help screen');
    return    
end

global FILLVALUE;

FILLVALUE = 999999;

boats_version = '23';
fprintf('Boats detections reduce ver. %s for file list %s\n',boats_version,FILELIST);

doCoverage = COVERAGE;
disp(['Generate coverage map: ',num2str(doCoverage)]);

strictFlag = STRICT;
disp(['Strict boat detection output: ',num2str(strictFlag)]);

sortFlag = SORT;
disp(['Sort boat detections into subfolders by input file: ',num2str(sortFlag)]);

if isempty(OUTPUT)
    outfile = strcat(FILELIST,'.reduce_v',boats_version,'.csv');
    kmlfile = strcat(FILELIST,'.reduce_v',boats_version);
    warning(['Using default output file name ',outfile]);
else
    [outfile_pathstr, outfile_name, outfile_ext] = fileparts(OUTPUT);
    outdir = outfile_pathstr;
    outfile = OUTPUT;
    kmlfile = fullfile(outdir,strcat(outfile_name));
    disp(['Output file name ',outfile]);    
end

% doplots = PLOT;
% disp(['Plot spectra option ',num2str(doplots)]);
domap = MAP;
disp(['Make KML map option ',num2str(domap)]);

tic;

if ~isempty(FILELIST)
    fid = fopen(FILELIST);
    fnames = textscan(fid,'%s');
    fclose(fid);
    nnames = cellfun(@length,fnames);
    
    flist = struct();
    idx = [];
    for nf = 1:nnames
        flist(nf).name = char(fnames{1}{nf});
        idx(nf) = nf;
    end
    
    pathstr = ''; % not to be used later in CSV filenames
else
    error('Empty input file name, nothing to process');
end

if (~isempty(idx))
    % iterate thrugh the file list
    TC = [];
    NTC = [];
    totaldtct = 0;
    for i=1:length(idx)
        try
            name = flist(idx(i)).name;
        %         C = csvimport(fullfile(pathstr,flist(idx(i)).name));
        %         fullfile(pathstr,flist(idx(i)).name)
            [NC,C] = swallow_csv(fullfile(pathstr,flist(idx(i)).name),'"',',',' ');
            csvhead = char(C(1,:));
            fprintf('Found %6d sources in CSV file %s\n',size(C,1)-1,flist(idx(i)).name);
            ndtct = size(C,1) - 1;
            totaldtct = totaldtct + ndtct;
            % size(C)
            if(ndtct > 0) % not only header, has detections
                TC = [TC; C(2:ndtct+1,:), repmat({name},[ndtct,1])];
                NTC = [NTC; NC(2:ndtct+1,:), repmat(NaN,[ndtct,1])];
            end
        catch
            disp(['Error: bad format in input CSV file ',fullfile(pathstr,flist(idx(i)).name)])
            varargout{1} = 1;
        end
    end
    % fname = fullfile(pathstr,flist(idx(length(idx))).name);
else
    error('Empty file list for pattern');
end

idind = strmatch('id',csvhead,'exact');
id =  NTC(:,idind);

idkeyind = strmatch('id_Key',csvhead,'exact');
id_key = char(TC(:,idkeyind));

latind = strmatch('Lat_DNB',csvhead,'exact');
lat = NTC(:,latind);

lonind = strmatch('Lon_DNB',csvhead,'exact');
lon = NTC(:,lonind);

dnbind = strmatch('Rad_DNB',csvhead,'exact');
dnb = NTC(:,dnbind);

datemscanind = strmatch('Date_Mscan',csvhead,'exact');
datemscan = char(TC(:,datemscanind));

ltzind = strmatch('Date_LTZ',csvhead,'exact');
localdate = char(TC(:,ltzind));

lineind = strmatch('Line_DNB',csvhead,'exact');
line = NTC(:,lineind);

sampleind = strmatch('Sample_DNB',csvhead,'exact');
sample = NTC(:,sampleind);

spkdnbind = strmatch('SMI',csvhead,'exact');
spkdnb = NTC(:,spkdnbind);

thrdnbind = strmatch('Thr_SMI',csvhead,'exact');
thrdnb = NTC(:,thrdnbind);

spikeindind = strmatch('SHI',csvhead,'exact');
spikeind = NTC(:,spikeindind);

thrspikeind = strmatch('Thr_SHI',csvhead,'exact');
thrspike = NTC(:,thrspikeind);

blurind = strmatch('SI',csvhead,'exact');
blur = NTC(:,blurind);

thrblurind = strmatch('Thr_SI',csvhead,'exact');
thrblur = NTC(:,thrblurind);

liind = strmatch('LI',csvhead,'exact');
li = NTC(:,liind);

xcind = strmatch('Xcorr',csvhead,'exact');
xc = NTC(:,xcind);

qfdetectind = strmatch('QF_Detect',csvhead,'exact');
qfdetect = NTC(:,qfdetectind);

qfbitflagind = strmatch('QF_Bitflag',csvhead,'exact');
qfbitflag = NTC(:,qfbitflagind);

landmaskind = strmatch('Land_Mask',csvhead,'exact');
landmask = NTC(:,landmaskind);

eezind = strmatch('EEZ',csvhead,'exact');
eeznames = TC(:,eezind);

fmzind = strmatch('FMZ',csvhead,'exact');
fmznames = TC(:,fmzind);

mpaind = strmatch('MPA',csvhead,'exact');
mpanames = TC(:,mpaind);

dnbfileind = strmatch('File_DNB',csvhead,'exact');
dnbfile = char(TC(:,dnbfileind));

geodnbfileind = strmatch('File_Geo_DNB',csvhead,'exact');
geodnbfile = char(TC(:,geodnbfileind));

vnffileind = strmatch('File_VMF',csvhead,'exact');
vnffile = char(TC(:,vnffileind));

eezfileind = strmatch('File_EEZ',csvhead,'exact');
eezfile = char(TC(:,eezfileind));

fmzfileind = strmatch('File_FMZ',csvhead,'exact');
fmzfile = char(TC(:,fmzfileind));

mpafileind = strmatch('File_MPA',csvhead,'exact');
mpafile = char(TC(:,mpafileind));

flmfileind = strmatch('File_FLM',csvhead,'exact');
flfile = char(TC(:,flmfileind));

lsmfileind = strmatch('File_LSM',csvhead,'exact');
lsmfile = char(TC(:,lsmfileind));

ltzfileind = strmatch('File_LTZ',csvhead,'exact');
ltzfile = char(TC(:,ltzfileind));

latgringind = strmatch('Lat_Gring',csvhead,'exact');
latgring = char(TC(:,latgringind));

longringind = strmatch('Lon_Gring',csvhead,'exact');
longring = char(TC(:,longringind));

dnblist = char(TC(:,dnbfileind));
flist = char(TC(:,end));

numberpos = find(~isnan(NTC));
TC(numberpos) = num2cell(NTC(numberpos));

if domap
    
    coords = zeros(size(TC,1),25);
    coords(:,1) = lat;
    coords(:,2) = lon;
    coords(:,3) = dnb;
    coords(:,4) = qfdetect;
    coords(:,5) = blur;
    coords(:,6) = spikeind;
    for i=1:size(TC,1)
        % fprintf('<%s>\n',datemscan(i,:))
        if ~isempty(strtrim(datemscan(i,:)))
            coords(i,7) = datenum(datemscan(i,:));
        else
            coords(i,7) = FILLVALUE;
        end
        
%         size(localdate)
        if ~isempty(strtrim(localdate(i,:)))
            coords(i,18) = datenum(localdate(i,:));
        else
            coords(i,18) = FILLVALUE;
        end
    end
    coords(:,8) = line;
    coords(:,9) = sample;
    coords(:,10) = landmask;
    coords(:,11) = spkdnb;
    coords(:,12) = thrdnb;
    coords(:,13) = qfbitflag;
    coords(:,14) = li;
    coords(:,15) = xc;
    coords(:,19) = 0; % lightning placeholder
    
    write_detection_kml_folders_v23(id,cellstr(id_key),coords,eeznames,fmznames,mpanames,latgring,longring,doCoverage,~strictFlag,FILLVALUE,kmlfile,flist,dnblist,boats_version);    
end

%v2.2
% header = 'id,id_Key,Date_Proc,Lat_DNB,Lon_DNB,Rad_DNB,Date_Mscan,Date_LTZ,Line_DNB,Sample_DNB,QF_Detect,QF_Bitflag,';
% header = [header,'SMI,Thr_SMI,SI,Thr_SI,SHI,Thr_SHI,LI,Thr_LI,Glint,Thr_Glint,Thr_Gl_DNB,Xcorr,'];
% header = [header,'Land_Mask,EEZ,FMZ,MPA,File_DNB,File_GDNB,File_VNF,File_EEZ,File_FMZ,File_MPA,File_FLM,File_LSM,'];
% header = [header,'File_LTZ,File_RLP,Dist_RLP,File_RLV,Lat_Gring,Lon_Gring,Gran_List,SOLZ_GDNBO,SOLA_GDNBO,SATZ_GDNBO,SATA_GDNBO,LUNZ_GDNBO,LUNA_GDNBO\n'];
% format = '%d,%s,%s,%f,%f,%g,%s,%s,%d,%d,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%d,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%g,%s,%s,%s,%s,%g,%g,%g,%g,%g,%g\n';

% size(cellstr(csvhead))
header = strcat(strjoin(cellstr(csvhead)',','),'\n');
format = '%d,%s,%s,%f,%f,%g,%s,%s,%d,%d,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%d,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%g,%s,%s,%s,%s,%g,%g,%g,%g,%g,%g\n';

csvfile = fopen(outfile, 'wt');
fprintf(csvfile,header);

for i=1:size(TC,1)
    fprintf(csvfile,format,TC{i,1:end-1});
end

fclose(csvfile);

fprintf('Total %d files processed with %d detections\n',length(idx),totaldtct);

toc

end

