import os
import glob
from dateutil import rrule
import datetime
import netCDF4 as netcdf
import numpy as np

a = '20200101'
b = '20201231'
YYYYmmdd_list = []
for dt in rrule.rrule(rrule.DAILY,
                      dtstart=datetime.datetime.strptime(a, '%Y%m%d'),
                      until=datetime.datetime.strptime(b, '%Y%m%d')):
    YYYYmmdd_list.append(dt.strftime('%Y%m%d'))
for YYYYmmdd in YYYYmmdd_list:
    mmdd = YYYYmmdd[4:]
    mm = YYYYmmdd[4:6]
    dd = YYYYmmdd[6:]
    dayofyear = str(int(datetime.datetime.strptime(YYYYmmdd, '%Y%m%d').strftime('%j')))
    new_climo_mean_file = ('/gpfs/dell2/emc/verification/noscrub/emc.verif/global/'
                           +'climo/new_climo_files/imerg/IMERG-Final.CLIM.'+mmdd+'.V06.nc')
    if os.path.exists(new_climo_mean_file):
        os.remove(new_climo_mean_file)
    new_climo_mean = netcdf.Dataset(
        new_climo_mean_file, 'w',
        format='NETCDF3_CLASSIC'
        #format='NETCDF3_64BIT'
    )
    if mmdd == '0229':
        imerg_file1 = 'IMERG-Final.CLIM.0228.V06.nc4'
        imerg_file2 = 'IMERG-Final.CLIM.0301.V06.nc4'
        print(mmdd+' '+dayofyear+' '+imerg_file1+' '+imerg_file2+' '+new_climo_mean_file)
        imerg_file_data1 = netcdf.Dataset(imerg_file1)
        imerg_lon1 = imerg_file_data1.variables['lon'][:]
        imerg_lat1 = imerg_file_data1.variables['lat'][:]
        imerg_precipitation1 = imerg_file_data1.variables['precipitation'][:]
        imerg_ncattrs1 = imerg_file_data1.ncattrs()
        imerg_file_dim_list1 = [dim for dim in imerg_file_data1.dimensions]
        imerg_file_var_list1 = [var for var in imerg_file_data1.variables]
        imerg_file_data2 = netcdf.Dataset(imerg_file2)
        imerg_lon2 = imerg_file_data2.variables['lon'][:]
        imerg_lat2 = imerg_file_data2.variables['lat'][:]
        imerg_precipitation2 = imerg_file_data2.variables['precipitation'][:]
        imerg_ncattrs2 = imerg_file_data2.ncattrs()
        imerg_file_dim_list2 = [dim for dim in imerg_file_data2.dimensions]
        imerg_file_var_list2 = [var for var in imerg_file_data2.variables]
        imerg_lon = imerg_lon1
        imerg_lat = imerg_lat1
        imerg_precipitation = (imerg_precipitation1+imerg_precipitation2)/2.
        imerg_ncattrs = imerg_ncattrs1
        imerg_file_dim_list = imerg_file_dim_list1
        imerg_file_var_list = imerg_file_var_list1
    else:
        imerg_file = 'IMERG-Final.CLIM.'+mmdd+'.V06.nc4'
        print(mmdd+' '+dayofyear+' '+imerg_file+' '+new_climo_mean_file)
        imerg_file_data = netcdf.Dataset(imerg_file)
        imerg_lon = imerg_file_data.variables['lon'][:]
        imerg_lat = imerg_file_data.variables['lat'][:]
        imerg_precipitation = imerg_file_data.variables['precipitation'][:]
        imerg_ncattrs = imerg_file_data.ncattrs()
        imerg_file_dim_list = [dim for dim in imerg_file_data.dimensions]
        imerg_file_var_list = [var for var in imerg_file_data.variables]
    #output file -- write attrs
    for attr in imerg_ncattrs:
        new_climo_mean.setncattr(
            attr, imerg_file_data.getncattr(attr)
        )
    new_climo_mean.setncattr('Conventions', 'CF-1.8')
    ##new_climo_mean.setncattr(
    ##    'history', 'Time series of total daily OLR are from NOAA/PSL '
    ##               +'https://www.psl.noaa.gov/data/gridded/'
    ##               +'data.interp_OLR.html, The PSL daily OLR are '
    ##               +'derived from the gridded individual satellite '
    ##               +'AVHRR OLR put together at CPC, Feb.29 as the mean '
    ##               +'of Feb.28 and Mar. 1, '
    ##               +'Data recieved from CPC by EMC, '
    ##               +'converted from binary to netCDF with GrADS, '
    ##               +'cleaned up to make CF-compliant' 
    ##)
    #output file -- write dimensions
    for dim_name in imerg_file_dim_list:
        dim_length = len(imerg_file_data.dimensions[dim_name])
        new_climo_mean.createDimension(dim_name,  dim_length)
    new_climo_mean.createDimension('time',  None)
    #output file -- write variables
    for var_name in imerg_file_var_list:
        write_var = new_climo_mean.createVariable(
            var_name, imerg_file_data.variables[var_name].datatype,
            imerg_file_data.variables[var_name].dimensions
        )
        for k in imerg_file_data.variables[var_name].ncattrs():
            write_var.setncatts(
                {k: imerg_file_data.variables[var_name]. \
                 getncattr(k)}
            )
        if var_name == 'lat':
            write_var.setncatts(
                {'long_name': 'Latitude',
                 'units': 'degrees_north',
                 'standard_name': 'latitude'}
            )
        elif var_name == 'lon':
            write_var.setncatts(
                {'long_name': 'Longitude',
                 'units': 'degrees_east',
                 'standard_name': 'longitude'}
            )
        elif var_name == 'precipitation':
            write_var.setncatts(
                {'long_name': 'Daily Longterm Mean of Precipitation',
                 'units': 'mm/day',
                 'var_desc': 'Precipitation Amount',
                 'statistic': 'Long Term Mean',
                 '_FillValue': -9999.9}
            )
        write_var[:] = (
            imerg_file_data.variables[var_name][:]
        )
    write_var = new_climo_mean.createVariable(
        'time', imerg_file_data.variables[var_name].datatype,
        ('time',)
    )
    write_var.setncatts(
        {'long_name': 'Time',
         'standard_name': 'time',
         'units': 'hours since 2020-01-01 00:00',
         'delta_t': '0000-00-01 00:00:00'}
    )
    base_time = datetime.datetime.strptime('2020-01-01 00:00',
                                          '%Y-%m-%d %H:%M')
    day_time = datetime.datetime.strptime('2020-'+mm+'-'+dd+' 00:00',
                                          '%Y-%m-%d %H:%M')
    hours_since = (base_time - day_time).total_seconds()/(60.*60.)
    print(base_time - datetime.timedelta(hours=hours_since))
    write_var[:] = -1 * hours_since
