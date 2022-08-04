#!/bin/sh
module load prod_util
module load prod_envir
#
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

## set -x

BASE=`pwd`
export HOMEverif="$(dirname ${BASE})"

logdir=/lfs/h2/emc/ptmp/${USER}/VERF_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/VERF_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/lfs/h2/emc/ptmp/${USER}/VERF_run
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

script_dir=`pwd`
caseid=hysplit_dust
jobname=metplus_${caseid}
script_base=run_${jobname}.template
if [ ! -s ${script_base} ]; then
   echo "Can not find ${script_base}"
   exit
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
    OBS_INPUT_NCO=/lfs/h1/ops/prod/dcom/${NOW}/wgrbbul/dust
    OBS_INPUT_USER=/lfs/h2/emc/physics/noscrub/${USER}/aod_dust/conc/aquamodis.${NOW}
    obs_dir=${OBS_INPUT_NCO}
    flag_find_obs=no
    let i=0
    while [ ${i} -le 23 ]; do
        icnt=`printf %2.2d ${i}`
        if [ -s ${obs_dir}/MYDdust.aod_conc.v6.3.4.${NOW}.hr${icnt}.grib ]; then
            echo "found MYDdust.aod_conc.v6.3.4.${NOW}.hr${icnt}.grib"
            flag_find_obs=yes
            break
        fi
        ((i++))
    done
    if [ "${flag_find_obs}" == "no" ]; then
        obs_dir=${OBS_INPUT_USER}
        let i=0
        while [ ${i} -le 23 ]; do
            icnt=`printf %2.2d ${i}`
            if [ -s ${obs_dir}/MYDdust.aod_conc.v6.3.4.${NOW}.hr${icnt}.grib ]; then
                echo "found MYDdust.aod_conc.v6.3.4.${NOW}.hr${icnt}.grib"
                flag_find_obs=yes
                break
            fi
            ((i++))
        done
    fi
    if [ "${flag_find_obs}" == "no" ]; then
        echo "There is no observation data in ${OBS_INPUT_NCO} or ${OBS_INPUT_USER}"
        echo "No verification is performed"
    else
        obs_select=${obs_dir}
    fi
    FCST_INPUT_NCO=/lfs/h1/ops/${envir}/com/hysplit/v7.9
    FCST_INPUT_USER=/lfs/h2/emc/physics/noscrub/${USER}/com/hysplit/${envir}
    fcst_dir=${FCST_INPUT_NCO}
    if [ -s ${fcst_dir}/dustcs.${PDYm2}/dustcs.t06z.pbl.1hr.grib2 ] || [ -s ${fcst_dir}/dustcs.${PDYm2}/dustcs.t06z.pbl.1hr.grib2 ]; then
        fcst_select=${fcst_dir}
    else
        fcst_dir=${FCST_INPUT_USER}
        if [ -s ${fcst_dir}/dustcs.${PDYm2}/dustcs.t06z.pbl.1hr.grib2 ] || [ -s ${fcst_dir}/dustcs.${PDYm2}/dustcs.t12z.pbl.1hr.grib2 ]; then
            fcst_select=${fcst_dir}
        else
            chkfile=cs.${PDYm2}/dustcs.t06z.pbl.1hr.grib2
            if [ ! -s ${fcst_dir}/${chkfile} ]; then
                echo "Can not find ${chkfile} in ${FCST_INPUT_NCO} and ${FCST_INPUT_USER}, skip to next day"
            fi
            chkfile=cs.${PDYm2}/dustcs.t12z.pbl.1hr.grib2
            if [ ! -s ${fcst_dir}/${chkfile} ]; then
                echo "Can not find ${chkfile} in ${FCST_INPUT_NCO} and ${FCST_INPUT_USER}, skip to next day"
            fi
            cdate=${NOW}"00"
            NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
            continue
        fi
    fi
    run_script=run_${jjob}.sh
    sed -e "s!xxBASE!${HOMEverif}!" -e "s!xxFCST_INPUT!${fcst_select}!" -e "s!xxOBS_INPUT!${obs_select}!" -e "s!xxENVIR!${envir}!" -e "s!xxJOB!${jjob}!" -e "s!xxOUTLOG!${out_logfile}!" -e "s!xxERRLOG!${err_logfile}!" -e "s!xxDATEp1!${PDYp1}!" -e "s!xxDATEm2!${PDYm2}!" -e "s!xxDATEm1!${PDYm1}!" -e "s!xxDATE!${NOW}!" ${script_dir}/${script_base} > ${working_dir}/${run_script}
    if [ -s ${working_dir}/${run_script} ]; then
        echo "${working_dir}/${run_script}"
        cat ${working_dir}/${run_script} | qsub
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

