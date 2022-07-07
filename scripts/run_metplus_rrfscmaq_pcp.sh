#!/bin/bash

#PBS -N metplus_pcp_fv3lam
#PBS -o /lfs/h2/emc/ptmp/${USER}/output/metplus_pcp_fv3lam.out
#PBS -e /lfs/h2/emc/ptmp/${USER}/output/metplus_pcp_fv3lam.out
#PBS -q dev
#PBS -A VERF-DEV
# 
#PBS -l place=shared,select=1:ncpus=1:mem=4GB
#PBS -l walltime=12:00:00
#PBS -l debug=true

set -x

STARTDATE=2019080100
ENDDATE=2019090100
DATE=$STARTDATE

export cycle=t00z
export utilscript=/apps/ops/prod/nco/core/prod_util.v2.0.13/ush
export utilexec=/apps/ops/prod/nco/core/prod_util.v2.0.13/exec
export EXECutil=/apps/ops/prod/nco/core/prod_util.v2.0.13/exec
export temp=/lfs/h2/emc/ptmp/${USER}/rrfscmaq_date

rm -f -r $temp
mkdir -p $temp
cd $temp

while [ $DATE -le $ENDDATE ]; do

DATEP1=`/apps/ops/prod/nco/core/prod_util.v2.0.13/exec/ndate +24 $DATE`
DATEP2=`/apps/ops/prod/nco/core/prod_util.v2.0.13/exec/ndate +24 $DATEP1`
DATEM1=`/apps/ops/prod/nco/core/prod_util.v2.0.13/exec/ndate -24 $DATE`
DATEM2=`/apps/ops/prod/nco/core/prod_util.v2.0.13/exec/ndate -24 $DATEM1`
DATEM3=`/apps/ops/prod/nco/core/prod_util.v2.0.13/exec/ndate -24 $DATEM2`
DATEM4=`/apps/ops/prod/nco/core/prod_util.v2.0.13/exec/ndate -24 $DATEM3`
DATEM5=`/apps/ops/prod/nco/core/prod_util.v2.0.13/exec/ndate -24 $DATEM4`

#sh $utilscript/setup.sh
#sh $utilscript/setpdy.sh
#. $temp/PDY

#export DATE=$PDYm2
#export DATEP1=$PDY

export MET_PLUS_TMP=/lfs/h2/emc/ptmp/${USER}/metplus_pcp_rrfscmaq_$DATE

rm -f -r $MET_PLUS_TMP
mkdir -p $MET_PLUS_TMP
cd $MET_PLUS_TMP

#sh $utilscript/setup.sh
#sh $utilscript/setpdy.sh
#. $MET_PLUS_TMP/PDY

echo $DATE > curdate1
DAY=`cut -c 1-8 curdate1`

echo $DATEM1 > curdate2
DAYM1=`cut -c 1-8 curdate2`

echo $DATEM2 > curdate3
DAYM2=`cut -c 1-8 curdate3`

echo $DATEM3 > curdate4
DAYM3=`cut -c 1-8 curdate4`

echo $DATEM4 > curdate5
DAYM4=`cut -c 1-8 curdate5`

echo $DATEM5 > curdate6
DAYM5=`cut -c 1-8 curdate6`

echo $DATEP1 > curdate7
DAYP1=`cut -c 1-8 curdate7`

echo $DATEP2 > curdate8
DAYP2=`cut -c 1-8 curdate8`

export DAY

PDY=$DAYP2
PDYm1=$DAYP1
PDYm2=$DAY
PDYm3=$DAYM1
PDYm4=$DAYM2
PDYm5=$DAYM3

#export DATE=$PDYm2
#export DATEP1=$PDY

export MET_PLUS=/lfs/h2/emc/physics/noscrub/${USER}/METplus-3.1
export MET_PLUS_CONF=/lfs/h2/emc/physics/noscrub/${USER}/METplus-3.1/parm/use_cases/precip
export MET_PLUS_OUT=/lfs/h2/emc/physics/noscrub/${USER}/metplus_pcp
export MET_PLUS_STD=/lfs/h2/emc/ptmp/${USER}/metplus_pcp_rrfscmaq_$DATE

mkdir -p $MET_PLUS_STD

export model=rrfscmaqv143b
model1=`echo $model | tr a-z A-Z`
echo $model1

