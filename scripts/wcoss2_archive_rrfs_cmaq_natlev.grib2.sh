#!/bin/bash
module load prod_util
module load prod_envir
MSG="$0 EXP [para|para1|...] START_DATE END_DATE"
if [ $# -lt 3 ]; then
   echo ${MSG}
   exit
fi
set -x
export in_envir=$1
export FIRSTDAY=$2
export LASTDAY=$3

if [[ "${in_envir}" == *"_"* ]]; then
    length=${#in_envir}
    cutlim=$(expr ${length} - 2)
    headcom=`echo ${in_envir} | cut -c1-${cutlim}`
    tailcom=`echo ${in_envir} | cut -c${length}-${length}`
    out_envir=${headcom}${tailcom}
else
    out_envir=${in_envir}
fi
echo "out_envir=${out_envir}"
data_in=/lfs/h2/emc/ptmp/ho-chun.huang/data/RRFSCMAQ/${in_envir}
if [ "${in_envir}" == "v70a1" ]; then
    data_in=/lfs/h2/emc/ptmp/jianping.huang/para/com/aqm/v7.0/aqm.v7.0.a1
    out_envir=${in_envir}
fi
if [ "${in_envir}" == "v70b1" ]; then
    data_in=/lfs/h2/emc/ptmp/jianping.huang/para/com/aqm/v7.0/aqm.v7.0.b1
    out_envir=${in_envir}
fi

hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/RRFS_postprd_grib2/${in_envir}
outdir=/scratch1/NCEPDEV/stmp2/${USER}
outdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/RRFS-CMAQ
outdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/RRFS-CMAQ
hsi mkdir -p ${hpssroot}
logdir=/lfs/h2/emc/ptmp/${USER}/VERF_logs
mkdir -p ${logdir}
declare -a cyc=( 06 12 )
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    ## idir=/scratch2/NCEPDEV/stmp1/jianping.huang/expt_dirs/${envir}/${NOW}${cyc}/postprd
    ## odir=${outdir}/${envir}/aqm.${NOW}/postprd
    odir=${outdir}/${out_envir}/aqm.${NOW}/postprd
    mkdir -p ${odir}/POST_STAT
    for i in "${cyc[@]}"; do
        idir=${data_in}/${NOW}${i}/postprd
        cp -p ${idir}/*natlevf* ${odir}
        ## cp -p ${idir}/*prslevf* ${odir}
        if [ -d ${idir}/POST_STAT ]; then cp -pr ${idir}/POST_STAT/*  ${odir}/POST_STAT; fi
	echo "${NOW} ${i}"
    done
    cd ${outdir}/${out_envir}
    if [ -d aqm.${NOW} ]; then
        htar cf ${hpssroot}/aqm.${NOW}.tar aqm.${NOW} > ${logdir}/rrfs_natlevf.${out_envir}.${NOW}.log 2>&1 &
    else
        echo "Can not find ${outdir}/${out_envir}/aqm.${NOW}"	    
    fi
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
