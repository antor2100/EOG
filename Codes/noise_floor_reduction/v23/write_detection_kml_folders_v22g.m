function write_detection_kml_folders_v22g(id,idkey,coords, eeznames, fmznames, mpanames, latgring, longring, ...
    docoverage, verbose, fillvalue, filename, flist, dnblist, ver)

PERSIST_FLAG = 16384;
FALSEQF1_FLAG = 65536;
FM_FLAG = 4;

global FILLVALUE;

kmlfile = [filename '.kml'];
[kml_path, kml_name, kml_ext] = fileparts(kmlfile);
fid = fopen(kmlfile, 'wt');
fprintf(fid,'<?xml version="1.0" encoding="UTF-8"?>');
fprintf(fid,'<kml xmlns="http://www.opengis.net/kml/2.2">');
fprintf(fid,'<Document>\n');
fprintf(fid,'<name>%s</name>\n',kml_name);
fprintf(fid,'<open>1</open>\n');

fcount = 0; % flare count
rcount = 0; % CR count
bcount = 0; % boat count
scount = 0; % spike count
ccount = 0; % cloud count

%% Boats foloder
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Boats</name>\n');
fprintf(fid,'<open>0</open>\n');
filesav = '';
for i=1:size(coords,1)

    if size(dnblist,1) == 0
    	dnbname = '';
    elseif size(dnblist,1) == 1
	dnbname = dnblist(1,:);
    else
	dnbname = dnblist(i,:);
    end

    if ~ isempty(flist)
        [part_path, part_name, part_ext] = fileparts(flist(i,:));
        if ~ strcmp(part_name,filesav)
            if i > 1
                fprintf(fid,'</Folder>\n');
            end
            filesav = part_name;
            fprintf(fid,'<Folder>\n');
            fprintf(fid,'<name>%s</name>\n',filesav);
            fprintf(fid,'<open>0</open>\n');
        end
    end

    if coords(i,10) > 1 && coords(i,19) == 0
    if coords(i,4) == 1

        waters = 'NA';
        if ~isempty(eeznames{i})
            waters = char(eeznames{i});
        end
        
        fishery = 'NA';
        if ~isempty(fmznames{i})
            fishery = char(fmznames{i});
        end
        
        protected = 'NA';
        if ~isempty(mpanames{i})
            protected = char(mpanames{i});
        end       
        
        bcount = bcount + 1;    
        
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<Style id="highlightPlacemark%d">\n',i);
        fprintf(fid,'<IconStyle>\n');
        
        if(log10(coords(i,3)) > 2) % large radiance
            fprintf(fid,'<scale>1</scale>\n');
        elseif(log10(coords(i,3)) > 1) % average radiance
            fprintf(fid,'<scale>0.75</scale>\n');
        else % low radiance
            fprintf(fid,'<scale>0.5</scale>\n');
        end
        
        fprintf(fid,'<Icon>\n');
        if coords(i,10) == 3
            fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/shapes/sailing.png</href>\n');
        else
            fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/shapes/marina.png</href>\n');
        end
        fprintf(fid,'</Icon>\n');
        fprintf(fid,'</IconStyle>\n');
        fprintf(fid,'</Style>\n');

        flarename = char(idkey{i});

        dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
        if coords(i,18) ~= FILLVALUE
            localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
        else
            localdtstr = '';
        end
        
        landsea = 'Ocean';
        if coords(i,10) < 3
            landsea = 'Coast';
        end
        
        write_kml_description(fid,i,verbose,'Boat',dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,dnbname);       

        fprintf(fid,'<Point>\n');
        fprintf(fid,'<coordinates>%f,%f,0</coordinates>\n',coords(i,2),coords(i,1));
        fprintf(fid,'</Point>\n');
        fprintf(fid,'</Placemark>\n');
    end
    end
end
if ~ isempty(filesav)
    fprintf(fid,'</Folder>\n');
end
fprintf(fid,'</Folder>\n');

