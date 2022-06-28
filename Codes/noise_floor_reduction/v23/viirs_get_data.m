%%
function [data] = viirs_get_data(h5name, h5dataset)

file = H5F.open (h5name, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
dset = H5D.open (file, h5dataset);
%attr = H5A.open_name (dset, ATTRIBUTE);

spaceId = H5D.get_space(dset);
[numdims h5_dims h5_maxdims] = H5S.get_simple_extent_dims(spaceId);

dxpl = 'H5P_DEFAULT';
data = H5D.read(dset,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',dxpl);

H5F.close (file);

end
