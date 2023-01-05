#!/bin/bash
module load prod_util
module load prod_envir
#
MSG="$0 EXP [prod|para6d|...] FIRSTDAY LASTDAY"
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

EXP=`echo ${envir} | tr a-z A-Z`

logdir=/lfs/h2/emc/ptmp/${USER}/archive_verification_stat_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/archive_verification_stat_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/lfs/h2/emc/ptmp/${USER}/archive_verification_stat_data
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

hpsshourly=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aq_hourly_point_stat
hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aq_daily_point_stat

datadir=/lfs/h2/emc/physics/noscrub/${USER}/metplus_aq/stat/aqm

cd ${rundir}
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    if [ -d ${datadir}/${NOW} ]; then
        /bin/rm -f ${datadir}/${NOW}/${EXP}*
    else
        echo "Can not find ${datadir}/${NOW}"
    fi
    echo ${NOW}
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
