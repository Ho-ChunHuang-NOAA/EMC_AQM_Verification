#!/bin/bash

#PBS -N metplus_hrrr_aod
#PBS -o /lfs/h2/emc/ptmp/ho-chun.huang/output/metplus_hrrr_aod.o%J
#PBS -e /lfs/h2/emc/ptmp/ho-chun.huang/output/metplus_hrrr_aod.o%J
#PBS -q dev
#PBS -A VERF-DEV
# 
#PBS -l place=shared,select=1:ncpus=1:mem=4500MB
#PBS -l walltime=04:00:00
#PBS -l debug=true

set -x

export cycle=t00z
export utilscript=/apps/ops/prod/nco/core/prod_util.v2.0.13/ush
export utilexec=/apps/ops/prod/nco/core/prod_util.v2.0.13/exec
export EXECutil=/apps/ops/prod/nco/core/prod_util.v2.0.13/exec
export MET_PLUS_TMP=/lfs/h2/emc/ptmp/ho-chun.huang/metplus_hrrr_aod

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

sh $utilscript/setup.sh
sh $utilscript/setpdy.sh
. $MET_PLUS_TMP/PDY

export DATE=$PDYm3
export DATEP1=$PDY
export DATEM1=$PDYm4
export MET_PLUS=/lfs/h2/emc/physics/noscrub/Perry.Shafran/METplus-4.0.0
export MET_PLUS_CONF=/lfs/h2/emc/physics/noscrub/Perry.Shafran/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/lfs/h2/emc/physics/noscrub/Perry.Shafran/metplus_hrrraod
export MET_PLUS_STD=/lfs/h2/emc/ptmp/ho-chun.huang/metplus_hrrr_aod_${DATE}

mkdir -p $MET_PLUS_STD

export model=hrrr
model1=`echo $model | tr a-z A-Z`
echo $model1

mkdir -p /lfs/h2/emc/physics/noscrub/Perry.Shafran/VIIRS_AOD/${DATE}
mkdir -p /lfs/h2/emc/physics/noscrub/Perry.Shafran/VIIRS_AOD_REGRID/${DATE}
cd /lfs/h2/emc/physics/noscrub/Perry.Shafran/VIIRS_AOD/${DATE}

ftp -n <<EOF
verbose
open ftp.star.nesdis.noaa.gov
user anonymous perry.shafran@noaa.gov
bi
prompt

cd /pub/smcd/VIIRS_Aerosol/Hongqing/VIIRS_L3_AQM/$DATE
mget VIIRS-L3-AOD_AQM_${DATE}*.nc
cd /pub/smcd/VIIRS_Aerosol/Hongqing/VIIRS_L3_AQM/$DATEM1
mget VIIRS-L3-AOD_AQM_${DATE}*.nc

close
EOF

cd $MET_PLUS_TMP

cat << EOF > regrid.conf
[config]
VALID_BEG = ${DATE}00
VALID_END = ${DATE}23
VALID_INCREMENT = 1H
EOF


run_metplus.py -c  ${MET_PLUS_CONF}/regrid_viirs.conf ${MET_PLUS_TMP}/regrid.conf

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

run_metplus.py -c ${MET_PLUS_CONF}/grid_stat_smoke_aod.conf ${MET_PLUS_TMP}/grid_stat.conf 

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

