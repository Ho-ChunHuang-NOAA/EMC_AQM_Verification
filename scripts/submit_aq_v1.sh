#!/bin/sh
module load prod_util
module load prod_envir
#
MSG="$0 FIRSTDAY LASTDAY"
if [ $# -lt 1 ]; then
    echo ${MSG}
    exit
elif [ $# -lt 2 ]; then
    FIRSTDAY=$1
    LASTDAY=$1
else
    FIRSTDAY=$1
    LASTDAY=$2
fi

BASE=`pwd`
export HOMEverif="$(dirname ${BASE})"

logdir=/lfs/h2/emc/ptmp/${USER}/VERF_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/VERF_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/lfs/h2/emc/ptmp/${USER}/VERF_run
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

script_dir=`pwd`
caseid=icmaq
caseid=aq
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

    cdate=${NOW}"00"
    PDYp1=$( ${NDATE} +24 ${cdate} | cut -c1-8 )
    jjob=${jobname}_${NOW}
    out_logfile=${logdir}/${jjob}.log
    err_logfile=${logdir}/${jjob}.log
    if [ -s ${out_logfile} ]; then /bin/rm ${out_logfile}; fi
    if [ -s ${err_logfile} ]; then /bin/rm ${err_logfile}; fi

    run_script=run_${jobname}_${NOW}.sh
    sed -e "s!xxBASE!${HOMEverif}!" -e "s!xxJOB!${jjob}!" -e "s!xxOUTLOG!${out_logfile}!" -e "s!xxERRLOG!${err_logfile}!" -e "s!xxDATEp1!${PDYp1}!" -e "s!xxDATE!${NOW}!" ${script_dir}/${script_base} > ${working_dir}/${run_script}
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

