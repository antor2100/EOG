#!/usr/bin/env python

import sys
import os
#from ngdc_file_tools import ngdc_get_fnames, ngdc_make_envi_hdr
import h5py
import numpy as np
import congrid
import julian
import datetime
#from ngdc_lunar_illum import ngdc_lunar_illum
#debug
# import matplotlib.pyplot as plt


def ngdc_viirs_li(h5_geo_fname, li_fname, sampling_factor=100, out_dir='./'):

    '''
    :param h5_geo_fname:
    :param li_fanem:
    :param sampling_factor:
    :param out_dir:
    :return:
    '''

    '''Check input files and assign default values'''
    if h5_geo_fname is None:
        print('Input VIIRS Geo filename not defined')
        sys.exit(1)
    if sampling_factor is None:
        print('sampling factor default to ', sampling_factor)
    if out_dir is None:
        print('out_dir default to ', out_dir)
    if li_fname is None:
        li_fname = sys.path.join(out_dir, sys.path.basename(h5_geo_fname)) + '_li'
    li_fname_info = ngdc_get_fnames(li_fname, newfile=True)

    # Get lat/lon/time from h5 file

    alldata_prefix = 'All_Data/VIIRS-DNB-GEO_All/'
    if os.path.basename(h5_geo_fname).startswith('GMTCO'):
        alldata_prefix = 'All_Data/VIIRS-MOD-GEO-TC_All'

    f = h5py.File(h5_geo_fname)
    lat = f[alldata_prefix+'Latitude']
    # print(lat)
    lon = f[alldata_prefix+'Longitude']
    time = f[alldata_prefix+'MidTime']
    # f.close()

    sz = lat.shape
    ns = sz[1]
    nl = sz[0]
    # print('sz',sz)
    # print(np.ceil(ns/float(sampling_factor)),
    #       np.ceil(ns/float(sampling_factor)).astype(int))
    ns_li = np.ceil(ns/float(sampling_factor)).astype(int)
    nl_li = np.ceil(nl/float(sampling_factor)).astype(int)
    # print([nl_li, ns_li])
    if sampling_factor != 1:
        lat = congrid(lat, [nl_li, ns_li])
        lon = congrid(lon, [nl_li, ns_li])

    li_data = np.zeros([nl_li, ns_li])
    time_buff = 0
    #ini_jul = np.sum(jdcal.gcal2jd(1958, 1, 1))
    ini_jul = julian.to_jd(datetime.datetime(1958, 1, 1))
    for i in range(0, nl-1, sampling_factor):

        # MidTime is same for every 16 lines in single scale
        time_l = time[i/16]
        # Check for no_data values, if any take average of neighbors
        # No need to check for lat/lon array because re-sampling
        # will smear the no_data scan, this is usually caused by leap scans
        if time_l == -993:
            # check for beginning/ending aggregate scans
            m = 0 if i == 0 else 1
            n = 0 if (i+sampling_factor >= nl-1) else 1
            # if any in either pre or aft, take its counterpart to get valid average
            # resulted average will remain no_data value [-993] if filed
            pre_time = time[i/16+n] if (time[i/16-m] == -993) else time[i/16-m]
            aft_time = time[i/16-m] if (time[i/16+n] == -993) else time[i/16+n]
            time_l = (pre_time+aft_time)/2
        # Predict mid scan time if scan line or granule is missing
        time_o = time_l  # preserve time_l value for last exam
        if time_l < time_buff:
            time_l = time_buff + 1779250
        # Calculate Julian Day of IECT time
        time_jul = time_l/1000000.0/86400 + ini_jul
        # Convert to month, day, year, hour, minute, second
        dt = julian.from_jd(time_jul)
        # print(dt)
        y = dt.year
        m = dt.month
        d = dt.day
        hr = dt.hour
        min = dt.minute
        sec = dt.second+dt.microsecond/1000000.0

        # Replicate time values into lines
        #time_y = replicate(y, ns_li)
        time_y = [y]*ns_li
        #time_y = replicate(y, ns_li)
        time_m = [m]*ns_li
        time_d = [d]*ns_li
        time_hr = [hr]*ns_li
        time_min = [min]*ns_li
        time_sec = [sec]*ns_li

        # make sure missing scan line/granule be excluded
        if time_o < -999:
            lunar = lunar_illum_thresh+1
        else:
            # print(i/sampling_factor)
            lunar = ngdc_lunar_illum(lon[np.array(i/sampling_factor).astype(int), :],
                                     lat[np.array(i/sampling_factor).astype(int), :],
                                     time_y, time_m, time_d,
                                     time_hr, time_min)
        li_data[np.array(i/sampling_factor).astype(int), :] = lunar.astype(float)
        # print('i',i)
        # print('lunar',lunar)
        # print('time_y',time_y)
        # print('time_m',time_m)
        # print('time_d',time_d)
        # print('time_hr',time_hr)
        # print('time_min',time_min)
        # llat=lat[np.array(i/sampling_factor).astype(int), :]
        # llon=lon[np.array(i/sampling_factor).astype(int), :]
        # print('(lat,lon)',[(llon[i],llat[i]) for i in range(0,len(llat))])
        # print('lunar',lunar)
        # plt.plot(lon[np.array(i/sampling_factor).astype(int), :])
        # plt.plot(lat[np.array(i/sampling_factor).astype(int), :])
        # plt.plot(lunar)
        # plt.show()

        # print('type(li_data)',type(li_data))
        # print('li_data.dtype',li_data.dtype)
        # print('type(li_data.dtype)',type(li_data.dtype))

    # of=open('F:/test_raw','wb')
    # of.write(li_data)
    # of.close()
    # plt.plot(li_data)
    # plt.show()
    # print(np.min(li_data), np.max(li_data))
    # rns = li_data.shape[1]
    # rnl = li_data.shape[0]
    # ngdc_make_envi_hdr('F:/test_raw.hdr', rns, rnl, n_bands=1, data_type=li_data.dtype, interleave='bsq')


    if sampling_factor != 1:
        # resample illumination array to original dimension
        li_data = congrid(li_data, [nl, ns], method='linear')
    dt_li = li_data.dtype

    # plt.plot(li_data)
    # plt.show()

    if li_fname_info['compress']:
        import gzip
        of = gzip.open(li_fname_info['fname'], mode='wb')
        of.write(li_data)
        of.close()
    of = open(li_fname_info['fname'], 'wb')
    of.write(li_data)
    of.close()
    # print(np.min(li_data), np.max(li_data))
    ngdc_make_envi_hdr(li_fname_info['fname_hdr'], ns, nl, n_bands=1,
                       data_type=dt_li, description='Lunar Illumiinance (lux)',
                       band_names=['lunar illum'], interleave='bsq')

    f.close()

ngdc_viirs_li('GDNBO_npp_d20220430_t1334313_e1335555_b54440_c20220430150717106796_oebc_ops.h5', None, None, None)
