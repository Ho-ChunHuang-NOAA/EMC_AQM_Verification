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

aq_daily=/lfs/h2/emc/physics/noscrub/${USER}/metplus_aq/stat/aqm

aq_pb2nc=/lfs/h2/emc/physics/noscrub/${USER}/metplus_aq/aqm/conus_sfc
aq_hourly=/lfs/h2/emc/physics/noscrub/${USER}/metplus_aq/aqm/stat
aqmmax_hourly=/lfs/h2/emc/physics/noscrub/${USER}/metplus_aq

declare -a hr_type=( aq pm )
declare -a case=( ${envir} )

NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    for i in "${hr_type[@]}"; do
        for j in "${case[@]}"; do
	    echo "${aq_pb2nc}/${j}"
            /bin/rm -rf  ${aq_pb2nc}/${j}
	    echo "${aq_hourly}/${i}/${j}"
            /bin/rm -rf  ${aq_hourly}/${i}/${j}
        done
    done
    i=aqmmax
    j=aqmmax
    for k in "${case[@]}"; do
	    echo "${aqmmax_hourly}/${i}/stat/${j}/${k}"
        /bin/rm -rf  ${aqmmax_hourly}/${i}/stat/${j}/${k}
            echo "${aqmmax_hourly}/aqmax1/${k}"
        /bin/rm -rf  ${aqmmax_hourly}/aqmax1/${k}
	    echo "${aqmmax_hourly}/aqmax8/${k}"
        /bin/rm -rf  ${aqmmax_hourly}/aqmax8/${k}
    done
    i=pmmax
    j=pmmax
    for k in "${case[@]}"; do
	    echo "${aqmmax_hourly}/${i}/stat/${j}/${k}"
        /bin/rm -rf  ${aqmmax_hourly}/${i}/stat/${j}/${k}
	    echo "${aqmmax_hourly}/${i}/${j}/${k}"
        /bin/rm -rf  ${aqmmax_hourly}/${i}/${j}/${k}
    done
    j=pmave
    for k in "${case[@]}"; do
	    echo "${aqmmax_hourly}/${i}/stat/${j}/${k}"
        /bin/rm -rf  ${aqmmax_hourly}/${i}/stat/${j}/${k}
	    echo "${aqmmax_hourly}/${i}/${j}/${k}"
        /bin/rm -rf  ${aqmmax_hourly}/${i}/${j}/${k}
    done
    echo ${NOW}
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
