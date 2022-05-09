#!/bin/bash
module load prod_util/1.1.6
module load prod_envir/1.1.0
module load HPSS/5.0.2.5
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

logdir=/gpfs/dell2/ptmp/${USER}/archive_verification_stat_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/gpfs/dell2/ptmp/Ho-Chun.Huang/archive_verification_stat_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/gpfs/dell2/ptmp/Ho-Chun.Huang/archive_verification_stat_data
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aq_daily_point_stat
hpsshourly=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aq_hourly_point_stat

datadir=/gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/metplus_aq/stat/aqm

YY0=`echo ${FIRSTDAY} | cut -c1-4`
YM0=`echo ${FIRSTDAY} | cut -c1-6`
hpssdir=${hpssroot}/${YY0}/${YM0}
hsi mkdir -p ${hpssdir}
cd ${rundir}
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
    if [ -d ${datadir}/${NOW} ]; then
        if [ -d aqm_${envir}.${NOW} ]; then /bin/rm -rf aqm_${envir}.${NOW}; fi
        mkdir -p aqm_${envir}.${NOW}
        cp -p  ${datadir}/${NOW}/${EXP}*  aqm_${envir}.${NOW}
        if [ -s a1 ]; then /bin/rm -f a1; fi
        ls aqm_${envir}.${NOW} > a1
        nline=$(wc -l a1 | awk -F" " '{print $1}')
        if [ ${nline} -ge 1 ]; then
           ## echo "aqm_${envir}.${NOW} contain ${nline} files"
           htar -cf ${hpssdir}/aqm_${envir}_${NOW}.tar aqm_${envir}.${NOW}
        else
            echo "${rundir}/aqm_${envir}.${NOW} contain zero file"
        fi
    else
        echo "Can not find ${datadir}/${NOW}"
    fi
    echo ${NOW}
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
