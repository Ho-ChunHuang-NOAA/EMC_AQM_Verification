#!/bin/bash

set -x

STARTDATE=2019080100
ENDDATE=2019090100
DATE=$STARTDATE

###cd /ptmp/wx20ps/temp

while [ $DATE -le $ENDDATE ]; do

echo $DATE > curdate
DAY=`cut -c 1-8 curdate`
YEAR=`cut -c 1-4 curdate`
MONTH=`cut -c 1-6 curdate`

DATEP1=`/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec/ips/ndate +24 $DATE`

echo $DATEP1 > curdate2
DAYP1=`cut -c 1-8 curdate2`
YEARP1=`cut -c 1-4 curdate2`
MONTHP1=`cut -c 1-6 curdate2`

export cycle=t00z
export utilscript=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/ush
export utilexec=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec
export EXECutil=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec
export MET_PLUS_TMP=/gpfs/dell2/ptmp/Ho-Chun.Huang/metplus_aq

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

#sh $utilscript/setup.sh
#sh $utilscript/setpdy.sh
#. $MET_PLUS_TMP/PDY

#export DATE=$PDYm3
#export DATEP1=$PDYm2
#export DATEP2=$PDY
#export DATE=20190810
#export DATEP1=20190811
#export DATEP2=20190812
export MET_PLUS=/gpfs/dell2/emc/verification/save/Ho-Chun.Huang/METplus-4.0.0
export MET_PLUS_CONF=/gpfs/dell2/emc/verification/save/Ho-Chun.Huang/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/metplus_aq
export MET_PLUS_STD=/gpfs/dell2/ptmp/Ho-Chun.Huang/metplus_aq

cat << EOF > shared.conf_aq
[config]
VALID_BEG = ${DAY}01
VALID_END = ${DAYP1}00

OBS_WINDOW_BEGIN = -86400
OBS_WINDOW_END = 86400

VALID_INCREMENT = 1H
INIT_SEQ = 12
LEAD_SEQ_MAX = 48
EOF

model=rrfscmaqv143b_aq
model1=`echo $model | tr a-z A-Z`
echo $model1


cat << EOF > ${model}.conf
[dir]
FCST_POINT_STAT_INPUT_DIR =  /gpfs/dell2/emc/retros/noscrub/Jianping.Huang/data/RRFSCMAQ/v143_b
OBS_POINT_STAT_INPUT_DIR = {OUTPUT_BASE}/aqm/conus_sfc
PB2NC_INPUT_DIR = /gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/com/hourly/prod
[config]
PB2NC_OBS_BUFR_VAR_LIST= COPO
METPLUS_CONF = {OUTPUT_BASE}/conf/${model}/metplus_final_pb2nc_pointstat.conf
POINT_STAT_CONFIG_FILE ={PARM_BASE}/met_config/PointStatConfig_AIRNOW
#LEAD_SEQ = begin_end_incr(1,48,1)
MODEL = ${model1}
FCST_VAR1_NAME = OZCON
FCST_VAR1_LEVELS = L1
OBS_VAR1_NAME= COPO
OBS_VAR1_LEVELS= A1
OBS_VAR1_OPTIONS =  convert(x) = x * 10^9;
[filename_templates]
FCST_POINT_STAT_INPUT_TEMPLATE = {init?fmt=%Y%m%d%H}/postprd/rrfs.t{init?fmt=%2H}z.natlevf{lead?fmt=%3H}.tm00.grib2
#OBS_POINT_STAT_INPUT_TEMPLATE = prepbufr.aqm.{valid?fmt=%Y%m%d%H}.nc
OBS_POINT_STAT_INPUT_TEMPLATE = prepbufr.aqm.${DATE}.nc
POINT_STAT_OUTPUT_TEMPLATE = ${model}
PB2NC_INPUT_TEMPLATE = hourly.{da_init?fmt=%Y%m%d}/aqm.t12z.prepbufr.tm00
#PB2NC_OUTPUT_TEMPLATE  = prepbufr.aqm.{valid?fmt=%Y%m%d%H}.nc
PB2NC_OUTPUT_TEMPLATE = prepbufr.aqm.${DATE}.nc
EOF

${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_aq.conf -c ${MET_PLUS_CONF}/point_stat_aq.conf -c ${MET_PLUS_TMP}/${model}.conf -c ${MET_PLUS_CONF}/shared.conf -c ${MET_PLUS_TMP}/shared.conf_aq -c ${MET_PLUS_CONF}/system_aq.conf

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

${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS_CONF}/system_aq.conf -c ${MET_PLUS_CONF}/StatAnalysis_gatherByHour_aq.conf -c ${MET_PLUS_TMP}/statanalysis.conf


#${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_aq.conf -c ${MET_PLUS_CONF}/point_stat_aq.conf -c ${MET_PLUS_TMP}/${model}.conf -c ${MET_PLUS_CONF}/shared.conf -c ${MET_PLUS_TMP}/shared.conf_aq -c ${MET_PLUS_CONF}/system_aq.conf -c ${MET_PLUS_CONF}/StatAnalysis_gatherByHour_aq.conf -c ${MET_PLUS_TMP}/statanalysis.conf

model=rrfscmaqv143b_pm
model1=`echo $model | tr a-z A-Z`
echo $model1

cat << EOF > ${model}.conf
[dir]
FCST_POINT_STAT_INPUT_DIR =  /gpfs/dell2/emc/retros/noscrub/Jianping.Huang/data/RRFSCMAQ/v143_b
OBS_POINT_STAT_INPUT_DIR = {OUTPUT_BASE}/aqm/conus_sfc
PB2NC_INPUT_DIR = /gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/com/hourly/prod
[config]
PB2NC_OBS_BUFR_VAR_LIST= COPOPM
METPLUS_CONF = {OUTPUT_BASE}/conf/${model}/metplus_final_pb2nc_pointstat.conf
POINT_STAT_CONFIG_FILE ={PARM_BASE}/met_config/PointStatConfig_ANOWPM
###LEAD_SEQ = begin_end_incr(0,48,1)
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
#PB2NC_OUTPUT_TEMPLATE  = prepbufr.pm.{valid?fmt=%Y%m%d%H}.nc
PB2NC_OUTPUT_TEMPLATE = prepbufr.pm.${DATE}.nc
EOF

${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_aq.conf -c ${MET_PLUS_CONF}/point_stat_aq.conf -c ${MET_PLUS_TMP}/${model}.conf -c ${MET_PLUS_CONF}/shared.conf -c ${MET_PLUS_TMP}/shared.conf_aq -c ${MET_PLUS_CONF}/system_aq.conf

DATE=`/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec/ips/ndate +24 $DATE`

done

exit

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

${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS_CONF}/system_aq.conf ${MET_PLUS_CONF}/StatAnalysis_gatherByHour.conf ${MET_PLUS_TMP}/statanalysis.conf


mv ${MET_PLUS_OUT}/logs/master_metplus.log.${DATEP1} ${MET_PLUS_TMP}

exit
