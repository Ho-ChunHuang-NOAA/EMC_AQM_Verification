#PBS -N metplus_hysplit_dust
#PBS -j oe
#PBS -o /lfs/h2/emc/ptmp/perry.shafran/output/metplus_hysplit_dust.out
#PBS -e /lfs/h2/emc/ptmp/perry.shafran/output/metplus_hysplit_dust.out
#PBS -q "dev"
#PBS -A VERF-DEV
#PBS -S /bin/bash
#PBS -l select=1:ncpus=1:mem=3000MB
#PBS -l walltime=01:00:00
#PBS -l debug=true

set -x

export cycle=t00z
export MET_PLUS_TMP=/lfs/h2/emc/ptmp/perry.shafran/metplus_hysplit_dust

module purge
export HPC_OPT=/apps/ops/prod/libs
module use /apps/ops/prod/libs/modulefiles/compiler/intel/19.1.3.304/
module load intel
module load gsl
module load python/3.8.6
module load netcdf/4.7.4
module load met/10.1.2
module load metplus/4.1.4

module load prod_util/2.0.13
module load prod_envir/2.0.6
module load wgrib2

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

sh setpdy.sh
. $MET_PLUS_TMP/PDY

export DATE=$PDYm2
export DATEP1=$PDY
export MET_PLUS_CONF=/lfs/h2/emc/vpppg/save/perry.shafran/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/lfs/h2/emc/vpppg/noscrub/perry.shafran/metplus_hysplit
export MET_PLUS_STD=/lfs/h2/emc/ptmp/perry.shafran/metplus_hysplit_dust_${DATE}

mkdir -p $MET_PLUS_STD

export model=hysplit
model1=`echo $model | tr a-z A-Z`
echo $model1

mkdir -p  /lfs/h2/emc/ptmp/perry.shafran/com/hysplit/prod/dustcs.${DATE}

for cyc in 06 12
do
for fhr in 1 2 3 4 5 6 7 8 9
do

wgrib2 -d ${fhr} /lfs/h1/ops/prod/com/hysplit/v7.9/dustcs.${DATE}/dustcs.t${cyc}z.pbl.1hr.grib2 -set_ftime "${fhr} hour fcst" -grib /lfs/h2/emc/ptmp/perry.shafran/com/hysplit/prod/dustcs.${DATE}/dustcs.t${cyc}z.pbl.f0${fhr}.grib2

done

for fhr in 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48
do

wgrib2 -d ${fhr} /lfs/h1/ops/prod/com/hysplit/v7.9/dustcs.${DATE}/dustcs.t${cyc}z.pbl.1hr.grib2 -set_ftime "${fhr} hour fcst" -grib /lfs/h2/emc/ptmp/perry.shafran/com/hysplit/prod/dustcs.${DATE}/dustcs.t${cyc}z.pbl.f${fhr}.grib2

done

done

cat << EOF > grid_stat.conf
[config]
VALID_BEG = ${DATE}00
VALID_END = ${DATE}23
EOF

run_metplus.py -c ${MET_PLUS_CONF}/grid_stat_hysplit.conf ${MET_PLUS_TMP}/grid_stat.conf

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