export model_dir=/lfs/h2/emc/ptmp/ho-chun.huang/data/RRFSCMAQ/v143_b
export EXPTDIR=/lfs/h2/emc/physics/noscrub/${USER}/metplus_pcp
export OBS_DIR=/lfs/h2/emc/ptmp/${USER}/ccpa
export acc=6hr
export fhr_list="begin_end_incr(0,48,6)"
export CDATE=${DATE}00

export METPLUS_PATH=${MET_PLUS}
export MET_INSTALL_DIR=/lfs/h2/emc/physics/noscrub/emc.metplus/met/9.1
export METPLUS_CONF=/lfs/h2/emc/physics/noscrub/${USER}/METplus-3.1/parm
export MET_CONFIG=/lfs/h2/emc/physics/noscrub/${USER}/METplus-3.1/parm/met_config

mkdir -p /lfs/h2/emc/ptmp/${USER}/ccpa/ccpa.$PDYm2

cp /lfs/h2/emc/physics/noscrub/${USER}/com/ccpa/prod/ccpa.$PDYm3/00/ccpa.*.06h.hrap.conus.gb2 /lfs/h2/emc/ptmp/ho-chun.huang/ccpa/ccpa.$PDYm3
cp /lfs/h2/emc/physics/noscrub/${USER}/com/ccpa/prod/ccpa.$PDYm3/06/ccpa.*.06h.hrap.conus.gb2 /lfs/h2/emc/ptmp/ho-chun.huang/ccpa/ccpa.$PDYm3
cp /lfs/h2/emc/physics/noscrub/${USER}/com/ccpa/prod/ccpa.$PDYm3/12/ccpa.*.06h.hrap.conus.gb2 /lfs/h2/emc/ptmp/ho-chun.huang/ccpa/ccpa.$PDYm3
cp /lfs/h2/emc/physics/noscrub/${USER}/com/ccpa/prod/ccpa.$PDYm3/18/ccpa.*.06h.hrap.conus.gb2 /lfs/h2/emc/ptmp/ho-chun.huang/ccpa/ccpa.$PDYm3
cp /lfs/h2/emc/physics/noscrub/${USER}/com/ccpa/prod/ccpa.$PDYm4/00/ccpa.t00z.06h.hrap.conus.gb2 /lfs/h2/emc/ptmp/ho-chun.huang/ccpa/ccpa.$PDYm3

cp /lfs/h2/emc/physics/noscrub/${USER}/com/ccpa/prod/ccpa.$PDYm2/00/ccpa.*.06h.hrap.conus.gb2 /lfs/h2/emc/ptmp/ho-chun.huang/ccpa/ccpa.$PDYm2
cp /lfs/h2/emc/physics/noscrub/${USER}/com/ccpa/prod/ccpa.$PDYm2/06/ccpa.*.06h.hrap.conus.gb2 /lfs/h2/emc/ptmp/ho-chun.huang/ccpa/ccpa.$PDYm2
cp /lfs/h2/emc/physics/noscrub/${USER}/com/ccpa/prod/ccpa.$PDYm2/12/ccpa.*.06h.hrap.conus.gb2 /lfs/h2/emc/ptmp/ho-chun.huang/ccpa/ccpa.$PDYm2
cp /lfs/h2/emc/physics/noscrub/${USER}/com/ccpa/prod/ccpa.$PDYm2/18/ccpa.*.06h.hrap.conus.gb2 /lfs/h2/emc/ptmp/ho-chun.huang/ccpa/ccpa.$PDYm2
cp /lfs/h2/emc/physics/noscrub/${USER}/com/ccpa/prod/ccpa.$PDYm3/00/ccpa.t00z.06h.hrap.conus.gb2 /lfs/h2/emc/ptmp/ho-chun.huang/ccpa/ccpa.$PDYm2

cat << EOF > ${model}.conf
[config]
METPLUS_CONF = {OUTPUT_BASE}/conf/${model}/metplus_final_gridstat.conf
MODEL = ${model1}
VALID_BEG = {ENV[DAY]}00
VALID_END = {ENV[DAY]}23
LEAD_SEQ = begin_end_incr(0,30,6)
VALID_INCREMENT = 6H
[filename_templates]
FCST_GRID_STAT_INPUT_TEMPLATE = {init?fmt=%Y%m%d%H}/postprd/rrfs.t{init?fmt=%2H}z.natlevf{lead?fmt=%3H}.tm00.grib2
GRID_STAT_OUTPUT_TEMPLATE = grid_stat/${model}
EOF

