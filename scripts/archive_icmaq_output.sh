#!/bin/bash
module load prod_util/1.1.6
module load prod_envir/1.1.0
module load HPSS/5.0.2.5
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

logdir=/gpfs/dell2/ptmp/${USER}/archive_icmaq_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/gpfs/dell2/ptmp/Ho-Chun.Huang/archive_icmaq_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/gpfs/dell2/ptmp/Ho-Chun.Huang/archive_icmaq_run
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

declare -a cyc=( 12 )
idir=/gpfs/dell2/ptmp/${USER}/icmaq
hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/2019_Inline_CMAQ_UPP_SAVE

cd ${rundir}
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    for i in "${cyc[@]}"; do
        timestamp=${NOW}${i}
        if [ -d ${idir}/${timestamp} ]; then
           batch_script=submit_archive_${timestamp}.sh
           logfile=${logdir}/archive_Inline_cmaq_${timestamp}.log
           if [ -s ${logfile} ]; then /bin/rm -f ${logfile}; fi
cat << EOF > ${batch_script}
#!/bin/bash
#BSUB -J archive_icmaq_${timestamp}
#BSUB -o ${logfile}
#BSUB -e ${logfile}
#BSUB -q "dev_transfer"
#BSUB -P CMAQ-T2O
#BSUB -R "rusage[mem=3000]"
#BSUB -n 1
#BSUB -W 02:00
#BSUB -R affinity[core(1)]

module load HPSS/5.0.2.5
cd ${idir}
if [ -d ${timestamp} ]; then
    htar -cf ${hpssroot}/${timestamp}.tar ${timestamp}
else
    echo "Can not find ${idir}/${timestamp}"
fi
EOF
            cat ${batch_script} | bsub
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
