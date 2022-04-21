#!/bin/bash

#BSUB -J metplus_namretro
#BSUB -o /gpfs/dell2/ptmp/Perry.Shafran/output/metplus_namretro.o%J
#BSUB -e /gpfs/dell2/ptmp/Perry.Shafran/output/metplus_namretro.o%J
#BSUB -q "dev2"
#BSUB -P VERF-T2O
#BSUB -R "rusage[mem=3000]"
#BSUB -n 1
#BSUB -W 04:00

set -x

STARTDATE=2019081800
ENDDATE=2019081900
DATE=$STARTDATE

###cd /ptmp/wx20ps/temp

while [ $DATE -le $ENDDATE ]; do

echo $DATE > curdate
DAY=`cut -c 1-8 curdate`
YEAR=`cut -c 1-4 curdate`
MONTH=`cut -c 1-6 curdate`

echo $DATEM1 > curdate2
DAYM1=`cut -c 1-8 curdate2`
YEARM1=`cut -c 1-4 curdate2`
MONTHM1=`cut -c 1-6 curdate2`

export cycle=t00z
export utilscript=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/ush
export utilexec=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec
export EXECutil=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec
export MET_PLUS_TMP=/gpfs/dell2/ptmp/Perry.Shafran/metplus_namretro

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

#sh $utilscript/setup.sh
#sh $utilscript/setpdy.sh
#. $MET_PLUS_TMP/PDY

#export DATE=$PDYm1
#export DATEP1=$PDY
export MET_PLUS=/gpfs/dell2/emc/verification/save/Perry.Shafran/METplus-4.0.0
export MET_PLUS_CONF=/gpfs/dell2/emc/verification/save/Perry.Shafran/METplus-4.0.0/parm/use_cases/perry
export MET_PLUS_OUT=/gpfs/dell2/emc/verification/noscrub/Perry.Shafran/metplus_cam
export MET_PLUS_STD=/gpfs/dell2/ptmp/Perry.Shafran/metplus_namretro_${DATE}

mkdir -p $MET_PLUS_STD

export model=nam
model1=`echo $model | tr a-z A-Z`
echo $model1

cat << EOF > shared_${model}.conf
[config]
VALID_BEG = ${DAY}00
VALID_END = ${DAY}23
EOF

cat << EOF > ${model}.conf
[dir]
FCST_POINT_STAT_INPUT_DIR = /gpfs/dell2/emc/verification/noscrub/Perry.Shafran/com/nam/prod
OBS_POINT_STAT_INPUT_DIR = {OUTPUT_BASE}/cam/conus_cam
PB2NC_INPUT_DIR = /gpfs/dell2/emc/verification/noscrub/Perry.Shafran/com/nam/prod
[config]
METPLUS_CONF = {OUTPUT_BASE}/conf/${model}/metplus_final_pb2nc_pointstat.conf
LEAD_SEQ = begin_end_incr(0,84,1)
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
FCST_POINT_STAT_INPUT_TEMPLATE = nam.{init?fmt=%Y%m%d}/nam.t{init?fmt=%2H}z.awphys{lead?fmt=%2H}.tm00.grib2
PB2NC_INPUT_TEMPLATE =  nam.{da_init?fmt=%Y%m%d}/nam.t{cycle?fmt=%2H}z.prepbufr.tm{offset?fmt=%2H}.nr
POINT_STAT_OUTPUT_TEMPLATE = ${model}
EOF

#model1=`echo $model | tr a-z A-Z`
#echo $model1

${MET_PLUS}/ush/run_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_cam.conf -c ${MET_PLUS_CONF}/point_stat_cam.conf -c ${MET_PLUS_TMP}/${model}.conf -c ${MET_PLUS_CONF}/shared.conf -c ${MET_PLUS_TMP}/shared_${model}.conf -c ${MET_PLUS_CONF}/system_cam.conf 

mkdir -p ${MET_PLUS_STD}/stat/${model}
cp ${MET_PLUS_OUT}/cam/stat/${model}/*${DATE}* ${MET_PLUS_STD}/stat/${model}
mv ${MET_PLUS_OUT}/logs/master_metplus.log.${DATE} ${MET_PLUS_TMP}/master_metplus.log.${DATE}_${model}

cat << EOF > statanalysis.conf
[config]
VALID_BEG = $DATE
VALID_END = $DATE
MODEL = $model
MODEL1 = $model1
EOF

${MET_PLUS}/ush/run_metplus.py -c ${MET_PLUS_CONF}/system_cam.conf ${MET_PLUS_CONF}/StatAnalysis_gatherByDay.conf ${MET_PLUS_TMP}/statanalysis.conf

###mv ${MET_PLUS_OUT}/logs/master_metplus.log.${DATEP1} ${MET_PLUS_TMP}

#cp ${MET_PLUS_CONF}/load_met.xml load_met_${model}.xml

DATE=`/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.2/exec/ips/ndate +24 $DATE`

done

exit

cat << EOF > load_met_${model}.xml
<load_spec>
  <connection>
    <host>metviewer-dev-cluster.cluster-czbts4gd2wm2.us-east-1.rds.amazonaws.com:3306</host>
    <database>mv_meso_grid2obs_2021_metplus</database>
    <user>rds_user</user>
    <password>rds_pwd</password>
    <management_system>aurora</management_system>
  </connection>

  <met_version>V6.1</met_version>

  <verbose>true</verbose>
  <insert_size>1</insert_size>
  <mode_header_db_check>true</mode_header_db_check>
  <stat_header_db_check>true</stat_header_db_check>
  <drop_indexes>false</drop_indexes>
  <apply_indexes>true</apply_indexes>
  <load_stat>true</load_stat>
  <load_mode>true</load_mode>
  <load_mpr>true</load_mpr>
  <load_orank>true</load_orank>
  <force_dup_file>true</force_dup_file>
  <group>EMC Regional CAM</group>
  <description>Regional Meso METplus data</description>
 <folder_tmpl>/base_dir/{model}</folder_tmpl>
  <load_val>
    <field name="model">
      <val>${model}</val>
    </field>
  </load_val>


  <load_xml>true</load_xml>
</load_spec>
EOF

/gpfs/dell2/emc/verification/save/Perry.Shafran/aws/mv_load_to_aws.sh perry.shafran ${MET_PLUS_TMP}/stat/ ${MET_PLUS_TMP}/load_met_nam.xml

cp /gpfs/dell2/ptmp/Perry.Shafran/output/metplus_nam.out $MET_PLUS_STD/metplus_nam_$DATE.out

exit