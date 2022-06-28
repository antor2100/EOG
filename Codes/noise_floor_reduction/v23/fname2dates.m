%%
function [dateFrom, dateTo] = fname2dates(fname)

[pathstr, name, ext] = fileparts(fname);
cparts = char(strread(name, '%s', 'delimiter', '_'));

strFileDate = cparts(3,2:end);
strFileFrom = cparts(4,2:end);
strFileTo = cparts(5,2:end);
strFileDateFrom = strcat(strFileDate,'T',strFileFrom);
strFileDateTo = strcat(strFileDate,'T',strFileTo);
dateFrom = datenum(strFileDateFrom,'yyyymmddTHHMMSS');
dateTo = datenum(strFileDateTo,'yyyymmddTHHMMSS');
if dateTo < dateFrom
    dateTo = dateTo + 1;
end

end

