function dateval = dateFromFileName(filename)

% filename = 'npp_d20130409_t2230459_e2236263_b07513'

datepos = strfind(filename,'_d');
datesubstr = filename(datepos+2:datepos+9);

timepos = strfind(filename,'_t');
timesubstr = filename(timepos+2:timepos+8);

dateval = datenum([datesubstr timesubstr],'yyyymmddhhMMSS');
% datestr(dateval)

end