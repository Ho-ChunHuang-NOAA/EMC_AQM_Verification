#!/bin/bash

#BSUB -J metplus_cmaq_viirs_aod
#BSUB -o /gpfs/dell2/ptmp/Perry.Shafran/output/metplus_cmaq_viirs_aod.o%J
#BSUB -e /gpfs/dell2/ptmp/Ho-Chun.Huang/output/metplus_cmaq_viirs_aod.o%J
#BSUB -q "dev2"
#BSUB -P VERF-T2O
#BSUB -R "rusage[mem=3000]"
#BSUB -n 1
#BSUB -W 04:00

set -x

export cycle=t00z
export utilscript=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/ush
export utilexec=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec
export EXECutil=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec
export MET_PLUS_TMP=/gpfs/dell2/ptmp/Ho-Chun.Huang/metplus_cmaq_viirs_aod

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

sh $utilscript/setup.sh
sh $utilscript/setpdy.sh
. $MET_PLUS_TMP/PDY

export DATE=$PDYm3
export DATEP1=$PDY
export DATEM1=$PDYm4
export MET_PLUS=/gpfs/dell2/emc/verification/save/Ho-Chun.Huang/METplus-4.0.0
export MET_PLUS_CONF=/gpfs/dell2/emc/verification/save/Ho-Chun.Huang/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/metplus_cmaqviirsaod
export MET_PLUS_STD=/gpfs/dell2/ptmp/Ho-Chun.Huang/metplus_cmaq_viirs_aod_${DATE}

mkdir -p $MET_PLUS_STD

export model=aqm
model1=`echo $model | tr a-z A-Z`
echo $model1
export satellite=viirs
satellite1=`echo ${satellite} | tr a-z A-Z`
export verif_obstype=aod
verif_obstype1=`echo ${verif_obstype} | tr a-z A-Z`

VIIRS_L3_AOD_DIR=/gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/VIIRS_AOD/AOD
if [ ! -d ${VIIRS_L3_AOD_DIR}/${DATE} ]; then
    echo "CVan not find ${VIIRS_L3_AOD_DIR}/${DATE}, PROGRAM STOPX"
    exit
fi
VIIRS_L3_REGRID_AOD_DIR=/gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/VIIRS_${verif_obstype1}/METPLUS_REGRID
if [ ! -d ${VIIRS_L3_REGRID_AOD_DIR}/${model}.${DATE} ]; then mkdir -p ${VIIRS_L3_REGRID_AOD_DIR}/${model}.${DATE}; fi

cd $MET_PLUS_TMP

cd ${MET_PLUS_TMP}
#
# Define high priority venviironment variable used in the METplus
# to overwrite any prior setting in ~/parm/use_cases/perry 
# and /parm/met_config
cat << EOF > user_priority.conf
[config]
#
# For Regrid_data_plane
#
# name of input field to process
# if unset, OBS_VAR1_NAME will be used
OBS_REGRID_DATA_PLANE_VAR1_INPUT_FIELD_NAME = ${verif_obstype1}_H_Quality
# name of output field to create
# if unset, OBS_VAR1_NAME and OBS_VAR1_LEVELS will be combined to generate an output field name
OBS_REGRID_DATA_PLANE_VAR1_OUTPUT_FIELD_NAME = ${verif_obstype1}_H_Quality
# Name to identify model data in output
MODEL = HRRR
# Used by regrid_data_plane to remap data
REGRID_DATA_PLANE_VERIF_GRID =  /gpfs/hps/nco/ops/com/${model}/prod/${model}.{init?fmt=%Y%m%d}/${model}.t06z.aot.f01.148.grib2
#
# For GriD_Stat
#
OBS_VAR1_NAME = ${verif_obstype1}_H_Quality
#GRID_STAT_OUTPUT_PREFIX = {MODEL}_{CURRENT_FCST_NAME}_vs_{OBTYPE}_{CURRENT_OBS_NAME}_{CURRENT_FCST_LEVEL}
GRID_STAT_OUTPUT_PREFIX = ${model1}_AOD_VS_VIIRS_${verif_obstype1}
[dir]
#
# For Regrid_data_plane
#
OUTPUT_BASE = ${MET_PLUS_OUT}
PROJ_DIR = ${MET_PLUS}/output
METPLUS_BASE = ${MET_PLUS}
CONFIG_DIR = ${MET_PLUS_CONF2}
# directory containing observation input to RegridDataPlane
OBS_REGRID_DATA_PLANE_INPUT_DIR = ${VIIRS_L3_AOD_DIR}/

