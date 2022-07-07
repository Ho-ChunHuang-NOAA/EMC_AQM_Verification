#!/bin/bash
module load prod_util
module load prod_envir
#
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

logdir=/lfs/h2/emc/ptmp/${USER}/archive_verification_stat_${envir}_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/archive_verification_stat_${envir}_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

datadir=/lfs/h2/emc/ptmp/${USER}/archive_verification_stat_${envir}_data
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang ## archive 5 year

cam_daily=/lfs/h2/emc/physics/noscrub/${USER}/metplus_cam/stat/cam

YY0=`echo ${FIRSTDAY} | cut -c1-4`
YM0=`echo ${FIRSTDAY} | cut -c1-6`
hpssdir=${hpssroot}/metplus_cam_hourly_point_stat/${EXP}/${YY0}/${YM0}
hsi mkdir -p ${hpssdir}

cam_hourly=/lfs/h2/emc/physics/noscrub/${USER}/metplus_cam/cam/stat

declare -a case=( ${envir} )

NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    if [ ${YY} -ne ${YY0} ] | [ ${YM} -ne ${YM0} ]; then
        echo "${YY0} ${YM0} to ${YY} ${YM}, hpss mkdir"
        YY0=${YY}
        YM0=${YM}
        hpssdir=${hpssroot}/metplus_cam_hourly_point_stat/${EXP}/${YY}/${YM}
        hsi mkdir -p ${hpssdir}
    fi
    for j in "${case[@]}"; do
        mkdir -p ${datadir}/${j}_CAM_${NOW}
        cp -p  ${cam_hourly}/${j}/*${NOW}*  ${datadir}/${j}_CAM_${NOW}
        cd ${datadir}
        htar -cf ${hpssdir}/${j}_CAM_${NOW}.tar ${j}_CAM_${NOW}
    done
    echo ${NOW}
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
