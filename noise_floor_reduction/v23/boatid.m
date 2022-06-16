function id_key = boatid(dateTime,lat,lon,line,sample,ver)

% lat = -40.123456;
% lon = -169.7654821;
% line = 0999;
% sample = 0001;

dtstr = datestr(dateTime,'yyyymmdd');
tmstr = datestr(dateTime,'HHMMSSFFF');
dttmstr = strcat('d',dtstr,'_t',tmstr(1:end-2));

if lon >= 0
    xpart = sprintf('x%07dE',round(lon*1e4));
else
    xpart = sprintf('x%07dW',round(-lon*1e4));
end

if lat >= 0
    ypart = sprintf('y%06dN',round(lat*1e4));
else
    ypart = sprintf('y%06dS',round(-lat*1e4));
end

lpart = sprintf('l%04d',line);
spart = sprintf('s%04d',sample);

id_key = strcat(dttmstr,'_',xpart,'_',ypart,'_',lpart,'_',spart,'_v',ver);

end
