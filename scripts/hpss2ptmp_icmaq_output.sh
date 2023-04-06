#!/bin/bash
source /u/ho-chun.huang/versions/run.ver
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

logdir=/lfs/h2/emc/ptmp/${USER}/archive_icmaq_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/archive_icmaq_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/lfs/h2/emc/ptmp/${USER}/archive_icmaq_run
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

declare -a cyc=( 12 )
idir=/lfs/h2/emc/ptmp/${USER}/icmaq

cd ${rundir}
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/${YY}_Inline_CMAQ_UPP_SAVE
    for i in "${cyc[@]}"; do
        timestamp=${NOW}${i}
        if [ -d ${idir}/${timestamp} ]; then
           batch_script=submit_archive_${timestamp}.sh
           logfile=${logdir}/archive_Inline_cmaq_${timestamp}.log
           if [ -s ${logfile} ]; then /bin/rm -f ${logfile}; fi
cat << EOF > ${batch_script}
#!/bin/bash
#PBS -N archive_icmaq_${timestamp}
#PBS -o ${logfile}
#PBS -e ${logfile}
#PBS -q dev_transfer
#PBS -A AQM-DEV
# 
#PBS -l place=shared,select=1:ncpus=1:mem=4500MB
#PBS -l walltime=02:00:00
#PBS -l debug=true
## module load envvar/${envvar_ver}
## module load PrgEnv-intel/${PrgEnv_intel_ver}
## module load intel/${intel_ver}
## module load craype/${craype_ver}
## module load cray-mpich/${cray_mpich_ver}
# 
mkdir -p ${idir}
cd ${idir}
htar -xf ${hpssroot}/${timestamp}.tar
EOF
            cat ${batch_script} | qsub
        else
            echo "Can not find ${idir}/${timestamp}"
        fi
        echo "${rundir}/${batch_script}"
        echo "${logfile}"
    done
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