%% Recurring lights foloder
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Recurring Lights</name>\n');
fprintf(fid,'<open>0</open>\n');
filesav = '';
for i=1:size(coords,1)

    if size(dnblist,1) == 0
    	dnbname = '';
    elseif size(dnblist,1) == 1
	dnbname = dnblist(1,:);
    else
	dnbname = dnblist(i,:);
    end

    if ~ isempty(flist)
        [part_path, part_name, part_ext] = fileparts(flist(i,:));
        if ~ strcmp(part_name,filesav)
            if i > 1
                fprintf(fid,'</Folder>\n');
            end
            filesav = part_name;
            fprintf(fid,'<Folder>\n');
            fprintf(fid,'<name>%s</name>\n',filesav);
            fprintf(fid,'<open>0</open>\n');
        end
    end
    if coords(i,10) > 1 && coords(i,19) == 0
    if coords(i,4) == 8

        % persist = bitand(uint32(coords(i,13)),uint32(PERSIST_FLAG));
        
        waters = 'NA';
        if ~isempty(eeznames{i})
            waters = char(eeznames{i});
        end
        
        fishery = 'NA';
        if ~isempty(fmznames{i})
            fishery = char(fmznames{i});
        end
        
        protected = 'NA';
        if ~isempty(mpanames{i})
            protected = char(mpanames{i});
        end       
        
        bcount = bcount + 1;    
        
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<Style id="highlightPlacemark%d">\n',i);
        fprintf(fid,'<IconStyle>\n');
        
        if(log10(coords(i,3)) > 2) % large radiance
            fprintf(fid,'<scale>1</scale>\n');
        elseif(log10(coords(i,3)) > 1) % average radiance
            fprintf(fid,'<scale>0.75</scale>\n');
        else % low radiance
            fprintf(fid,'<scale>0.5</scale>\n');
        end
        
        fprintf(fid,'<Icon>\n');
        fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/shapes/square.png</href>\n');
        fprintf(fid,'</Icon>\n');
        fprintf(fid,'</IconStyle>\n');
        fprintf(fid,'</Style>\n');

        flarename = char(idkey{i});

        dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
        if coords(i,18) ~= FILLVALUE
            localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
        else
            localdtstr = '';
        end
        
        landsea = 'Ocean';
        if coords(i,10) < 3
            landsea = 'Coast';
        end
        
        write_kml_description(fid,i,verbose,'Recurring light',dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,dnbname);       

        fprintf(fid,'<Point>\n');
        fprintf(fid,'<coordinates>%f,%f,0</coordinates>\n',coords(i,2),coords(i,1));
        fprintf(fid,'</Point>\n');
        fprintf(fid,'</Placemark>\n');
    end
    end
end
if ~ isempty(filesav)
    fprintf(fid,'</Folder>\n');
end
fprintf(fid,'</Folder>\n');

%% Spikes folder
filesav = '';
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Weak Detections</name>\n');
fprintf(fid,'<open>0</open>\n');
for i=1:size(coords,1)

    if size(dnblist,1) == 0
    	dnbname = '';
    elseif size(dnblist,1) == 1
	dnbname = dnblist(1,:);
    else
	dnbname = dnblist(i,:);
    end

    if ~ isempty(flist)
        [part_path, part_name, part_ext] = fileparts(flist(i,:));
        if ~ strcmp(part_name,filesav)
            if i > 1
                fprintf(fid,'</Folder>\n');
            end
            filesav = part_name;
            fprintf(fid,'<Folder>\n');
            fprintf(fid,'<name>%s</name>\n',filesav);
            fprintf(fid,'<open>0</open>\n');
        end
    end
    if coords(i,10) > 1 && coords(i,19) == 0
    if coords(i,4) == 2
        
        waters = 'NA';
        if ~isempty(eeznames{i})
            waters = char(eeznames{i});
        end
        
        fishery = 'NA';
        if ~isempty(fmznames{i})
            fishery = char(fmznames{i});
        end
        
        protected = 'NA';
        if ~isempty(mpanames{i})
            protected = char(mpanames{i});
        end       
        
        scount = scount + 1;    
        
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<Style id="highlightPlacemark%d">\n',i);
        fprintf(fid,'<IconStyle>\n');
        
        if(log10(coords(i,3)) > 2) % large radiance
            fprintf(fid,'<scale>1</scale>\n');
        elseif(log10(coords(i,3)) > 1) % average radiance
            fprintf(fid,'<scale>0.75</scale>\n');
        else % low radiance
            fprintf(fid,'<scale>0.5</scale>\n');
        end
        
        fprintf(fid,'<Icon>\n');
        fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/shapes/target.png</href>\n');
        fprintf(fid,'</Icon>\n');
        fprintf(fid,'</IconStyle>\n');
        fprintf(fid,'</Style>\n');

        flarename = char(idkey{i});

        visibility = ['<visibility>' num2str(verbose) '</visibility>\n'];
        fprintf(fid,visibility);

        dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
        if coords(i,18) ~= FILLVALUE
            localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
        else
            localdtstr = '';
        end
        
        landsea = 'Ocean';
        if coords(i,10) < 3
            landsea = 'Coast';
        end
        
        write_kml_description(fid,i,verbose,'Weak',dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,dnbname);       

        fprintf(fid,'<Point>\n');
        fprintf(fid,'<coordinates>%f,%f,0</coordinates>\n',coords(i,2),coords(i,1));
        fprintf(fid,'</Point>\n');
        fprintf(fid,'</Placemark>\n');
    end
    end
