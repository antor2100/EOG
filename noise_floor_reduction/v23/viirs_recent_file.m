function fname = viirs_recent_file(pathstr,prefix,compart,suffix)
if nargin < 4 || isempty(suffix)
    suffix = 'h5';
end
pattern = strcat('*',prefix,'*',compart,'*.',suffix);
flist = dir(fullfile(pathstr,pattern));
[~,idx] = sort({flist.name});
if (length(idx) > 1)
    warning('Found %d files with %s prefix',length(idx),prefix);
end
if (length(idx) > 0)
    fname = fullfile(pathstr,flist(idx(length(idx))).name);
else
    warning('Empty file list for pattern %s',fullfile(pathstr,pattern))
    fname = [];
end
end
