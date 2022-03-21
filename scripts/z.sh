#!/bin/bash
module use /gpfs/dell2/emc/verification/noscrub/emc.metplus/modulefiles
module load met/10.0.1
module load metplus/4.0.0
module load python/3.6.3
module load NetCDF/4.5.0

set -x
TODAY=`date +%Y%m%d`

export cycle=t00z
export utilscript=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/ush
export utilexec=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec
export EXECutil=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec
export MET_PLUS_TMP=/gpfs/dell2/ptmp/Ho-Chun.Huang/metplus_aqmax

export wgrib2=/gpfs/dell1/nco/ops/nwprod/grib_util.v1.1.1/exec/wgrib2

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

## sh $utilscript/setup.sh  ## no longer existed in the system
sh $utilscript/setpdy.sh
. $MET_PLUS_TMP/PDY

export DATE=$PDYm4
export DATEP1=$PDY
export MET_PLUS=/gpfs/dell2/emc/verification/save/Ho-Chun.Huang/METplus-4.0.0
export MET_PLUS_CONF=/gpfs/dell2/emc/verification/save/Ho-Chun.Huang/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/metplus_aq
export MET_PLUS_STD=/gpfs/dell2/ptmp/Ho-Chun.Huang/metplus_aqmax

export FCST_INPUT_COMOUT=/gpfs/hps/nco/ops/com/aqm/prod
export FCST_INPUT_USER=/gpfs/dell2/ptmp/Ho-Chun.Huang/com/aqm/prod

mkdir -p ${MET_PLUS_OUT} ${MET_PLUS_STD}

cat << EOF > shared.conf_aqmax
[config]

# Time method by which to perform validation, either by init time or by valid
# time. Indicate by either BY_VALID or BY_INIT
#TIME_METHOD = BY_VALID
LOOP_BY = VALID

# For processing by init time or valid time, indicate the start and end hours
# in HH format                                                             
VALID_TIME_FMT = %Y%m%d

VALID_BEG = ${DATE}
VALID_END = ${DATE}

# Indicate the begin and end date, and interval (in hours)                                                        
#BEG_TIME = 20190502
#END_TIME = 20190502
#INTERVAL_TIME = 1
VALID_INCREMENT = 3600

# start and end dates are created by combining the date with
# start and end hours (format can be hh, hhmm, or hhmmss.                                                         
#START_DATE = {BEG_TIME}{START_HOUR}
#END_DATE = {END_TIME}{END_HOUR}

# The obs window dictionary
OBS_WINDOW_BEGIN = -43200
OBS_WINDOW_END = 43200

OBS_PB2NC_FILE_WINDOW_BEGIN = 0
OBS_PB2NC_FILE_WINDOW_END = 86400
EOF

for hour in 06 12
do

for model in aqmax1 
do

    ifile=aqm.t${hour}z.max_1hr_o3.148.grib2
    for iday in ${PDYm3} ${PDYm4} ${PDYm5}; do
        mkdir -p ${FCST_INPUT_USER}/aqm.${iday}
        if [ -s out1.grb2 ]; then /bin/rm -f out1.grb2; fi
        if [ -s out2.grb2 ]; then /bin/rm -f out2.grb2; fi
        if [ $hour -eq 06 ]; then
            ${wgrib2} -d 1 ${FCST_INPUT_COMOUT}/aqm.${iday}/${ifile} -set_ftime "-1-22 hour ave fcst" -grib out1.grb2
            ${wgrib2} -d 2 ${FCST_INPUT_COMOUT}/aqm.${iday}/${ifile} -set_ftime "23-46 hour ave fcst" -grib out2.grb2
        elif [ $hour -eq 12 ]; then
            ${wgrib2} -d 1 ${FCST_INPUT_COMOUT}/aqm.${iday}/${ifile} -set_ftime "-7-16 hour ave fcst" -grib out1.grb2
            ${wgrib2} -d 2 ${FCST_INPUT_COMOUT}/aqm.${iday}/${ifile} -set_ftime "17-40 hour ave fcst" -grib out2.grb2
        fi
        cat out1.grb2 out2.grb2 > ${FCST_INPUT_USER}/aqm.${iday}/${ifile}
    done


cat << EOF > fcst_input_temp_${model}.conf
[dir]
OUTPUT_BASE = ${MET_PLUS_OUT}
FCST_POINT_STAT_INPUT_DIR = ${FCST_INPUT_USER}
[filename_templates]
FCST_POINT_STAT_INPUT_TEMPLATE = aqm.{init?fmt=%Y%m%d}/aqm.t${hour}z.max_1hr_o3.148.grib2
EOF