end
if ~ isempty(filesav)
    fprintf(fid,'</Folder>\n');
end
fprintf(fid,'</Folder>\n');

%% Clouds folder    
filesav = '';
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Blurry Detections</name>\n');
fprintf(fid,'<open>0</open>\n');
for i=1:size(coords,1)

    if size(dnblist,1) == 0
    	dnbname = '';
    elseif size(dnblist,1) == 1
	dnbname = dnblist(1,:);
    else
	dnbname = dnblist(i,:);
    end

    if ~ isempty(flist)
        [part_path, part_name, part_ext] = fileparts(flist(i,:));
        if ~ strcmp(part_name,filesav)
            if i > 1
                fprintf(fid,'</Folder>\n');
            end
            filesav = part_name;
            fprintf(fid,'<Folder>\n');
            fprintf(fid,'<name>%s</name>\n',filesav);
            fprintf(fid,'<open>0</open>\n');
        end
    end   
    if coords(i,10) > 1 && coords(i,19) == 0
    if coords(i,4) == 3
        
        waters = 'NA';
        if ~isempty(eeznames{i})
            waters = char(eeznames{i});
        end
        
        fishery = 'NA';
        if ~isempty(fmznames{i})
            fishery = char(fmznames{i});
        end
        
        protected = 'NA';
        if ~isempty(mpanames{i})
            protected = char(mpanames{i});
        end       
        
        ccount = ccount + 1;    
        
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<Style id="highlightPlacemark%d">\n',i);
        fprintf(fid,'<IconStyle>\n');
        
        if(log10(coords(i,3)) > 2) % large radiance
            fprintf(fid,'<scale>1</scale>\n');
        elseif(log10(coords(i,3)) > 1) % average radiance
            fprintf(fid,'<scale>0.75</scale>\n');
        else % low radiance
            fprintf(fid,'<scale>0.5</scale>\n');
        end
        
        fprintf(fid,'<Icon>\n');
        fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/shapes/rainy.png</href>\n');
        fprintf(fid,'</Icon>\n');
        fprintf(fid,'</IconStyle>\n');
        fprintf(fid,'</Style>\n');

        flarename = char(idkey{i});

        visibility = ['<visibility>' num2str(verbose) '</visibility>\n'];
        fprintf(fid,visibility);
        
        dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
        if coords(i,18) ~= FILLVALUE
            localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
        else
            localdtstr = '';
        end
        
        landsea = 'Ocean';
        if coords(i,10) < 3
            landsea = 'Coast';
        end
        
        write_kml_description(fid,i,verbose,'Blurry',dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,dnbname);       

        fprintf(fid,'<Point>\n');
        fprintf(fid,'<coordinates>%f,%f,0</coordinates>\n',coords(i,2),coords(i,1));
        fprintf(fid,'</Point>\n');
        fprintf(fid,'</Placemark>\n');
    end
    end
end
if ~ isempty(filesav)
    fprintf(fid,'</Folder>\n');
end
fprintf(fid,'</Folder>\n');

