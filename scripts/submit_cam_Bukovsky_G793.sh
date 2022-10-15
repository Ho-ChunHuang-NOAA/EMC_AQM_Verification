#!/bin/bash
module load prod_util
module load prod_envir
#
MSG="$0 envir FIRSTDAY LASTDAY"
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

logdir=/lfs/h2/emc/ptmp/${USER}/VERF_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/VERF_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/lfs/h2/emc/ptmp/${USER}/VERF_run
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

script_dir=`pwd`
caseid=icmaq
caseid=cam
jobname=metplus_${caseid}
script_base=run_${jobname}.template_Bukovsky_G793
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
    Bias_Corr=''
fi

declare -a obs_cyc=( 00 06 12 18 )
declare -a fcst_cyc=( 06 12 )
let obs_hour_beg=0
let obs_hour_end=6
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
    jjob=${caseid}_${envir}_b793_${NOW}
    out_logfile=${logdir}/${jjob}.log
    err_logfile=${logdir}/${jjob}.log
    if [ -s ${out_logfile} ]; then /bin/rm ${out_logfile}; fi
    if [ -s ${err_logfile} ]; then /bin/rm ${err_logfile}; fi
    OBS_INPUT_NCO=/lfs/h1/ops/prod/com/obsproc/v1.0
    OBS_INPUT_USER=/lfs/h2/emc/physics/noscrub/${USER}/verification/com/nam/prod
    obs_dir=${OBS_INPUT_NCO}
    find_obs_prepbufr=yes
    for i in "${obs_cyc[@]}"; do
        let t=${obs_hour_beg}
        while [ ${t} -le ${obs_hour_end} ]; do
            icnt=`printf %2.2d ${t}`
            ckfile=${obs_dir}/nam.${PDYm1}/nam.t${i}z.prepbufr.tm${icnt}
            ckfile=${obs_dir}/nam.${PDYm1}/nam.t${i}z.prepbufr.tm${icnt}.nr
            if [ -s ${ckfile} ]; then
                if [ "${icnt}" == "06" ]; then echo "Found        ${ckfile}"; fi
            else
                if [ "${icnt}" == "06" ]; then echo "Can not find ${ckfile}"; fi
                find_obs_prepbufr=no
                break
            fi
            ((t++))
        done
        if [ "${find_obs_prepbufr}" == "no" ]; then break; fi
    done
    if [ "${find_obs_prepbufr}" == "yes" ]; then
        obs_select=${obs_dir}
    else
        obs_dir=${OBS_INPUT_USER}
        for i in "${obs_cyc[@]}"; do
            let t=${obs_hour_beg}
            while [ ${t} -le ${obs_hour_end} ]; do
                icnt=`printf %2.2d ${t}`
                ckfile=${obs_dir}/nam.${PDYm1}/nam.t${i}z.prepbufr.tm${icnt}
                ckfile=${obs_dir}/nam.${PDYm1}/nam.t${i}z.prepbufr.tm${icnt}.nr
                if [ -s ${ckfile} ]; then
                    if [ "${icnt}" == "06" ]; then echo "Found        ${ckfile}";fi
                else
                    if [ "${icnt}" == "06" ]; then echo "Can not find ${ckfile}"; fi
                fi
                ((t++))
            done
        done
        obs_select=${obs_dir}   ## one need to assign obs_select no matter what, it can failed during the run, it is okay
    fi
    FCST_INPUT_NCO=/lfs/h1/ops/prod/com/aqm/v6.1
    FCST_INPUT_USER=/lfs/h2/emc/physics/noscrub/${USER}/verification/RRFS-CMAQ/${EXP}
    fcst_dir=${FCST_INPUT_NCO}
    find_fcst_grib2=yes
    for i in "${fcst_cyc[@]}"; do
        ckfile=${fcst_dir}/aqm.${PDYm3}/postprd/aqm.t${i}z.all.f072.793.grib2
        if [ -s ${ckfile} ]; then
            echo "Found        ${ckfile}"
        else
            echo "Can not find ${ckfile}"
            find_fcst_grib2=no
        fi
    done
    if [ "${find_fcst_grib2}" == "yes" ]; then
        fcst_select=${fcst_dir}
    else
        fcst_dir=${FCST_INPUT_USER}
        for i in "${fcst_cyc[@]}"; do
            ckfile=${fcst_dir}/aqm.${PDYm3}/postprd/aqm.t${i}z.all.f072.793.grib2
            if [ -s ${ckfile} ]; then
                echo "Found        ${ckfile}"
            else
                echo "Can not find ${ckfile}"
            fi
        done
        fcst_select=${fcst_dir}   ## one need to assign fcst_select no matter what, it can failed during the run, it is okay
    fi
    run_script=run_${jjob}.sh
    sed -e "s!xxBASE!${HOMEverif}!" -e "s!xxFCST_INPUT!${fcst_select}!" -e "s!xxOBS_INPUT!${obs_select}!" -e "s!xxENVIR!${envir}!" -e "s!xxJOB!${jjob}!" -e "s!xxOUTLOG!${out_logfile}!" -e "s!xxERRLOG!${err_logfile}!" -e "s!xxDATEp1!${PDYp1}!" -e "s!xxDATE!${NOW}!" ${script_dir}/${script_base} > ${working_dir}/${run_script}
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

