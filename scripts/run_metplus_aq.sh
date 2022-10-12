#!/bin/bash

#PBS -N metplus_aq
#PBS -o /lfs/h2/emc/ptmp/${USER}/output/metplus_aq.o%J
#PBS -e /lfs/h2/emc/ptmp/${USER}/output/metplus_aq.o%J
#PBS -q dev
#PBS -A VERF-DEV
# 
#PBS -l place=shared,select=1:ncpus=1:mem=4500MB
#PBS -l walltime=04:00:00
#PBS -l debug=true

module load met/10.1.1
module load metplus/4.1.1
module load python/3.6.3

set -x

export cycle=t00z
export utilscript=/apps/ops/prod/nco/core/prod_util.v2.0.13/ush
export utilexec=/apps/ops/prod/nco/core/prod_util.v2.0.13/exec
export EXECutil=/apps/ops/prod/nco/core/prod_util.v2.0.13/exec
export MET_PLUS_TMP=/lfs/h2/emc/ptmp/${USER}/metplus_aqtest

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

sh $utilscript/setup.sh
sh $utilscript/setpdy.sh
. $MET_PLUS_TMP/PDY

export DATE=$PDYm1
export DATEP1=$PDY
export MET_PLUS=/lf/sh2/emc/vpppg/save/${USER}/METplus-4.0.0
export MET_PLUS_CONF=/lf/sh2/emc/vpppg/save/${USER}/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/lfs/h2/emc/physics/noscrub/${USER}/metplus_aqtest
export MET_PLUS_STD=/lfs/h2/emc/ptmp/${USER}/metplus_aqtest

mkdir -p ${MET_PLUS_OUT} ${MET_PLUS_STD}

cat << EOF > shared.conf_aq
[config]
VALID_BEG = ${DATE}01
VALID_END = ${DATEP1}00

OBS_WINDOW_BEGIN = -86400
OBS_WINDOW_END = 86400

VALID_INCREMENT = 1H
## INIT_SEQ = 6, 12
INIT_SEQ = 12
LEAD_SEQ_MAX = 72
EOF

## model=aq
model=icmaq150a_aq
model1=`echo $model | tr a-z A-Z`
echo $model1


## FCST_POINT_STAT_INPUT_DIR = /lfs/h1/ops/prod/com/aqm/v6.1
## PB2NC_INPUT_DIR = /lfs/h1/ops/prod/com/obsproc/v1.0
## FCST_POINT_STAT_INPUT_TEMPLATE = cs.{init?fmt=%Y%m%d}/aqm.t{init?fmt=%2H}z.awpozcon.f{lead?fmt=%2H}.148.grib2
## OBS_POINT_STAT_INPUT_TEMPLATE = prepbufr.aqm.{valid?fmt=%Y%m%d%H}.nc
## PB2NC_OUTPUT_TEMPLATE  = prepbufr.aqm.{valid?fmt=%Y%m%d%H}.nc
cat << EOF > ${model}.conf
[dir]
FCST_POINT_STAT_INPUT_DIR = /lfs/h2/emc/ptmp/ho-chun.huang/expt_dirs/test_cmaq13_a
OBS_POINT_STAT_INPUT_DIR = {OUTPUT_BASE}/aqm/conus_sfc
PB2NC_INPUT_DIR = /lfs/h2/emc/physics/noscrub/Perry.Shafran/com/hourly/prod
[config]
PB2NC_OBS_BUFR_VAR_LIST= COPO
METPLUS_CONF = {OUTPUT_BASE}/conf/${model}/metplus_final_pb2nc_pointstat.conf
POINT_STAT_CONFIG_FILE ={PARM_BASE}/met_config/PointStatConfig_AIRNOW
#LEAD_SEQ = begin_end_incr(1,72,1)
MODEL = ${model1}
FCST_VAR1_NAME = OZCON
FCST_VAR1_LEVELS = A1
FCST_VAR1_OPTIONS = set_attr_name = "OZCON1";
OBS_VAR1_NAME= COPO
OBS_VAR1_LEVELS= A1
OBS_VAR1_OPTIONS =  convert(x) = x * 10^9;
FCST_VAR2_NAME = OZCON
FCST_VAR2_LEVELS = A8
FCST_VAR2_OPTIONS = set_attr_name = "OZCON8";
OBS_VAR2_NAME= COPO
OBS_VAR2_LEVELS= A8
OBS_VAR2_OPTIONS =  convert(x) = x * 10^9;
[filename_templates]
FCST_POINT_STAT_INPUT_TEMPLATE = {init?fmt=%Y%m%d%H}/postprd/rrfs.t{init?fmt=%2H}z.natlevf{lead?fmt=%3H}.tm00.grib2
OBS_POINT_STAT_INPUT_TEMPLATE = prepbufr.aqm.${DATE}.nc
POINT_STAT_OUTPUT_TEMPLATE = ${model}
PB2NC_INPUT_TEMPLATE = hourly.{da_init?fmt=%Y%m%d}/aqm.t12z.prepbufr.tm00
PB2NC_OUTPUT_TEMPLATE = prepbufr.aqm.${DATE}.nc
EOF