%% Gas Flares folder
filesav = '';
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Gas Flares</name>\n');
fprintf(fid,'<open>0</open>\n');
for i=1:size(coords,1)

    if size(dnblist,1) == 0
    	dnbname = '';
    elseif size(dnblist,1) == 1
	dnbname = dnblist(1,:);
    else
	dnbname = dnblist(i,:);
    end

    if ~ isempty(flist)
        [part_path, part_name, part_ext] = fileparts(flist(i,:));
        if ~ strcmp(part_name,filesav)
            if i > 1
                fprintf(fid,'</Folder>\n');
            end
            filesav = part_name;
            fprintf(fid,'<Folder>\n');
            fprintf(fid,'<name>%s</name>\n',filesav);
            fprintf(fid,'<open>0</open>\n');
        end
    end
    if coords(i,10) > 1 && coords(i,19) == 0
    if coords(i,4) == 4

        falseqf1 = bitand(uint32(coords(i,13)),uint32(FALSEQF1_FLAG));
        flaremask = bitand(uint32(coords(i,13)),uint32(FM_FLAG));
        
        waters = 'NA';
        if ~isempty(eeznames{i})
            waters = char(eeznames{i});
        end
        
        fishery = 'NA';
        if ~isempty(fmznames{i})
            fishery = char(fmznames{i});
        end
        
        protected = 'NA';
        if ~isempty(mpanames{i})
            protected = char(mpanames{i});
        end       
        
        fcount = fcount + 1;    
        
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<Style id="highlightPlacemark%d">\n',i);
        fprintf(fid,'<IconStyle>\n');
        
        if(log10(coords(i,3)) > 2) % large radiance
            fprintf(fid,'<scale>1</scale>\n');
        elseif(log10(coords(i,3)) > 1) % average radiance
            fprintf(fid,'<scale>0.75</scale>\n');
        else % low radiance
            fprintf(fid,'<scale>0.5</scale>\n');
        end
        
        fprintf(fid,'<Icon>\n');
        if falseqf1 && ~flaremask
            fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/paddle/wht-blank.png</href>\n');
        else
            fprintf(fid,'<href>http://maps.google.com/mapfiles/ms/micons/red.png</href>\n');        
        end
        fprintf(fid,'</Icon>\n');
        fprintf(fid,'</IconStyle>\n');
        fprintf(fid,'</Style>\n');

        flarename = char(idkey{i});

        visibility = ['<visibility>' num2str(verbose) '</visibility>\n'];
        fprintf(fid,visibility);

        dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
        if coords(i,18) ~= FILLVALUE
            localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
        else
            localdtstr = '';
        end
        
        landsea = 'Ocean';
        if coords(i,10) < 3
            landsea = 'Coast';
        end
        
        write_kml_description(fid,i,verbose,'Gas flare',dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,dnbname);       

        fprintf(fid,'<Point>\n');
        fprintf(fid,'<coordinates>%f,%f,0</coordinates>\n',coords(i,2),coords(i,1));
        fprintf(fid,'</Point>\n');
        fprintf(fid,'</Placemark>\n');
    end
    end
end
if ~ isempty(filesav)
    fprintf(fid,'</Folder>\n');
end
fprintf(fid,'</Folder>\n');

if verbose
    
%% Gas Flares Crosstalk folder
filesav = '';
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Sensor Crosstalk</name>\n');
fprintf(fid,'<open>0</open>\n');
fprintf(fid,'<visibility>0</visibility>\n');
for i=1:size(coords,1)

    if size(dnblist,1) == 0
    	dnbname = '';
    elseif size(dnblist,1) == 1
	dnbname = dnblist(1,:);
    else
	dnbname = dnblist(i,:);
    end

    if ~ isempty(flist)
        [part_path, part_name, part_ext] = fileparts(flist(i,:));
        if ~ strcmp(part_name,filesav)
            if i > 1
                fprintf(fid,'</Folder>\n');
            end
            filesav = part_name;
            fprintf(fid,'<Folder>\n');
            fprintf(fid,'<name>%s</name>\n',filesav);
            fprintf(fid,'<visibility>0</visibility>\n');
            fprintf(fid,'<open>0</open>\n');
        end
    end
    if coords(i,10) > 1 && coords(i,19) == 0
    if coords(i,4) == 9

        falseqf1 = bitand(uint32(coords(i,13)),uint32(FALSEQF1_FLAG));
        flaremask = bitand(uint32(coords(i,13)),uint32(FM_FLAG));
        
        waters = 'NA';
        if ~isempty(eeznames{i})
            waters = char(eeznames{i});
        end
        
        fishery = 'NA';
        if ~isempty(fmznames{i})
            fishery = char(fmznames{i});
        end
        
        protected = 'NA';
        if ~isempty(mpanames{i})
            protected = char(mpanames{i});
        end       
        
        fcount = fcount + 1;    
        
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<Style id="highlightPlacemark%d">\n',i);
        fprintf(fid,'<IconStyle>\n');
        
        if(log10(coords(i,3)) > 2) % large radiance
            fprintf(fid,'<scale>1</scale>\n');
        elseif(log10(coords(i,3)) > 1) % average radiance
            fprintf(fid,'<scale>0.75</scale>\n');
        else % low radiance
            fprintf(fid,'<scale>0.5</scale>\n');
        end
        
        fprintf(fid,'<Icon>\n');
        fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/paddle/wht-blank.png</href>\n');
        fprintf(fid,'</Icon>\n');
        fprintf(fid,'</IconStyle>\n');
        fprintf(fid,'</Style>\n');

        flarename = char(idkey{i});

        fprintf(fid,'<visibility>0</visibility>\n');

        dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
        if coords(i,18) ~= FILLVALUE
            localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
        else
            localdtstr = '';
        end
        
        landsea = 'Ocean';
        if coords(i,10) < 3
            landsea = 'Coast';
        end
        
        write_kml_description(fid,i,verbose,'Sensor crosstalk',dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,dnbname);       

        fprintf(fid,'<Point>\n');
        fprintf(fid,'<coordinates>%f,%f,0</coordinates>\n',coords(i,2),coords(i,1));
        fprintf(fid,'</Point>\n');
        fprintf(fid,'</Placemark>\n');
    end
    end
