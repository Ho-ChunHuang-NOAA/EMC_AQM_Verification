#!/bin/sh
module load prod_util/1.1.6
module load prod_envir/1.1.0
module load HPSS/5.0.2.5
MSG="$0 FIRSTDAY LASTDAY"
if [ $# -lt 2 ]; then
    echo ${MSG}
    exit
elif [ $# -lt 3 ]; then
    envir=$1
    FIRSTDAY=$2
    LASTDAY=$2
else
    envir=$1
    FIRSTDAY=$2
    LASTDAY=$3
fi

BASE=`pwd`
export HOMEverif="$(dirname ${BASE})"

logdir=/gpfs/dell2/ptmp/${USER}/VERF_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/gpfs/dell2/ptmp/${USER}/VERF_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/gpfs/dell2/ptmp/${USER}/VERF_run
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

aqm_model=aqm
satellite=viirs
verify_var=aod
verify_var1=`echo ${verify_var} | tr a-z A-Z`
viirs_regrid_aod=/gpfs/dell2/emc/modeling/noscrub/${USER}/VIIRS_${verify_var1}/METPLUS_REGRID

script_dir=`pwd`
caseid=icmaq
caseid=aqm_viirs_aod
jobname=metplus_${caseid}
script_base=run_${jobname}.template
if [ ! -s ${script_base} ]; then
   echo "Can not find ${script_base}"
   exit
fi 
#
# Find EXP Name if envir="EXP"_bc
#
if [[ "${envir}" == *"_bc"* ]]; then
    length=${#envir}
    cutlim=$(expr ${length} - 3)
    EXP=`echo ${envir} | cut -c1-${cutlim}`
    Bias_Corr='_bc'
else
    EXP=${envir}
    Bias_Bcorr=''
fi

NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`

    #
    ## note verification is performed based on the timeline of obs ${NOW}
    ## It may required model output of ${NOW}, ${PDYm1}, ${PDYm2},.... depends on how many days of forecast
    #
    cdate=${NOW}"00"
    PDYm3=$( ${NDATE} -72 ${cdate} | cut -c1-8 )
    PDYm2=$( ${NDATE} -48 ${cdate} | cut -c1-8 )
    PDYm1=$( ${NDATE} -24 ${cdate} | cut -c1-8 )
    PDYp1=$( ${NDATE} +24 ${cdate} | cut -c1-8 )
    jjob=${caseid}_${envir}_${NOW}
    out_logfile=${logdir}/${jjob}.log
    err_logfile=${logdir}/${jjob}.log
    if [ -s ${out_logfile} ]; then /bin/rm ${out_logfile}; fi
    if [ -s ${err_logfile} ]; then /bin/rm ${err_logfile}; fi
    OBS_INPUT_NCO=/gpfs/dell2/emc/modeling/noscrub/${USER}/VIIRS_AOD/AOD
    OBS_INPUT_USER=/gpfs/dell2/emc/modeling/noscrub/${USER}/VIIRS_AOD/AOD
    obs_dir=${OBS_INPUT_NCO}
    if [ -s ${obs_dir}/${NOW}/VIIRS-L3-AOD_AQM_${NOW}_230000.nc ]; then
        obs_select=${obs_dir}
    else
        obs_dir=${OBS_INPUT_USER}
        if [ -s ${obs_dir}/${NOW}/VIIRS-L3-AOD_AQM_${NOW}_230000.nc ]; then
            obs_select=${obs_dir}
        else
            chkfile=${NOW}/VIIRS-L3-AOD_AQM_${NOW}_230000.nc
            echo "Can not find ${chkfile} in ${OBS_INPUT_NCO} and ${OBS_INPUT_USER}, skip to next day"
            cdate=${NOW}"00"
            NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
            continue
        fi
    fi
    FCST_INPUT_NCO=/gpfs/hps/nco/ops/com/aqm/prod
    FCST_INPUT_USER=/gpfs/dell2/emc/modeling/noscrub/${USER}/verification/aqm/${EXP}
    fcst_dir=${FCST_INPUT_NCO}
    if [ -s ${fcst_dir}/aqm.${PDYm2}/aqm.t06z.aot.f72.148.grib2 ]; then
        fcst_select=${fcst_dir}
    else
        fcst_dir=${FCST_INPUT_USER}
        if [ -s ${fcst_dir}/aqm.${PDYm2}/aqm.t06z.aot.f72.148.grib2 ]; then
            fcst_select=${fcst_dir}
        else
            chkfile=aqm.${PDYm2}/aqm.t06z.aot.f72.148.grib2
            echo "Can not find ${chkfile} in ${FCST_INPUT_NCO} and ${FCST_INPUT_USER}, skip to next day"
            if [ 1 -eq 1 ]; then
                fcst_select=${fcst_dir}
            else
                cdate=${NOW}"00"
                NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
                continue
            fi
        fi
    fi

    run_script=run_${jjob}.sh
    sed -e "s!xxVIIRS_REGRID_AOD_OUTPUT!${viirs_regrid_aod}!" -e "s!xxAOD_TYPE!${verify_var}!" -e "s!xxSAT_TYPE!${satellite}!" -e "s!xxMODEL!${aqm_model}!" -e "s!xxBASE!${HOMEverif}!" -e "s!xxFCST_INPUT!${fcst_select}!" -e "s!xxOBS_INPUT!${obs_select}!" -e "s!xxENVIR!${envir}!" -e "s!xxJOB!${jjob}!" -e "s!xxOUTLOG!${out_logfile}!" -e "s!xxERRLOG!${err_logfile}!" -e "s!xxDATEm1!${PDYm1}!" -e "s!xxDATEp1!${PDYp1}!" -e "s!xxDATE!${NOW}!" ${script_dir}/${script_base} > ${working_dir}/${run_script}
    if [ -s ${working_dir}/${run_script} ]; then
        echo "${working_dir}/${run_script}"
        cat ${working_dir}/${run_script} | bsub
    else
        echo "Can not find ${working_dir}/${run_script}"
    fi
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
echo "working_dir=${working_dir}"
echo "run_scrpt = ${working_dir}/${run_script}"
echo "log_file  = ${out_logfile}"
exit

