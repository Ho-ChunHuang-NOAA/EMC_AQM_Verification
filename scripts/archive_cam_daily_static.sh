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

hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_cam_daily_point_stat

datadir=/lfs/h2/emc/physics/noscrub/${USER}/metplus_cam/stat/cam

YY0=`echo ${FIRSTDAY} | cut -c1-4`
YM0=`echo ${FIRSTDAY} | cut -c1-6`
hpssdir=${hpssroot}/${YY0}/${YM0}
hsi mkdir -p ${hpssdir}
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    hpssdir=${hpssroot}/${YY}/${YM}
    if [ ${YY} -ne ${YY0} ] | [ ${YM} -ne ${YM0} ]; then
        echo "${YY0} ${YM0} to ${YY} ${YM}, hpss mkdir"
        YY0=${YY}
        YM0=${YM}
        hsi mkdir -p ${hpssdir}
    fi
    hsifile=${EXP}_CAM_${NOW}.stat
    if [ -s ${datadir}/${NOW}/${hsifile} ]; then
        cd ${datadir}/${NOW}
        ## hsi "cd ${hpssdir}; put ${hsifile}" > ${logdir}/${hsifile}.log 2>&1 &
        hsi "cd ${hpssdir}; put ${hsifile}"
    else
        echo "Can not find ${datadir}/${NOW}/${hsifile}"
    fi
    echo ${NOW}
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