end
if ~ isempty(filesav)
    fprintf(fid,'</Folder>\n');
end
fprintf(fid,'</Folder>\n');

%% Moon glint folder    
filesav = '';
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Moon Glint</name>\n');
fprintf(fid,'<open>0</open>\n');
fprintf(fid,'<visibility>0</visibility>\n');
for i=1:size(coords,1)

    if size(dnblist,1) == 0
    	dnbname = '';
    elseif size(dnblist,1) == 1
	dnbname = dnblist(1,:);
    else
	dnbname = dnblist(i,:);
    end

    if ~ isempty(flist)
        [part_path, part_name, part_ext] = fileparts(flist(i,:));
        if ~ strcmp(part_name,filesav)
            if i > 1
                fprintf(fid,'</Folder>\n');
            end
            filesav = part_name;
            fprintf(fid,'<Folder>\n');
            fprintf(fid,'<name>%s</name>\n',filesav);
            fprintf(fid,'<visibility>0</visibility>\n');
            fprintf(fid,'<open>0</open>\n');
        end
    end   
    if coords(i,10) > 1 && coords(i,19) == 0
    if coords(i,4) == 6
        
        waters = 'NA';
        if ~isempty(eeznames{i})
            waters = char(eeznames{i});
        end
        
        fishery = 'NA';
        if ~isempty(fmznames{i})
            fishery = char(fmznames{i});
        end
        
        protected = 'NA';
        if ~isempty(mpanames{i})
            protected = char(mpanames{i});
        end       
        
        ccount = ccount + 1;    
        
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<Style id="highlightPlacemark%d">\n',i);
        fprintf(fid,'<IconStyle>\n');
        
        if(log10(coords(i,3)) > 2) % large radiance
            fprintf(fid,'<scale>1</scale>\n');
        elseif(log10(coords(i,3)) > 1) % average radiance
            fprintf(fid,'<scale>0.75</scale>\n');
        else % low radiance
            fprintf(fid,'<scale>0.5</scale>\n');
        end
        
        fprintf(fid,'<Icon>\n');
        fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/shapes/water.png</href>\n');
        fprintf(fid,'</Icon>\n');
        fprintf(fid,'</IconStyle>\n');
        fprintf(fid,'</Style>\n');

        flarename = char(idkey{i});

        fprintf(fid,'<visibility>0</visibility>\n');
        
        dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
        if coords(i,18) ~= FILLVALUE
            localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
        else
            localdtstr = '';
        end
        
        landsea = 'Ocean';
        if coords(i,10) < 3
            landsea = 'Coast';
        end
        
        write_kml_description(fid,i,verbose,'Glint zone',dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,dnbname);       

        fprintf(fid,'<Point>\n');
        fprintf(fid,'<coordinates>%f,%f,0</coordinates>\n',coords(i,2),coords(i,1));
        fprintf(fid,'</Point>\n');
        fprintf(fid,'</Placemark>\n');
    end
    end
end
if ~ isempty(filesav)
    fprintf(fid,'</Folder>\n');
end
fprintf(fid,'</Folder>\n');

