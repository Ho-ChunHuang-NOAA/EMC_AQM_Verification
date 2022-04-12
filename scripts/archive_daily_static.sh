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

aq_daily=/gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/metplus_aq/stat/aqm

YY0=`echo ${FIRSTDAY} | cut -c1-4`
YM0=`echo ${FIRSTDAY} | cut -c1-6`
hpssdir_d=${hpssdaily}/${YY0}/${YM0}
hsi mkdir -p ${hpssdir_d}
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    hpssdir_d=${hpssdaily}/${YY}/${YM}
    if [ ${YY} -ne ${YY0} ] | [ ${YM} -ne ${YM0} ]; then
        echo "${YY0} ${YM0} to ${YY} ${YM}, hpss mkdir"
        YY0=${YY}
        YM0=${YM}
        hsi mkdir -p ${hpssdir_d}
    fi
    mkdir -p ${datadir}/aqm_daily.${NOW}
    if [ -d ${aq_daily}/${NOW} ]; then
        cp -p  ${aq_daily}/${NOW}/*  ${datadir}/aqm_daily.${NOW}
        cd ${datadir}
        htar -cf ${hpssdir_d}/aqm_daily_${NOW}.tar aqm_daily.${NOW}
    else
        echo "Can not find ${aq_daily}/${NOW}"
    fi
    echo ${NOW}
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