# directory to write observation output from RegridDataPlane
OBS_REGRID_DATA_PLANE_OUTPUT_DIR = ${VIIRS_L3_REGRID_AOD_DIR}/
#
# For GriD_Stat
#
# input and output data directories
FCST_GRID_STAT_INPUT_DIR = /gpfs/hps/nco/ops/com/${model}/prod
OBS_GRID_STAT_INPUT_DIR = ${VIIRS_L3_REGRID_AOD_DIR}
[filename_templates]
#
# For Regrid_data_plane
#
# template to use to read input data and write output data for RegridDataPlane
# if different names for input and output are desired, set OBS_REGRID_DATA_PLANE_INPUT_TEMPLATE
# and OBS_REGRID_DATA_PLANE_OUTPUT_TEMPLATE instead
OBS_REGRID_DATA_PLANE_TEMPLATE = ${model}.{init?fmt=%Y%m%d}/VIIRS-L3-${verif_obstype1}_${model1}_{init?fmt=%Y%m%d}_{init?fmt=%2H}0000.nc
#
# For GriD_Stat
#
# format of filenames
# FCST
FCST_GRID_STAT_INPUT_TEMPLATE = ${model}.{init?fmt=%Y%m%d}/${model}.t{init?fmt=%2H}z.aot.f{lead?fmt=%2H}.grib2

# ANLYS
OBS_GRID_STAT_INPUT_TEMPLATE = ${model}.{da_init?fmt=%Y%m%d}/VIIRS-L3-${verif_obstype1}_${model1}_{da_init?fmt=%Y%m%d}_{da_init?fmt=%2H}0000.nc
EOF

cat << EOF > regrid.conf
[config]
VALID_BEG = ${DATE}00
VALID_END = ${DATE}23
VALID_INCREMENT = 1H
EOF


run_metplus.py -c  ${MET_PLUS_CONF}/regrid_viirs.conf ${MET_PLUS_TMP}/regrid.conf -c ${MET_PLUS_TMP}/user_priority.conf

cp regrid.conf grid_stat.conf

#for level in low medium high
#do

#level1=`echo $level | tr a-z A-Z`

#cat << EOF > level.conf
#[config]
#MODEL = CMAQ${level1}
#GRID_STAT_OUTPUT_PREFIX = CMAQ_AOD_VS_OBS_AOD_${level1}
#[filename_templates]
#OBS_GRID_STAT_INPUT_TEMPLATE = aqm.{da_init?fmt=%Y%m%d}/OBS_AOD_aqm_g16_{da_init?fmt=%Y%m%d}_{da_init?fmt=%2H}_${level}.nc
#EOF

run_metplus.py -c ${MET_PLUS_CONF}/grid_stat_smoke_aod.conf ${MET_PLUS_TMP}/grid_stat.conf -c ${MET_PLUS_TMP}/user_priority.conf

exit

mkdir -p ${MET_PLUS_STD}/stat/${model}
cp ${MET_PLUS_OUT}/cam/stat/${model}/*${DATE}* ${MET_PLUS_STD}/stat/${model}
mv ${MET_PLUS_OUT}/logs/master_metplus.log.${DATEP1} ${MET_PLUS_TMP}/master_metplus.log.${DATEP1}_${model}

cat << EOF > statanalysis.conf
[config]
VALID_BEG = $DATE
VALID_END = $DATE
MODEL = $model
MODEL1 = $model1
EOF

run_metplus.py -c ${MET_PLUS_CONF}/StatAnalysis_gatherByDay_hysplit.conf ${MET_PLUS_TMP}/statanalysis.conf

###mv ${MET_PLUS_OUT}/logs/master_metplus.log.${DATEP1} ${MET_PLUS_TMP}

#cp ${MET_PLUS_CONF}/load_met.xml load_met_${model}.xml

exit