%% Glow folder    
filesav = '';
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Flare Glow</name>\n');
fprintf(fid,'<open>0</open>\n');
fprintf(fid,'<visibility>0</visibility>\n');
for i=1:size(coords,1)
    if ~ isempty(flist)
        [part_path, part_name, part_ext] = fileparts(flist(i,:));
        if ~ strcmp(part_name,filesav)
            if i > 1
                fprintf(fid,'</Folder>\n');
            end
            filesav = part_name;
            fprintf(fid,'<Folder>\n');
            fprintf(fid,'<name>%s</name>\n',filesav);
            fprintf(fid,'<visibility>0</visibility>\n');
            fprintf(fid,'<open>0</open>\n');
        end
    end   
    if coords(i,10) > 1 && coords(i,19) == 0
    if coords(i,4) == 7
        
        waters = 'NA';
        if ~isempty(eeznames{i})
            waters = char(eeznames{i});
        end
        
        fishery = 'NA';
        if ~isempty(fmznames{i})
            fishery = char(fmznames{i});
        end
        
        protected = 'NA';
        if ~isempty(mpanames{i})
            protected = char(mpanames{i});
        end       
        
        ccount = ccount + 1;    
        
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<Style id="highlightPlacemark%d">\n',i);
        fprintf(fid,'<IconStyle>\n');
        
        if(log10(coords(i,3)) > 2) % large radiance
            fprintf(fid,'<scale>1</scale>\n');
        elseif(log10(coords(i,3)) > 1) % average radiance
            fprintf(fid,'<scale>0.75</scale>\n');
        else % low radiance
            fprintf(fid,'<scale>0.5</scale>\n');
        end        
        fprintf(fid,'<Icon>\n');
        fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/paddle/ylw-blank.png</href>\n');
        fprintf(fid,'</Icon>\n');
        fprintf(fid,'</IconStyle>\n');
        fprintf(fid,'</Style>\n');

        fprintf(fid,'<visibility>0</visibility>\n');
        
        flarename = char(idkey{i});

        dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
        if coords(i,18) ~= FILLVALUE
            localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
        else
            localdtstr = '';
        end
        
        landsea = 'Ocean';
        if coords(i,10) < 3
            landsea = 'Coast';
        end
        
        write_kml_description(fid,i,verbose,'Flare glow',dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,dnbname);       

        fprintf(fid,'<Point>\n');
        fprintf(fid,'<coordinates>%f,%f,0</coordinates>\n',coords(i,2),coords(i,1));
        fprintf(fid,'</Point>\n');
        fprintf(fid,'</Placemark>\n');
    end
    end
end
if ~ isempty(filesav)
    fprintf(fid,'</Folder>\n');
end
fprintf(fid,'</Folder>\n');

%% Weak and blurry folder    
filesav = '';
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Weak and Blurry</name>\n');
fprintf(fid,'<open>0</open>\n');
fprintf(fid,'<visibility>0</visibility>\n');
for i=1:size(coords,1)

    if size(dnblist,1) == 0
    	dnbname = '';
    elseif size(dnblist,1) == 1
	dnbname = dnblist(1,:);
    else
	dnbname = dnblist(i,:);
    end

    if ~ isempty(flist)
        [part_path, part_name, part_ext] = fileparts(flist(i,:));
        if ~ strcmp(part_name,filesav)
            if i > 1
                fprintf(fid,'</Folder>\n');
            end
            filesav = part_name;
            fprintf(fid,'<Folder>\n');
            fprintf(fid,'<name>%s</name>\n',filesav);
            fprintf(fid,'<visibility>0</visibility>\n');
            fprintf(fid,'<open>0</open>\n');
        end
    end   
    if coords(i,10) > 1 && coords(i,19) == 0
    if coords(i,4) == 10
                
        waters = 'NA';
        if ~isempty(eeznames{i})
            waters = char(eeznames{i});
        end
        
        fishery = 'NA';
        if ~isempty(fmznames{i})
            fishery = char(fmznames{i});
        end
        
        protected = 'NA';
        if ~isempty(mpanames{i})
            protected = char(mpanames{i});
        end       
        
        ccount = ccount + 1;    
        
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<Style id="highlightPlacemark%d">\n',i);
        fprintf(fid,'<IconStyle>\n');
        
        if(log10(coords(i,3)) > 2) % large radiance
            fprintf(fid,'<scale>1</scale>\n');
        elseif(log10(coords(i,3)) > 1) % average radiance
            fprintf(fid,'<scale>0.75</scale>\n');
        else % low radiance
            fprintf(fid,'<scale>0.5</scale>\n');
        end        
        fprintf(fid,'<Icon>\n');
        fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png</href>\n');
        fprintf(fid,'</Icon>\n');
        fprintf(fid,'</IconStyle>\n');
        fprintf(fid,'</Style>\n');

        fprintf(fid,'<visibility>0</visibility>\n');
        
        flarename = char(idkey{i});

        dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
        if coords(i,18) ~= FILLVALUE
            localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
        else
            localdtstr = '';
        end
        
        landsea = 'Ocean';
        if coords(i,10) < 3
            landsea = 'Coast';
        end
        
        write_kml_description(fid,i,verbose,'Weak and blurry',dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,dnbname);       

        fprintf(fid,'<Point>\n');
        fprintf(fid,'<coordinates>%f,%f,0</coordinates>\n',coords(i,2),coords(i,1));
        fprintf(fid,'</Point>\n');
        fprintf(fid,'</Placemark>\n');
    end
    end
