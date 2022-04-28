#!/bin/bash

#BSUB -J metplus_nam
#BSUB -o /gpfs/dell2/ptmp/Ho-Chun.Huang/VERF_logs/nam_v161a_20190828.ps.log
#BSUB -e /gpfs/dell2/ptmp/Ho-Chun.Huang/VERF_logs/nam_v161a_20190828.ps.log
#BSUB -q "dev2"
#BSUB -P VERF-T2O
#BSUB -R "rusage[mem=3000]"
#BSUB -n 1
#BSUB -W 04:00
###BSUB -R affinity[core(1)]

module use /gpfs/dell2/emc/verification/noscrub/emc.metplus/modulefiles
module load met/10.0.1
module load metplus/4.0.0
module load python/3.6.3
module load NetCDF/4.5.0

#
# This template is for multiple days point-stat verification.  Mainly for restrospective
# StatAnalysis can be run after all Point_Stat are finsihed for each days. Otherwise, 00z staistic may be missing.
#
## envir=xxENVIR
envir=v161a
envir1=`echo ${envir} | tr a-z A-Z`
echo "experiment run is ${envir} ${envir1}"

set -x
TODAY=`date +%Y%m%d`

export cycle=t00z
export utilscript=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/ush
export utilexec=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec
export EXECutil=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec
export MET_PLUS_TMP=/gpfs/dell2/ptmp/${USER}/metplus_nam

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

## sh $utilscript/setup.sh
## sh $utilscript/setpdy.sh
## . $MET_PLUS_TMP/PDY

export DATE=20190802
export MET_PLUS=/gpfs/dell2/emc/verification/save/${USER}/METplus-4.0.0
export MET_PLUS_CONF=/gpfs/dell2/emc/verification/save/${USER}/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/gpfs/dell2/emc/verification/noscrub/${USER}/metplus_cam
export MET_PLUS_STD=/gpfs/dell2/ptmp/${USER}/metplus_nam_${DATE}

mkdir -p $MET_PLUS_STD

export model=${envir}
export model=nam
model1=`echo $model | tr a-z A-Z`
echo $model1

#
# Define high priority enviironment variable used in the METplus
# to overwrite any prior setting in ~/parm/use_cases/perry
# and /parm/met_config
cat << EOF > user_priority.conf
[config]
PB2NC_SKIP_IF_OUTPUT_EXISTS=true
[dir]
OUTPUT_BASE = ${MET_PLUS_OUT}
PROJ_DIR = ${MET_PLUS}/output
METPLUS_BASE = ${MET_PLUS}
## CONFIG_DIR = ${MET_PLUS_CONF2}
EOF

cat << EOF > shared_${model}.conf
[config]
VALID_BEG = ${DATE}00
VALID_END = ${DATE}23
EOF

