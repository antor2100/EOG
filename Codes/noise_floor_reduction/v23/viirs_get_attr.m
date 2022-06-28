%%
function [attrValue] = viirs_get_attr(h5name, h5group, h5attribute)

file = H5F.open (h5name, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
group = H5G.open(file,h5group);
attr = H5A.open_name (group, h5attribute);

attrValue = H5A.read(attr)';

H5A.close (attr);
H5G.close(group);
H5F.close (file);

end