end
if ~ isempty(filesav)
    fprintf(fid,'</Folder>\n');
end
fprintf(fid,'</Folder>\n');

%% Cosmic Rays folder
filesav = '';
fprintf(fid,'<Folder>\n');
fprintf(fid,'<name>Cosmic Rays</name>\n');
fprintf(fid,'<open>0</open>\n');
fprintf(fid,'<visibility>0</visibility>\n');
for i=1:size(coords,1)

    if size(dnblist,1) == 0
    	dnbname = '';
    elseif size(dnblist,1) == 1
	dnbname = dnblist(1,:);
    else
	dnbname = dnblist(i,:);
    end

    if ~ isempty(flist)
        [part_path, part_name, part_ext] = fileparts(flist(i,:));
        if ~ strcmp(part_name,filesav)
            if i > 1
                fprintf(fid,'</Folder>\n');
            end
            filesav = part_name;
            fprintf(fid,'<Folder>\n');
            fprintf(fid,'<name>%s</name>\n',filesav);
            fprintf(fid,'<visibility>0</visibility>\n');
            fprintf(fid,'<open>0</open>\n');
        end
    end
        
    if coords(i,10) > 1 && coords(i,19) == 0
    if coords(i,4) == 5
        
        waters = 'NA';
        if ~isempty(eeznames{i})
            waters = char(eeznames{i});
        end
        
        fishery = 'NA';
        if ~isempty(fmznames{i})
            fishery = char(fmznames{i});
        end
        
        protected = 'NA';
        if ~isempty(mpanames{i})
            protected = char(mpanames{i});
        end       
        
        rcount = rcount + 1;    
        
        fprintf(fid,'<Placemark>\n');
        fprintf(fid,'<Style id="highlightPlacemark%d">\n',i);
        fprintf(fid,'<IconStyle>\n');
        
        fprintf(fid,'<scale>1</scale>\n');
        
        fprintf(fid,'<Icon>\n');
        fprintf(fid,'<href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle_highlight.png</href>\n');
        fprintf(fid,'</Icon>\n');
        fprintf(fid,'</IconStyle>\n');
        fprintf(fid,'</Style>\n');

        fprintf(fid,'<visibility>0</visibility>\n');

        flarename = char(idkey{i});

        dtstr = datestr(coords(i,7),'yyyy-mm-dd HH:MM:SS');
        if coords(i,18) ~= FILLVALUE
            localdtstr = datestr(coords(i,18), 'yyyy-mm-dd HH:MM:SS');
        else
            localdtstr = '';
        end
        
        landsea = 'Ocean';
        if coords(i,10) < 3
            landsea = 'Coast';
        end
        
        write_kml_description(fid,i,verbose,'Cosmic ray',dtstr,localdtstr,flarename,coords,waters,fishery,protected,landsea,dnbname);       

        fprintf(fid,'<Point>\n');
        fprintf(fid,'<coordinates>%f,%f,0</coordinates>\n',coords(i,2),coords(i,1));
        fprintf(fid,'</Point>\n');
        fprintf(fid,'</Placemark>\n');
    end
    end
end
if ~ isempty(filesav)
    fprintf(fid,'</Folder>\n');
end
fprintf(fid,'</Folder>\n');

end

[kmlfile_pathstr, kmlfile_name, kmlfile_ext] = fileparts(kmlfile);

