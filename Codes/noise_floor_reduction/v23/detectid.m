function id_key = detectid(lsyear,lsday,lat,lon,line,sample)

% lat = -40.123456;
% lon = -169.7654821;
% line = 0999;
% sample = 0001;

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

dpart = sprintf('d%s%s',lsyear,lsday);

id_key = strcat(dpart,'_',xpart,'_',ypart,'_',lpart,'_',spart);

end