#!/bin/sh
module load ips/18.0.5.274    ## require for module load prod_util/1.1.6
module load prod_util/1.1.6
module load prod_envir/1.1.0
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
bkpdir=/gpfs/dell2/emc/modeling/noscrub/${USER}/verification/${model}/${envir}
hpssroot=/5year/NCEPDEV/emc-naqfc/${USER} ## archive 5 year
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

    working_dir=/gpfs/dell2/stmp/${USER}/to_hpss_${model}_verification_grib2_${envir}
    if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

    ## Now at working dir
    cd ${working_dir}

    job_name=verif_${envir}_${NOW}
    batch_script=to_hpss_${model}_verif_${envir}_${NOW}.sh
    if [ -s ${batch_script} ]; then /bin/rm -f ${batch_script}; fi

    logdir=/gpfs/dell2/ptmp/${USER}/batch_logs
    if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

    logfile=${logdir}/${job_name}.out
    if [ -s ${logfile} ]; then /bin/rm -f ${logfile}; fi

    task_cpu='01:00'
cat > ${batch_script} << EOF
#!/bin/sh
#BSUB -o ${logfile}
#BSUB -e ${logfile}
#BSUB -n 1
#BSUB -J j${job_name}
#BSUB -q dev_transfer
#BSUB -P HYS-T2O
#BSUB -W ${task_cpu}
#BSUB -R span[ptile=1]
#BSUB -R affinity[core]
#BSUB -R rusage[mem=200]
##
##  Provide fix date daily Hysplit data processing
##

module load ips/18.0.5.274    ## require for module load prod_util/1.1.6
module load prod_util/1.1.6
module load HPSS/5.0.2.5

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
        ## cat ${batch_script} | bsub
        ## bash ${batch_script} > ${logfile} 2>&1 &
        bash ${batch_script} > ${logfile} 2>&1
        echo "Batch_script : ${working_dir}/${batch_script}"
    else
        echo "test bsub < ${batch_script} completed"
    fi
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