if docoverage && length(id) > 0
    
    fprintf(fid,'<Folder>\n');
    fprintf(fid,'<name>Coverage</name>\n');
    fprintf(fid,'<open>0</open>\n');
    
    covname = strcat(kmlfile_name,'.png');
    latLonLimits = [-90,90,-180,180];
    
    if docoverage == 1
        pcxindeg = 10;
        [lonimage, latimage] = meshgrid(0:1/pcxindeg:360-1/pcxindeg, ...
            -90:1/pcxindeg:90-1/pcxindeg);
        covimage = ones(size(lonimage));
    end
    
    latsav = '';
    lonsav = '';
    
    for i=1:size(latgring,1)
        if ~ (strcmp(latgring(i,:),latsav) && strcmp(longring(i,:),lonsav))
            latsav = latgring(i,:);
            lonsav = longring(i,:);
            latvec = cell2mat(textscan(latsav,'%f','delimiter',';'));
            lonvec = cell2mat(textscan(lonsav,'%f','delimiter',';'));
            if docoverage == 1
                covimage_new = viirs_coverage(latvec,lonvec,10);
                covimage = covimage & ~covimage_new;
            end
        end
    end
    
    if docoverage == 1
        alpha = 0.5 * covimage;
        composite = zeros(size(covimage,1), size(covimage,2), 3);
        composite(:,:,1) = covimage;
        composite(:,:,2) = covimage;
        composite(:,:,3) = covimage;
        
        disp('Writing coverage png file');
        imwrite(composite,fullfile(kmlfile_pathstr,covname),'png','Alpha',alpha);
    end
    
    fprintf(fid,'<GroundOverlay>\n');
%     fprintf(fid,'<name>%s</name>\n',covname);
    fprintf(fid,'<name>Composite</name>\n');
    fprintf(fid,'<color>c7ffffff</color>\n');
    fprintf(fid,'<visibility>1</visibility>\n');
    fprintf(fid,'<Icon>\n');
    fprintf(fid,strcat('<href>',covname,'</href>\n'));
    fprintf(fid,'<viewBoundScale>0.75</viewBoundScale>\n');
    fprintf(fid,'</Icon>\n');
    fprintf(fid,'<LatLonBox>\n');
    fprintf(fid,strcat('<north>',num2str(latLonLimits(2)),'</north>\n'));
    fprintf(fid,strcat('<south>',num2str(latLonLimits(1)),'</south>\n'));
    fprintf(fid,strcat('<east>',num2str(latLonLimits(4)),'</east>\n'));
    fprintf(fid,strcat('<west>',num2str(latLonLimits(3)),'</west>\n'));
    fprintf(fid,'</LatLonBox>\n');
    fprintf(fid,'</GroundOverlay>\n');

    %     fprintf(fid,'<Placemark>\n');
    %     fprintf(fid,'<LineString>\n');
    %     fprintf(fid,'<coordinates>\n');
    %     for j = 1:length(latvec)
    %         fprintf(fid,'%f,%f,0.\n',lonvec(j),latvec(j));
    %     end
    %     fprintf(fid,'%f,%f,0.\n',lonvec(1),latvec(1));
    %     fprintf(fid,'</coordinates>\n');
    %     fprintf(fid,'</LineString>\n');
    %     fprintf(fid,'</Placemark>\n');

    if ~ isempty(flist)
        filesav = '';
        for i=1:size(flist,1)
            [part_path, part_name, part_ext] = fileparts(flist(i,:));
            if ~ strcmp(part_name,filesav)
                filesav = part_name;
                fprintf(fid,'<GroundOverlay>\n');
                fprintf(fid,'<name>%s</name>\n',filesav);
                fprintf(fid,'<visibility>0</visibility>\n');
                fprintf(fid,'<Icon>\n');
                fprintf(fid,strcat('<href>',[filesav '.png'],'</href>\n'));
                fprintf(fid,'<viewBoundScale>0.75</viewBoundScale>\n');
                fprintf(fid,'</Icon>\n');
                fprintf(fid,'<LatLonBox>\n');
                fprintf(fid,strcat('<north>',num2str(latLonLimits(2)),'</north>\n'));
                fprintf(fid,strcat('<south>',num2str(latLonLimits(1)),'</south>\n'));
                fprintf(fid,strcat('<east>',num2str(latLonLimits(4)),'</east>\n'));
                fprintf(fid,strcat('<west>',num2str(latLonLimits(3)),'</west>\n'));
                fprintf(fid,'</LatLonBox>\n');                
                fprintf(fid,'</GroundOverlay>\n');
            end
        end
    end    

    fprintf(fid,'</Folder>\n');

    fprintf(fid,'<LookAt>\n');
    fprintf(fid,'<latitude>%f</latitude>\n',latvec(2));
    fprintf(fid,'<longitude>%f</longitude>\n',lonvec(2));
    fprintf(fid,'<range>5000000</range><tilt>0</tilt><heading>0</heading>');
    fprintf(fid,'</LookAt>\n');
    
end

fprintf(fid,'</Document>\n');
fprintf(fid,'</kml>');
fclose(fid);

end

