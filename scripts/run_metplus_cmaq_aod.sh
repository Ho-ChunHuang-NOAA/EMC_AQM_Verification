#!/bin/bash

#BSUB -J metplus_cmaq_aod
#BSUB -o /gpfs/dell2/ptmp/Perry.Shafran/output/metplus_cmaq_aod.o%J
#BSUB -e /gpfs/dell2/ptmp/Perry.Shafran/output/metplus_cmaq_aod.o%J
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
export MET_PLUS_TMP=/gpfs/dell2/ptmp/Perry.Shafran/metplus_cmaq_aod

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

sh $utilscript/setup.sh
sh $utilscript/setpdy.sh
. $MET_PLUS_TMP/PDY

export DATE=$PDYm3
export DATEP1=$PDY
export MET_PLUS=/gpfs/dell2/emc/verification/save/Perry.Shafran/METplus-4.0.0
export MET_PLUS_CONF=/gpfs/dell2/emc/verification/save/Perry.Shafran/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/gpfs/dell2/emc/verification/noscrub/Perry.Shafran/metplus_cmaqaod
export MET_PLUS_STD=/gpfs/dell2/ptmp/Perry.Shafran/metplus_cmaq_aod_${DATE}

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

