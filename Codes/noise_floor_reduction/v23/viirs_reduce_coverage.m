function viirs_reduce_coverage(FILELIST,varargin)

[OUTPUT, XTRA] = ...
    process_options(varargin, '-output', '');

nightfire_version = '21';
fprintf('Nightfire detections reduce ver. %s for file list %s\n',nightfire_version,FILELIST);

if isempty(OUTPUT)
    pngfile = strcat(FILELIST,'.reduce_v',nightfire_version,'.png');
    warning(['Using default output coverage file name ',pngfile]);
else
    [outfile_pathstr, outfile_name, outfile_ext] = fileparts(OUTPUT);
    outdir = outfile_pathstr;
    outfile = OUTPUT;
    pngfile = fullfile(outdir,strcat(outfile_name,'.png'));
    disp(['Output coverage file name ',pngfile]);    
end

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
    error('Empty input file list, nothing to process');
end

nodup = true;
oldName = '';
covpng = [];

if (length(idx) > 0)
    % iterate thrugh the file list
    totaldtct = 0;
    for i=1:length(idx)
        filename = flist(idx(i)).name;
        [pathstr,name,ext] = fileparts(filename);
        pngname = [name '.png'];
        if nodup && strcmp(pngname,oldName)
            warning(['Skipping duplicate PNG file ' pngname]);
        else
            curpng = uint8(imread(fullfile(pathstr,pngname)) ~= 0);
            %curpng = imread(fullfile(pathstr,pngname));
            %size(curpng)
            %max(curpng(:))
            %min(curpng(:))
            if isempty(covpng)
                covpng = curpng;
                totaldtct = 1;
            elseif ~isequal(size(curpng),size(covpng))
                % size(curpng)
                error(['Image sizes are not the same for ' name '.png']);
            else
                % size(covpng)
                % size(curpng)
                covpng = covpng .* curpng;
                totaldtct = totaldtct + 1;
            end
        end
        oldName = pngname;
    end
    % fname = fullfile(pathstr,flist(idx(length(idx))).name);
else
    error('Empty file list for pattern %s',pattern);
end

% imshow(covpng);

fprintf('Writing coverage image stack for %d aggregates\n',totaldtct);

covalpha = 0.5 * 255 * covpng(:,:,1);
imwrite(255 * covpng,pngfile,'png','Alpha',covalpha);

