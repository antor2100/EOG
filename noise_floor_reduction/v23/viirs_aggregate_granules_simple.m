%%
function aggregate = viirs_aggregate_granules_simple(namesmap, h5dataset)

global FILLVALUE;

ngrans = namesmap.length();

if ngrans == 0
    aggregate = [];
    return
else
    grannames = namesmap.values();
    gname = char(grannames(1));
    [pathstr, name, ext] = fileparts(gname);
    if strcmp('.h5',ext)
        granule = viirs_get_data(gname, h5dataset);
	if size(granule, 2) == 1
	    granule = granule';
	end
    else
        % gname
        granule = freadenvi(gname)';
    end 
end

% size(granule)
aggregate = ones(size(granule,1),ngrans * size(granule,2)) * FILLVALUE;
% size(aggregate)
aggregate(:,1:size(granule,2)) = granule;

for granind=2:ngrans
    gname = char(grannames(granind));
    [pathstr, name, ext] = fileparts(gname);
    if strcmp('.h5',ext)
        granule = viirs_get_data(gname, h5dataset);
	if size(granule, 2) == 1
	    granule = granule';
	end
    else
        granule = freadenvi(gname)';
    end
    aggregate(:,1+(granind-1)*size(granule,2):granind*size(granule,2)) = granule;
end

end