cat << EOF > ${model}_pcpcombine.conf
[config]
METPLUS_CONF = {OUTPUT_BASE}/conf/${model}/metplus_final_pcpcombine_{ENV[acc]}_gridstat.conf
MODEL = ${model1}
LEAD_SEQ = begin_end_incr(0,30,6)
VALID_INCREMENT = 6H
[filename_templates]
FCST_PCP_COMBINE_INPUT_TEMPLATE = {init?fmt=%Y%m%d%H}/postprd/rrfs.t{init?fmt=%2H}z.natlevf{lead?fmt=%3H}.tm00.grib2
FCST_PCP_COMBINE_OUTPUT_TEMPLATE = ${DATE}/rrfscmaq.t{init?fmt=%H}z.conus.f{lead?fmt=%HH}.a{level?fmt=%HH}h
GRID_STAT_OUTPUT_TEMPLATE = grid_stat/${model}
EOF


#${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS_CONF}/common.conf -c ${MET_PLUS_CONF}/APCP_01h.conf -c ${model}.conf
${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS_CONF}/common.conf -c ${MET_PLUS_CONF}/APCP_06h_6hccpa.conf -c ${model}.conf

#export acc=3hr
#${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS_CONF}/common.conf -c ${MET_PLUS_CONF}/APCP_03h.conf -c ${model}_pcpcombine.conf

#export acc=6hr
#${MET_PLUS}/ush/run_metplus.py -c ${MET_PLUS_CONF}/common.conf -c ${MET_PLUS_CONF}/APCP_06h.conf_6hCCPA -c ${model}_pcpcombine.conf

#export acc=24hr
#${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS_CONF}/common.conf -c ${MET_PLUS_CONF}/APCP_24h.conf -c ${model}_pcpcombine.conf


#${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS}/parm/use_cases/grid_to_obs/grid_to_obs.conf -c ${MET_PLUS}/parm/use_cases/grid_to_obs/examples/conus_surface.conf -c ${MET_PLUS_CONF}/pb2nc_cam.conf -c ${MET_PLUS_CONF}/point_stat_cam.conf -c ${MET_PLUS_TMP}/${model}.conf -c ${MET_PLUS_CONF}/shared.conf -c ${MET_PLUS_TMP}/shared_${model}.conf -c ${MET_PLUS_CONF}/system_cam.conf 

mkdir -p ${MET_PLUS_TMP}/stat/${model}
cp ${MET_PLUS_OUT}/grid_stat/${model}/*${DATE}* ${MET_PLUS_TMP}/stat/${model}
mv ${MET_PLUS_OUT}/logs/master_metplus.log.${DATEP1} ${MET_PLUS_TMP}/master_metplus.log.${DATEP1}_${model}

#cat << EOF > statanalysis.conf
#[config]
#VALID_BEG = $DATE
#VALID_END = $DATE
#MODEL = $model
#MODEL1 = $model1
#EOF

#${MET_PLUS}/ush/master_metplus.py -c ${MET_PLUS_CONF}/system_cam.conf ${MET_PLUS_CONF}/StatAnalysis_gatherByHour.conf ${MET_PLUS_TMP}/statanalysis.conf

###mv ${MET_PLUS_OUT}/logs/master_metplus.log.${DATEP1} ${MET_PLUS_TMP}

#cp ${MET_PLUS_CONF}/load_met.xml load_met_${model}.xml

DATE=`/apps/ops/prod/nco/core/prod_util.v2.0.13/exec/ndate +24 $DATE`

done

exit


cat << EOF > load_met_${model}.xml
<load_spec>
  <connection>
    <host>metviewer-dev-cluster.cluster-czbts4gd2wm2.us-east-1.rds.amazonaws.com:3306</host>
    <database>mv_lam_pcp_2021_metplus</database>
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
  <group>EMC CAM para</group>
  <description>Loading of CAM para precip</description>
 <folder_tmpl>/base_dir/{model}</folder_tmpl>
  <load_val>
    <field name="model">
      <val>${model}</val>
    </field>
  </load_val>


  <load_xml>true</load_xml>
</load_spec>
EOF

/lfs/h2/emc/physics/noscrub/${USER}/aws/mv_load_to_aws.sh perry.shafran ${MET_PLUS_TMP}/stat/ ${MET_PLUS_TMP}/load_met_fv3lam.xml

cp /lfs/h2/emc/ptmp/${USER}/output/metplus_fv3lam_pcp.out $MET_PLUS_STD/metplus_fv3lam_$DATE.out

exit
