#PBS -N metplus_cmaq_aod_viirs
#PBS -j oe
#PBS -o /lfs/h2/emc/ptmp/perry.shafran/output/metplus_cmaq_aod_viirs.out
#PBS -e /lfs/h2/emc/ptmp/perry.shafran/output/metplus_cmaq_aod_viirs.out
#PBS -q "dev"
#PBS -A VERF-DEV
#PBS -S /bin/bash
#PBS -l select=1:ncpus=1:mem=3000MB
#PBS -l walltime=02:00:00
#PBS -l debug=true

set -x

export cycle=t00z
export MET_PLUS_TMP=/lfs/h2/emc/ptmp/perry.shafran/metplus_cmaq_aod

module purge
export HPC_OPT=/apps/ops/prod/libs
module use /apps/ops/prod/libs/modulefiles/compiler/intel/19.1.3.304/
module load intel
module load gsl
module load python/3.8.6
module load netcdf/4.7.4
module load met/10.0.1
module load metplus/4.0.0

module load prod_util/2.0.13
module load prod_envir/2.0.6

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

sh setpdy.sh
. $MET_PLUS_TMP/PDY

export DATE=$PDYm3
export DATEP1=$PDY
export MET_PLUS_CONF=/lfs/h2/emc/vpppg/save/perry.shafran/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/lfs/h2/emc/vpppg/noscrub/perry.shafran/metplus_cmaqaod
export MET_PLUS_STD=/lfs/h2/emc/ptmp/perry.shafran/metplus_cmaq_aod_${DATE}

mkdir -p $MET_PLUS_STD

export model=cmaq
model1=`echo $model | tr a-z A-Z`
echo $model1

mkdir -p /lfs/h2/emc/vpppg/noscrub/perry.shafran/VIIRS_AOD_CMAQ_REGRID/${DATE}

cat << EOF > regrid.conf
[config]
VALID_BEG = ${DATE}00
VALID_END = ${DATE}23
VALID_INCREMENT = 1H
EOF

run_metplus.py -c  ${MET_PLUS_CONF}/regrid_viirs_cmaq.conf ${MET_PLUS_TMP}/regrid.conf

cp regrid.conf grid_stat.conf

run_metplus.py -c ${MET_PLUS_CONF}/grid_stat_cmaq_viirs_aod.conf ${MET_PLUS_TMP}/grid_stat.conf 

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

