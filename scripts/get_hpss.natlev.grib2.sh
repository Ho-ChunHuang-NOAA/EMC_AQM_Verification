#!/bin/bash
#    ## require for module load prod_util
module load prod_util
module load prod_envir
#
flag_test=yes
flag_test=no

# set -x

TODAY=`date +%Y%m%d`
   
MSG="$0 EXP start_date end_date"
if [ $# -lt 2 ]; then
    echo ${MSG}
    exit
elif [ $# -eq 2 ]; then
    envir=$1
    FIRSTDAY=$2
    LASTDAY=$2
elif [ $# -gt 2 ]; then
    envir=$1
    FIRSTDAY=$2
    LASTDAY=$3
fi

if [[ "${envir}" == *"_"* ]]; then
    length=${#envir}
    cutlim=$(expr ${length} - 2)
    headcom=`echo ${envir} | cut -c1-${cutlim}`
    tailcom=`echo ${envir} | cut -c${length}-${length}`
    local_envir=${headcom}${tailcom}
else
    local_envir=${envir}
fi
# if [ "${envir}" == "v161_a" ]; then local_envir=v161a; fi
# if [ "${envir}" == "v161_b" ]; then local_envir=v161b; fi
model=rrfs_cmaq
logdir=/lfs/h2/emc/ptmp/${USER}/com/${model}_output/${envir}
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

model=RRFS-CMAQ
hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/RRFS_postprd_grib2/${envir} ## archive 5 year
bkpdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/${model}/${local_envir}
if [ ! -d ${bkpdir} ]; then mkdir -p ${bkpdir}; fi

NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    target_dir=aqm.${NOW}
    cd ${bkpdir}
    htar -xf ${hpssroot}/${target_dir}.tar > ${logdir}/$0.${NOW}.log 2>&1 &
    echo "${logdir}/$0.${NOW}.log"
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
