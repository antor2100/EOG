function h5ex_g_visit
%**************************************************************************
%  This example shows how to recursively traverse a file
%  using H5O.visit and H5L.visit.  The program prints all of
%  the objects in the file specified in FILE, then prints all
%  of the links in that file.  The default file used by this
%  example implements the structure described in the User's
%  Guide, chapter 4, figure 26.
%
%  This file is intended for use with HDF5 Library version 1.8
%**************************************************************************
%FILE = 'Data/VIIRS_20120503/SVM10_npp_d20120503_t1106402_e1112206_b02668_c20120503171222423639_noaa_ops.h5'
%FILE = 'Data/VIIRES_FIRE/GMODO-SVM10-SVM12_npp_d20120608_t0914276_e0920080_b03178_c20120620172201400390_noaa_ops.h5';
%FILE = 'Data/VIIRS_20120503/GMTCO_npp_d20120503_t0006390_e0012194_b02662_c20120503061219156658_noaa_ops.h5'
%FILE = 'Data/VIIRS_20120730/GMODO-SVM07-SVM08-SVM10-SVM12_npp_d20120730_t0800532_e0806336_b03915_c20120801183551528508_noaa_ops.h5'
%FILE = 'Data/VIIRS_20120730/GDNBO_npp_d20120730_t0800532_e0806336_b03915_c20120730140633695112_noaa_ops.h5';

%FILE = 'Data/rt/GMTCO_npp_d20120808_t1009201_e1010426_b00001_c20120808101750699611_cspp_dev.h5';

%FILE = '/Volumes/Shared/MyProjects/VIIRS-NPS/Data/aggregates/npp_d20121029_t0607468_e0613272_b05205/GDNBO_npp_d20121029_t0607468_e0613272_b05205_c20121029121327682644_noaa_ops.h5';

%%FILE = '/Volumes/Shared/MyProjects/VIIRS-NPS/Data/aggregates/npp_d20121029_t0607468_e0613272_b05205/SVDNB_npp_d20121029_t0607468_e0613272_b05205_c20121029121327683020_noaa_ops.h5';

% FILE = '../../Data/aggregates/GDNBO_npp_d20130713_t1454340_e1500126_b08856_c20130713210014277991_noaa_ops.h5';

% FILE = 'Data/VIIRS_20120503/IVCOP_npp_d20120503_t1018182_e1019424_b02668_c20120503124444486887_noaa_ops.h5'
% FILE = 'Data/North_Dakota_20120411/GMODO-IICMO-SVM07-SVM08-SVM10-SVM12-SVM13-SVM14-SVM15-SVM16_npp_d20120411_t0859348_e0905152_b02355_c20120412184507025236_noaa_ops.h5';
% FILE = 'Data/North_Dakota_20120411/GMODO-IICMO-SVM07-SVM08-SVM10-SVM12-SVM13-SVM14-SVM15-SVM16_npp_d20120411_t0859348_e0905152_b02355_c20120412184507025236_noaa_ops.h5';
% M bands
% FILE = 'GMODO-IICMO-SVM07-SVM08-SVM10-SVM12-SVM13-SVM14-SVM15-SVM16_npp_d20120408_t2154428_e2200232_b02320_c20120409180453915572_noaa_ops.h5';
% cloud mask
% FILE = 'GMODO-IICMO_npp_d20120408_t2154428_e2200232_b02320_c20120410165147340524_noaa_ops.h5';
% terrain corrected geolocation for M bands
% FILE = 'GMTCO_npp_d20120408_t2154428_e2200232_b02320_c20120409040023737058_noaa_ops.h5';

% FILE = '/Volumes/Shared/MyProjects/viirs_reprojection_java/GDNBO_npp_d20140728_t0857420_e0903224_b14244_c20140728150323137981_noaa_ops.h5';
% FILE = '/Volumes/Shared/MyProjects/Boats/M15/SVDNB_npp_d20141102_t1716320_e1722124_b15625_c20141102232213117407_noaa_ops.h5';
% FILE = '/Volumes/Shared/MyProjects/Boats/M15/SVM15_npp_d20141102_t1716320_e1722124_b15625_c20141102232213227884_noaa_ops.h5';
% FILE = '/Volumes/Shared/MyProjects/Boats/M15/GMTCO_npp_d20141102_t1716320_e1722124_b15625_c20141102232213072339_noaa_ops.h5';

% FILE = '/Volumes/Shared/MyProjects/Boats/moon_glint/npp_d20150511_t1752546_e1754188_b18321/GDNBO_npp_d20150511_t1752546_e1754188_b18321_c20150511202300200088_ssec_dev.h5';

