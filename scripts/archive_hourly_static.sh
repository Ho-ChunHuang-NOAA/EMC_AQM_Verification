#!/bin/bash
module load prod_util/1.1.6
module load prod_envir/1.1.0
module load HPSS/5.0.2.5
TODAY=`date +%Y%m%d`

MSG="$0 EXP start_date end_date"
if [ $# -lt 1 ]; then
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

if [[ "${envir}" == *"_bc"* ]]; then
    length=${#envir}
    cutlim=$(expr ${length} - 3)
    EXP=`echo ${envir} | cut -c1-${cutlim}`
else
    EXP=${envir}
fi

logdir=/gpfs/dell2/ptmp/${USER}/archive_verification_stat_${envir}_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/gpfs/dell2/ptmp/${USER}/archive_verification_stat_${envir}_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

datadir=/gpfs/dell2/ptmp/${USER}/archive_verification_stat_${envir}_data
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

hpssroot=/5year/NCEPDEV/emc-naqfc/${USER} ## archive 5 year

aq_daily=/gpfs/dell2/emc/verification/noscrub/${USER}/metplus_aq/stat/aqm

YY0=`echo ${FIRSTDAY} | cut -c1-4`
YM0=`echo ${FIRSTDAY} | cut -c1-6`
hpssdir=${hpssroot}/metplus_aq_hourly_point_stat/${EXP}/${YY0}/${YM0}
hsi mkdir -p ${hpssdir}

aq_hourly=/gpfs/dell2/emc/verification/noscrub/${USER}/metplus_aq/aqm/stat
aqmmax_hourly=/gpfs/dell2/emc/verification/noscrub/${USER}/metplus_aq

declare -a hr_type=( aq pm )
declare -a case=( ${envir} )

NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    if [ ${YY} -ne ${YY0} ] | [ ${YM} -ne ${YM0} ]; then
        echo "${YY0} ${YM0} to ${YY} ${YM}, hpss mkdir"
        YY0=${YY}
        YM0=${YM}
        hpssdir=${hpsshourly}/${EXP}/${YY}/${YM}
        hsi mkdir -p ${hpssdir}
    fi
    for i in "${hr_type[@]}"; do
        for j in "${case[@]}"; do
            mkdir -p ${datadir}/${i}_${j}_${NOW}
            cp -p  ${aq_hourly}/${i}/${j}/*${NOW}*  ${datadir}/${i}_${j}_${NOW}
            cd ${datadir}
            htar -cf ${hpssdir}/${i}_${j}_${NOW}.tar ${i}_${j}_${NOW}
        done
    done
    i=aqmmax
    j=aqmmax
    for k in "${case[@]}"; do
        mkdir -p ${datadir}/${j}_${k}_${NOW}
        cp -p  ${aqmmax_hourly}/${i}/stat/${j}/${k}/*${NOW}*  ${datadir}/${j}_${k}_${NOW}
        cd ${datadir}
        htar -cf ${hpssdir}/${j}_${k}_${NOW}.tar ${j}_${k}_${NOW}
    done
    i=pmmax
    j=pmmax
    for k in "${case[@]}"; do
        mkdir -p ${datadir}/${j}_${k}_${NOW}
        cp -p  ${aqmmax_hourly}/${i}/stat/${j}/${k}/*${NOW}*  ${datadir}/${j}_${k}_${NOW}
        cd ${datadir}
        htar -cf ${hpssdir}/${j}_${k}_${NOW}.tar ${j}_${k}_${NOW}
    done
    j=pmave
    for k in "${case[@]}"; do
        mkdir -p ${datadir}/${j}_${k}_${NOW}
        cp -p  ${aqmmax_hourly}/${i}/stat/${j}/${k}/*${NOW}*  ${datadir}/${j}_${k}_${NOW}
        cd ${datadir}
        htar -cf ${hpssdir}/${j}_${k}_${NOW}.tar ${j}_${k}_${NOW}
    done
    echo ${NOW}
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
