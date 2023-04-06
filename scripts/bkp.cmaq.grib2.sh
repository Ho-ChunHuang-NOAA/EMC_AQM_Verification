#!/bin/bash
source /u/ho-chun.huang/versions/run.ver
#    ## require for module load prod_util
module load prod_util
module load prod_envir
#
flag_test=yes
flag_test=no

TODAY=`date +%Y%m%d`
   
MSG="$0 EXP start_date end_date"
if [ $# -eq 1 ]; then
    echo ${MSG}
    exit
elif [ $# -eq 1 ]; then
    envir=$1
    FIRSTDAY=${TODAY}
    LASTDAY=${TODAY}
    flag_realtime=yes
elif [ $# -eq 2 ]; then
    envir=$1
    FIRSTDAY=$2
    LASTDAY=$2
elif [ $# -gt 2 ]; then
    envir=$1
    FIRSTDAY=$2
    LASTDAY=$3
fi

model=aqm
bkpdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/${model}/${envir}
hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang ## archive 5 year
if [ ! -d ${bkpdir} ]; then
    echo "Can not find ${bkpdir}"
    exit
fi

YY0=`echo ${FIRSTDAY} | cut -c1-4`
YM0=`echo ${FIRSTDAY} | cut -c1-6`
hpssdir=${hpssroot}/Verification_Grib2/${envir}/${YY0}/${YM0}
hsi mkdir -p ${hpssdir}
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    hpssdir=${hpssroot}/Verification_Grib2/${envir}/${YY}/${YM}
    if [ ${YY} -ne ${YY0} ] | [ ${YM} -ne ${YM0} ]; then
        echo "${YY0} ${YM0} to ${YY} ${YM}, hpss mkdir"
        YY0=${YY}
        YM0=${YM}
        hsi mkdir -p ${hpssdir}
    fi
   
    target_dir=${model}.${NOW}

    working_dir=/lfs/h2/emc/stmp/${USER}/to_hpss_${model}_verification_grib2_${envir}
    if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

    ## Now at working dir
    cd ${working_dir}

    job_name=verif_${envir}_${NOW}
    batch_script=to_hpss_${model}_verif_${envir}_${NOW}.sh
    if [ -s ${batch_script} ]; then /bin/rm -f ${batch_script}; fi

    logdir=/lfs/h2/emc/ptmp/${USER}/batch_logs
    if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

    logfile=${logdir}/${job_name}.out
    if [ -s ${logfile} ]; then /bin/rm -f ${logfile}; fi

    task_cpu='04:59:00'
cat > ${batch_script} << EOF
#!/bin/bash
#PBS -o ${logfile}
#PBS -e ${logfile}
#PBS -l place=shared,select=1:ncpus=1:mem=4500MB
#PBS -N j${job_name}
#PBS -q dev_transfer
#PBS -A AQM-DEV
#PBS -l walltime=${task_cpu}
#PBS -l debug=true
## module load envvar/${envvar_ver}
## module load PrgEnv-intel/${PrgEnv_intel_ver}
## module load intel/${intel_ver}
## module load craype/${craype_ver}
## module load cray-mpich/${cray_mpich_ver}
# 
##
##  Provide fix date daily Hysplit data processing
##

#    ## require for ## module load prod_util
## module load prod_util
#

cd ${bkpdir}
if [ ! -d ${target_dir} ]; then 
    echo "${bkpdir}/${target_dir} can not be found; No HPSS backup performed" 
else
    echo "HPSS BACKUP :: ${bkpdir}/${target_dir}"
    htar -cf ${hpssdir}/${target_dir}.tar ${target_dir}
fi
echo "HPSS location is ${hpssdir}"
exit
EOF
    ##
    ##  Submit run scripts
    ##
    if [ "${flag_test}" == "no" ]; then
        ## cat ${batch_script} | qsub
        ## bash ${batch_script} > ${logfile} 2>&1 &
        bash ${batch_script} > ${logfile} 2>&1
        echo "Batch_script : ${working_dir}/${batch_script}"
    else
        echo "test qsub < ${batch_script} completed"
    fi
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
