#!/bin/bash

#PBS -N metplus_cmaq_aod
#PBS -o /lfs/h2/emc/ptmp/ho-chun.huang/output/metplus_cmaq_aod.o%J
#PBS -e /lfs/h2/emc/ptmp/ho-chun.huang/output/metplus_cmaq_aod.o%J
#PBS -q dev
#PBS -A VERF-DEV
# 
#PBS -l place=shared,select=1:ncpus=1:mem=4GB
#PBS -l walltime=04:00:00
#PBS -l debug=true

set -x

export cycle=t00z
export utilscript=/apps/ops/prod/nco/core/prod_util.v2.0.13/ush
export utilexec=/apps/ops/prod/nco/core/prod_util.v2.0.13/exec
export EXECutil=/apps/ops/prod/nco/core/prod_util.v2.0.13/exec
export MET_PLUS_TMP=/lfs/h2/emc/ptmp/ho-chun.huang/metplus_cmaq_aod

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

sh $utilscript/setup.sh
sh $utilscript/setpdy.sh
. $MET_PLUS_TMP/PDY

export DATE=$PDYm3
export DATEP1=$PDY
export MET_PLUS=/lfs/h2/emc/physics/noscrub/Perry.Shafran/METplus-4.0.0
export MET_PLUS_CONF=/lfs/h2/emc/physics/noscrub/Perry.Shafran/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/lfs/h2/emc/physics/noscrub/Perry.Shafran/metplus_cmaqaod
export MET_PLUS_STD=/lfs/h2/emc/ptmp/ho-chun.huang/metplus_cmaq_aod_${DATE}

mkdir -p $MET_PLUS_STD

export model=cmaq
model1=`echo $model | tr a-z A-Z`
echo $model1


cat << EOF > grid_stat.conf
[config]
VALID_BEG = ${DATE}00
VALID_END = ${DATE}23
EOF

for level in low medium high
do

level1=`echo $level | tr a-z A-Z`

cat << EOF > level.conf
[config]
MODEL = CMAQ${level1}
GRID_STAT_OUTPUT_PREFIX = CMAQ_AOD_VS_OBS_AOD_${level1}
[filename_templates]
OBS_GRID_STAT_INPUT_TEMPLATE = aqm.{da_init?fmt=%Y%m%d}/OBS_AOD_aqm_g16_{da_init?fmt=%Y%m%d}_{da_init?fmt=%2H}_${level}.nc
EOF

run_metplus.py -c ${MET_PLUS_CONF}/grid_stat_cmaq_aod.conf ${MET_PLUS_TMP}/grid_stat.conf ${MET_PLUS_TMP}/level.conf

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

done

###mv ${MET_PLUS_OUT}/logs/master_metplus.log.${DATEP1} ${MET_PLUS_TMP}

#cp ${MET_PLUS_CONF}/load_met.xml load_met_${model}.xml

exit