${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_${model}.conf -c ${MET_PLUS_CONF}/point_stat_${model}.conf -c ${MET_PLUS_TMP}/shared.conf_aqmax -c ${MET_PLUS_CONF}/system_aq.conf -c ${MET_PLUS_TMP}/fcst_input_temp_${model}.conf


done

for model in aqmax8
do

    ifile=aqm.t${hour}z.max_8hr_o3.148.grib2
    for iday in ${PDYm3} ${PDYm4} ${PDYm5}; do
        mkdir -p ${FCST_INPUT_USER}/aqm.${iday}
        if [ -s out1.grb2 ]; then /bin/rm -f out1.grb2; fi
        if [ -s out2.grb2 ]; then /bin/rm -f out2.grb2; fi
        if [ $hour -eq 06 ]; then
            ${wgrib2} -d 1 ${FCST_INPUT_COMOUT}/aqm.${iday}/${ifile} -set_ftime "6-29 hour ave fcst" -grib out1.grb2
            ${wgrib2} -d 2 ${FCST_INPUT_COMOUT}/aqm.${iday}/${ifile} -set_ftime "30-53 hour ave fcst" -grib out2.grb2
        elif [ $hour -eq 12 ]; then
            ${wgrib2} -d 1 ${FCST_INPUT_COMOUT}/aqm.${iday}/${ifile} -set_ftime "0-23 hour ave fcst" -grib out1.grb2
            ${wgrib2} -d 2 ${FCST_INPUT_COMOUT}/aqm.${iday}/${ifile} -set_ftime "24-47 hour ave fcst" -grib out2.grb2
        fi
        cat out1.grb2 out2.grb2 > ${FCST_INPUT_USER}/aqm.${iday}/${ifile}
    done


cat << EOF > fcst_input_temp_${model}.conf
[dir]
OUTPUT_BASE = ${MET_PLUS_OUT}
FCST_POINT_STAT_INPUT_DIR = ${FCST_INPUT_USER}
[filename_templates]
FCST_POINT_STAT_INPUT_TEMPLATE = aqm.{init?fmt=%Y%m%d}/aqm.t${hour}z.max_8hr_o3.148.grib2
EOF

${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_${model}.conf -c ${MET_PLUS_CONF}/point_stat_${model}.conf -c ${MET_PLUS_TMP}/shared.conf_aqmax -c ${MET_PLUS_CONF}/system_aq.conf -c ${MET_PLUS_TMP}/fcst_input_temp_${model}.conf

done


for model in pmmax
do

    ## Need to copy to ${FCST_INPUT_USER} if FCST_POINT_STAT_INPUT_DIR = ${FCST_INPUT_USER}
    for iday in ${PDYm3} ${PDYm4} ${PDYm5}; do
        mkdir -p ${FCST_INPUT_USER}/aqm.${iday}
        cp -p ${FCST_INPUT_COMOUT}/aqm.${iday}/aqm.t${hour}z.max_1hr_pm25.148.grib2 ${FCST_INPUT_USER}/aqm.${iday}
    done

cat << EOF > fcst_input_temp_${model}.conf
[dir]
OUTPUT_BASE = ${MET_PLUS_OUT}
FCST_POINT_STAT_INPUT_DIR = ${FCST_INPUT_USER}
[filename_templates]
FCST_POINT_STAT_INPUT_TEMPLATE = aqm.{init?fmt=%Y%m%d}/aqm.t${hour}z.max_1hr_pm25.148.grib2
EOF

${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_${model}.conf -c ${MET_PLUS_CONF}/point_stat_${model}.conf -c ${MET_PLUS_TMP}/shared.conf_aqmax -c ${MET_PLUS_CONF}/system_aq.conf -c ${MET_PLUS_TMP}/fcst_input_temp_${model}.conf

done

for model in pmave
do

    ## Need to copy to ${FCST_INPUT_USER} if FCST_POINT_STAT_INPUT_DIR = ${FCST_INPUT_USER}
    for iday in ${PDYm3} ${PDYm4} ${PDYm5}; do
        mkdir -p ${FCST_INPUT_USER}/aqm.${iday}
        cp -p ${FCST_INPUT_COMOUT}/aqm.${iday}/aqm.t${hour}z.ave_24hr_pm25.148.grib2 ${FCST_INPUT_USER}/aqm.${iday}
    done

cat << EOF > fcst_input_temp_${model}.conf
[dir]
OUTPUT_BASE = ${MET_PLUS_OUT}
FCST_POINT_STAT_INPUT_DIR = ${FCST_INPUT_USER}
[filename_templates]
FCST_POINT_STAT_INPUT_TEMPLATE = aqm.{init?fmt=%Y%m%d}/aqm.t${hour}z.ave_24hr_pm25.148.grib2
EOF

${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_${model}.conf -c ${MET_PLUS_CONF}/point_stat_${model}.conf -c ${MET_PLUS_TMP}/shared.conf_aqmax -c ${MET_PLUS_CONF}/system_aq.conf -c ${MET_PLUS_TMP}/fcst_input_temp_${model}.conf

done

done

## mv ${MET_PLUS_OUT}/logs/master_metplus.log.${DATEP1} ${MET_PLUS_TMP}
mv ${MET_PLUS_OUT}/logs/master_metplus.log.${TODAY}* ${MET_PLUS_TMP}

exit