% Bow-tie affected geolocation files
% FILE = '/Volumes/Shared/MyProjects/VIIRS-2/Data/sunlit_polar/GMTCO_npp_d20160101_t1715517_e1721303_b21655_c20160101232132162214_noaa_ops.h5';
% FILE = '/Volumes/Shared/MyProjects/Boats/npp_d20140202_t1731310_e1737096_b11752/GITCO_npp_d20140202_t1731310_e1737096_b11752_c20140202233710957218_noaa_ops.h5';
% FILE = '/Volumes/Shared/MyProjects/VIIRS-2/Data/sunlit_polar/GMTCO_npp_d20160101_t1715517_e1721303_b21655_c20160101232132162214_noaa_ops.h5';
% FILE = '/Volumes/Shared/MyProjects/Boats/boats_error2/SVDNB_npp_d20141210_t1700116_e1705520_b16164_c20141210232428968839_noaa_ops.h5'

% FILE = '/Volumes/Shared/MyProjects/VIIRS-2/Data/npp_d20121122_t2210264_e2216072_b05555_negative_RH/IVCOP_npp_d20121122_t2213176_e2214418_b05555_c20121123014017950559_noaa_ops.h5';

% New VICMO block 2 cloud product
% FILE = '/Volumes/ADATA/MyProjects/VIIRS-2/Data/VICOP_block_2/VICMO_npp_d20170309_t0537330_e0543134_b27791_c20170309114313973863_noac_ops.h5';

% FILE = 'd:\smolder\Indonesia\hdf5\GDTCN_npp_d20140926_t1852060_e1857464_b15101_c20140927005747739686_noaa_ops.h5'

FILE = 'SVDNB_npp_d20180108_t0822167_e0827571_b32120_c20180108142757736055_noac_ops.h5'

%
% Open file
%
file = H5F.open (FILE, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');

%
% Begin iteration using H5O.visit
%
disp ('Objects in the file:');
H5O.visit (file, 'H5_INDEX_NAME', 'H5_ITER_NATIVE',@op_func, []);

%
% Repeat the same process using H5L.visit
%
% disp ('Links in the file:');
% H5L.visit (file, 'H5_INDEX_NAME', 'H5_ITER_NATIVE',@op_func_L, []);

%
% Close and release resources.
%
H5F.close (file);


end


function [status opdataOut]=op_func(rootId,name,~)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%Operator function for H5O.visit.  This function prints the
%name and type of the object passed to it.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('/');               % Print root group in object path %

objId=H5O.open(rootId,name,'H5P_DEFAULT');
info=H5O.get_info(objId);
%
% Check if the current object is the root group, and if not print
% the full path name and type.
%
if (name(1) == '.')         % Root group, do not print '.' %
    fprintf ('  (Group)\n');
else
    switch (info.type)
        case H5ML.get_constant_value('H5O_TYPE_GROUP')
            disp ([name ' (Group)']);
            numAtts = H5A.get_num_attrs(objId)
            if numAtts > 0
                for i = 0:numAtts-1
                    attr = H5A.open_idx(objId, i);
                    attrName = H5A.get_name(attr)
                    attrValue = H5A.read(attr, 'H5ML_DEFAULT')'
                end
            end
            
        case H5ML.get_constant_value('H5O_TYPE_DATASET')
            spaceId = H5D.get_space(objId);
            [numdims h5_dims h5_maxdims] = H5S.get_simple_extent_dims(spaceId);
            disp ([name ' (Dataset)']);
            matlab_dims = fliplr(h5_dims)
%            disp ([matlab_dims ' (dimensions)']);
            numAtts = H5A.get_num_attrs(objId)
            if numAtts > 0
                for i = 0:numAtts-1
                    attr = H5A.open_idx(objId, i);
                    attrName = H5A.get_name(attr)
                    attrValue = H5A.read(attr, 'H5ML_DEFAULT')'
                end
            end
            
        case H5ML.get_constant_value('H5O_TYPE_NAMED_DATATYPE')
            disp ([name ' (Datatype)']);
            
        otherwise
            disp ([name '  (Unknown)']);
    end
    
end
H5O.close(objId);


opdataOut=[];
status=0;
end

function [status opdataOut]=op_func_L(gid,name,opdataIn)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%Operator function for H5L.visit.  This function simply
%retrieves the info for the object the current link points
%to, and calls the operator function for H5O.visit.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
% Get type of the object and display its name and type.
% The name of the object is passed to this function by
% the Library.
%
status=0;
opdataOut=[];
op_func (gid,name,opdataIn);
end

