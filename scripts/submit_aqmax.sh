#!/bin/sh
module load prod_util/1.1.6
module load prod_envir/1.1.0
module load HPSS/5.0.2.5
MSG="$0 EXP FIRSTDAY LASTDAY"
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

logdir=/gpfs/dell2/ptmp/${USER}/VERF_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/gpfs/dell2/ptmp/${USER}/VERF_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/gpfs/dell2/ptmp/${USER}/VERF_run
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

script_dir=`pwd`
caseid=icmaq
caseid=aq
caseid=aqmax
jobname=metplus_${caseid}
script_base=run_${jobname}.template_working
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
    obs_dir=/gpfs/dell1/nco/ops/com/hourly/prod
    if [ -s ${obs_dir}/hourly.${PDYp1}/aqm.t12z.anowpm.pb.tm024 ] && [ -s ${obs_dir}/hourly.${NOW}/aqm.t12z.prepbufr.tm00 ]; then
        run_type=realtime
    else
        obs_dir=/gpfs/dell2/emc/modeling/noscrub/${USER}/com/hourly/prod
        if [ -s ${obs_dir}/hourly.${PDYp1}/aqm.t12z.anowpm.pb.tm024 ] && [ -s ${obs_dir}/hourly.${NOW}/aqm.t12z.prepbufr.tm00 ]; then
            run_type=retro
        else
            echo "Can not find prepbufr data in ${obs_dir} and /gpfs/dell1/nco/ops/com/hourly/prod, program stop"
            exit
        fi
    fi
    fcst_dir=/gpfs/hps/nco/ops/com/aqm/prod
    if [ "${run_type}" == "realtime" ]; then
        if [ ! -s ${fcst_dir}/aqm.${PDYm3}/aqm.t12z.ave_1hr_pm25_bc.227.grib2 ]; then
           fcst_dir=/gpfs/dell2/emc/modeling/noscrub/${USER}/verification/aqm/prod
            if [ -s ${fcst_dir}/aqm.${PDYm3}/aqm.t12z.ave_1hr_pm25_bc.227.grib2 ]; then
                run_type=retro
            else
                echo "Can not find model ouput data ${PDYm3} in ${fcst_dir} and /gpfs/hps/nco/ops/com/aqm/prod, program stop"
                exit
            fi
        fi
    fi

    run_script=run_${jjob}.sh
    sed -e "s!xxRUN_TYPE!${run_type}!" -e "s!xxENVIR!${envir}!" -e "s!xxJOB!${jjob}!" -e "s!xxOUTLOG!${out_logfile}!" -e "s!xxERRLOG!${err_logfile}!" -e "s!xxDATEm3!${PDYm3}!" -e "s!xxDATEm2!${PDYm2}!" -e "s!xxDATEm1!${PDYm1}!" -e "s!xxDATEp1!${PDYp1}!" -e "s!xxDATE!${NOW}!" ${script_dir}/${script_base} > ${working_dir}/${run_script}
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

