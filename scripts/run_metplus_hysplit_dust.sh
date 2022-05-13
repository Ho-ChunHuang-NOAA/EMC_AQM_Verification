#!/bin/bash

#BSUB -J metplus_hysplit_dust
#BSUB -o /gpfs/dell2/ptmp/Perry.Shafran/output/metplus_hysplit_dust.o%J
#BSUB -e /gpfs/dell2/ptmp/Perry.Shafran/output/metplus_hysplit_dust.o%J
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
export MET_PLUS_TMP=/gpfs/dell2/ptmp/Perry.Shafran/metplus_hysplit_dust

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

sh $utilscript/setup.sh
sh $utilscript/setpdy.sh
. $MET_PLUS_TMP/PDY

export DATE=$PDYm2
export DATEP1=$PDY
export MET_PLUS=/gpfs/dell2/emc/verification/save/Perry.Shafran/METplus-4.0.0
export MET_PLUS_CONF=/gpfs/dell2/emc/verification/save/Perry.Shafran/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/gpfs/dell2/emc/verification/noscrub/Perry.Shafran/metplus_hysplit
export MET_PLUS_STD=/gpfs/dell2/ptmp/Perry.Shafran/metplus_hysplit_dust_${DATE}

mkdir -p $MET_PLUS_STD

export model=hysplit
model1=`echo $model | tr a-z A-Z`
echo $model1

mkdir -p  /gpfs/dell2/ptmp/Perry.Shafran/com/hysplit/prod/dustcs.${DATE}

for cyc in 06 12
do
for fhr in 1 2 3 4 5 6 7 8 9
do

wgrib2 -d ${fhr} /gpfs/dell1/nco/ops/com/hysplit/prod/dustcs.${DATE}/dustcs.t${cyc}z.pbl.1hr.grib2 -set_ftime "${fhr} hour fcst" -grib /gpfs/dell2/ptmp/Perry.Shafran/com/hysplit/prod/dustcs.${DATE}/dustcs.t${cyc}z.pbl.f0${fhr}.grib2

done

for fhr in 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48
do

wgrib2 -d ${fhr} /gpfs/dell1/nco/ops/com/hysplit/prod/dustcs.${DATE}/dustcs.t${cyc}z.pbl.1hr.grib2 -set_ftime "${fhr} hour fcst" -grib /gpfs/dell2/ptmp/Perry.Shafran/com/hysplit/prod/dustcs.${DATE}/dustcs.t${cyc}z.pbl.f${fhr}.grib2

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

