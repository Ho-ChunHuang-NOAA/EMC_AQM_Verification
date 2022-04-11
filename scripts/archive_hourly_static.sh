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

logdir=/gpfs/dell2/ptmp/${USER}/archive_verification_stat_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/gpfs/dell2/ptmp/Ho-Chun.Huang/archive_verification_stat_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

datadir=/gpfs/dell2/ptmp/Ho-Chun.Huang/archive_verification_stat_data
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

hpssdaily=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aq_daily_point_stat
hpsshourly=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aq_hourly_point_stat

aq_hourly=/gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/metplus_aq/aqm/stat
aqmmax_hourly=/gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/metplus_aq

declare -a hr_type=( aq pm )
declare -a envir=( prod prod_bc )
declare -a envir=( para6d para6d_bc )

NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    hpssdir_h=${hpsshourly}/${YY}/${YM}
    hpssdir_d=${hpssdaily}/${YY}/${YM}
    ## hsi mkdir -p ${hpssdir_h}
    for i in "${hr_type[@]}"; do
        for j in "${envir[@]}"; do
            mkdir -p ${datadir}/${i}_${j}_${NOW}
            cp -p  ${aq_hourly}/${i}/${j}/*${NOW}*  ${datadir}/${i}_${j}_${NOW}
            cd ${datadir}
            htar -cf ${hpssdir_h}/${i}_${j}_${NOW}.tar ${i}_${j}_${NOW}
        done
    done
    i=aqmmax
    j=aqmmax
    for k in "${envir[@]}"; do
        mkdir -p ${datadir}/${j}_${k}_${NOW}
        cp -p  ${aqmmax_hourly}/${i}/stat/${j}/${k}/*${NOW}*  ${datadir}/${j}_${k}_${NOW}
        cd ${datadir}
        htar -cf ${hpssdir_h}/${j}_${k}_${NOW}.tar ${j}_${k}_${NOW}
    done
    i=pmmax
    j=pmmax
    for k in "${envir[@]}"; do
        mkdir -p ${datadir}/${j}_${k}_${NOW}
        cp -p  ${aqmmax_hourly}/${i}/stat/${j}/${k}/*${NOW}*  ${datadir}/${j}_${k}_${NOW}
        cd ${datadir}
        htar -cf ${hpssdir_h}/${j}_${k}_${NOW}.tar ${j}_${k}_${NOW}
    done
    j=pmave
    for k in "${envir[@]}"; do
        mkdir -p ${datadir}/${j}_${k}_${NOW}
        cp -p  ${aqmmax_hourly}/${i}/stat/${j}/${k}/*${NOW}*  ${datadir}/${j}_${k}_${NOW}
        cd ${datadir}
        htar -cf ${hpssdir_h}/${j}_${k}_${NOW}.tar ${j}_${k}_${NOW}
    done
    echo ${NOW}
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