${MET_PLUS}/ush/run_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_aq.conf -c ${MET_PLUS_CONF}/point_stat_aq.conf -c ${MET_PLUS_TMP}/${model}.conf -c ${MET_PLUS_CONF}/shared.conf -c ${MET_PLUS_TMP}/shared.conf_aq -c ${MET_PLUS_CONF}/system_aq.conf

cat << EOF > statanalysis.conf
[dir]
STAT_ANALYSIS_OUTPUT_DIR = {OUTPUT_BASE}/stat/aqm
MODEL1_STAT_ANALYSIS_LOOKIN_DIR = {OUTPUT_BASE}/aqm/stat/${model}/*{VALID_BEG}*
[config]
VALID_BEG = ${DATE}
VALID_END = ${DATEP1}
MODEL = $model
MODEL1 = $model1
EOF

${MET_PLUS}/ush/run_metplus.py -c ${MET_PLUS_CONF}/system_aq.conf -c ${MET_PLUS_CONF}/StatAnalysis_gatherByHour_aq.conf -c ${MET_PLUS_TMP}/statanalysis.conf


#${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_aq.conf -c ${MET_PLUS_CONF}/point_stat_aq.conf -c ${MET_PLUS_TMP}/${model}.conf -c ${MET_PLUS_CONF}/shared.conf -c ${MET_PLUS_TMP}/shared.conf_aq -c ${MET_PLUS_CONF}/system_aq.conf -c ${MET_PLUS_CONF}/StatAnalysis_gatherByHour_aq.conf -c ${MET_PLUS_TMP}/statanalysis.conf

## model=pm
model=icmaq150a_pm
model1=`echo $model | tr a-z A-Z`
echo $model1

## FCST_POINT_STAT_INPUT_DIR = /lfs/h1/ops/prod/com/aqm/v6.1
## FCST_POINT_STAT_INPUT_TEMPLATE = cs.{init?fmt=%Y%m%d}/aqm.t{init?fmt=%2H}z.pm25.f{lead?fmt=%2H}.148.grib2
## OBS_POINT_STAT_INPUT_TEMPLATE = prepbufr.pm.{valid?fmt=%Y%m%d%H}.nc
## PB2NC_OUTPUT_TEMPLATE  = prepbufr.pm.{valid?fmt=%Y%m%d%H}.nc
cat << EOF > ${model}.conf
[dir]
FCST_POINT_STAT_INPUT_DIR = /lfs/h2/emc/ptmp/ho-chun.huang/expt_dirs/test_cmaq13_a
OBS_POINT_STAT_INPUT_DIR = {OUTPUT_BASE}/aqm/conus_sfc
PB2NC_INPUT_DIR = /lfs/h2/emc/physics/noscrub/Perry.Shafran/com/hourly/prod
[config]
PB2NC_OBS_BUFR_VAR_LIST= COPOPM
METPLUS_CONF = {OUTPUT_BASE}/conf/${model}/metplus_final_pb2nc_pointstat.conf
POINT_STAT_CONFIG_FILE ={PARM_BASE}/met_config/PointStatConfig_ANOWPM
###LEAD_SEQ = begin_end_incr(0,72,1)
FCST_VAR1_NAME = PMTF
FCST_VAR1_LEVELS = L1
OBS_VAR1_NAME= COPOPM
OBS_VAR1_LEVELS= A1
OBS_VAR1_OPTIONS =  convert(x) = x * 10^9;
MODEL = ${model1}
[filename_templates]
FCST_POINT_STAT_INPUT_TEMPLATE = {init?fmt=%Y%m%d%H}/postprd/rrfs.t{init?fmt=%2H}z.natlevf{lead?fmt=%3H}.tm00.grib2
OBS_POINT_STAT_INPUT_TEMPLATE = prepbufr.pm.${DATE}.nc
POINT_STAT_OUTPUT_TEMPLATE = ${model}
PB2NC_INPUT_TEMPLATE = hourly.{da_init?fmt=%Y%m%d?shift=86400}/aqm.t12z.anowpm.pb.tm024
PB2NC_OUTPUT_TEMPLATE = prepbufr.pm.${DATE}.nc
EOF

${MET_PLUS}/ush/run_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_aq.conf -c ${MET_PLUS_CONF}/point_stat_aq.conf -c ${MET_PLUS_TMP}/${model}.conf -c ${MET_PLUS_CONF}/shared.conf -c ${MET_PLUS_TMP}/shared.conf_aq -c ${MET_PLUS_CONF}/system_aq.conf

cat << EOF > statanalysis.conf
[dir]
STAT_ANALYSIS_OUTPUT_DIR = {OUTPUT_BASE}/stat/aqm
MODEL1_STAT_ANALYSIS_LOOKIN_DIR = {OUTPUT_BASE}/aqm/stat/{MODEL}/*{VALID_BEG}*
[config]
VALID_BEG = $DATE
VALID_END = $DATEP1
MODEL = $model
MODEL1 = $model1
EOF

${MET_PLUS}/ush/run_metplus.py -c ${MET_PLUS_CONF}/system_aq.conf ${MET_PLUS_CONF}/StatAnalysis_gatherByHour.conf ${MET_PLUS_TMP}/statanalysis.conf


mv ${MET_PLUS_OUT}/logs/master_metplus.log.${DATEP1} ${MET_PLUS_TMP}

exit