#
# Inline-CMAQ natlev fcst_var = "SPFH" (2m/10m[kg/kg]), "TMP"(2m[K]), "HGT"(sfc), "UGRD"(10m), "VGRD"(10m), "RH" (2m[%]), "CAPE" (sfc[J/kg]), "HPBL" (sfc[m]),
#                           "PRMSL"(MSL[Pa]), "DPT"(2m[K}), "PWO", "TCDC"(hybrid level[%]), "VIS"(sfc[m]), "CEILING", "GUST"i(sfc[m/s])
# 
# PB2NC sample :  obs_var = "SPFH"[KG/KG], "TMP"[K], "HGT"[m], "UGRD"[m/s], "VGRD"[m/s], "RH", "CAPE", "PBL",
#                           "PRMSL"[PA], "DPT"[K], "PWO"[KG/M**2or mm], "TCDC"[%], "VIS"[m], "CEILING"[m], "GUST"[m/s] 
# PWO : TOTAL PRECIPITABLE WATER
# CELING : HGT OF CLOUD BASE
#
# Switch to use prolevf because the pb2nc and point_stat both look for pressure quantities
# BOTH_VAR1_LEVELS = Z2, P1000, P925, P850, P700, P500, P400, P300, P250, P200, P150, P100, P50
#
## FCST_POINT_STAT_INPUT_DIR = /gpfs/dell1/nco/ops/com/nam/prod
## MODEL = ${model1}
## OBS_POINT_STAT_INPUT_TEMPLATE = prepbufr.nam.{valid?fmt=%Y%m%d%H}.nc
cat << EOF > ${model}.conf
[dir]
FCST_POINT_STAT_INPUT_DIR = /gpfs/dell2/emc/modeling/noscrub/${USER}/verification/RRFS-CMAQ/${envir}
OBS_POINT_STAT_INPUT_DIR = {OUTPUT_BASE}/cam/conus_cam
PB2NC_INPUT_DIR = /gpfs/dell2/emc/modeling/noscrub/${USER}/verification/com/nam/prod
[config]
METPLUS_CONF = {OUTPUT_BASE}/conf/${model}/metplus_final_pb2nc_pointstat.conf
LEAD_SEQ = begin_end_incr(0,72,1)
BOTH_VAR8_OPTIONS = GRIB_lvl_typ = 1; censor_thresh = gt16090; censor_val = 16090; desc = "EMC";
FCST_VAR16_NAME = VIS
FCST_VAR16_LEVELS = L0
FCST_VAR16_THRESH =  <805, <1609, <4828, <8045 ,>=8045, <16090
FCST_VAR16_OPTIONS = GRIB_lvl_typ = 3; desc = "GSL"; censor_thresh = gt16090; censor_val = 16090;
OBS_VAR16_NAME = VIS
OBS_VAR16_LEVELS = L0
OBS_VAR16_THRESH =  <805, <1609, <4828, <8045 ,>=8045, <16090
OBS_VAR16_OPTIONS = censor_thresh = gt16090; censor_val = 16090; desc = "GSL";
MODEL = namretro
[filename_templates]
FCST_POINT_STAT_INPUT_TEMPLATE = aqm.{init?fmt=%Y%m%d}/postprd/rrfs.t{init?fmt=%2H}z.natlevf{lead?fmt=%3H}.tm00.grib2
PB2NC_INPUT_TEMPLATE =  nam.{da_init?fmt=%Y%m%d}/nam.t{cycle?fmt=%2H}z.prepbufr.tm{offset?fmt=%2H}.nr
POINT_STAT_OUTPUT_TEMPLATE = ${model}
EOF

#model1=`echo $model | tr a-z A-Z`
#echo $model1

${MET_PLUS}/ush/run_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_cam.conf -c ${MET_PLUS_CONF}/point_stat_cam.conf -c ${MET_PLUS_TMP}/${model}.conf -c ${MET_PLUS_CONF}/shared.conf -c ${MET_PLUS_TMP}/shared_${model}.conf -c ${MET_PLUS_CONF}/system_cam.conf -c ${MET_PLUS_TMP}/user_priority.conf

mkdir -p ${MET_PLUS_STD}/stat/${model}
cp ${MET_PLUS_OUT}/cam/stat/${model}/*${TODAY}* ${MET_PLUS_STD}/stat/${model}
mv ${MET_PLUS_OUT}/logs/master_metplus.log.${TODAY} ${MET_PLUS_TMP}/master_metplus.log.${TODAY}_${model}

cat << EOF > statanalysis.conf
[config]
VALID_BEG = $DATE
VALID_END = $DATE
MODEL = $model
MODEL1 = $model1
EOF

# ${MET_PLUS}/ush/run_metplus.py -c ${MET_PLUS_CONF}/system_cam.conf -c ${MET_PLUS_CONF}/StatAnalysis_gatherByDay.conf -c ${MET_PLUS_TMP}/statanalysis.conf -c ${MET_PLUS_TMP}/user_priority.conf


exit
