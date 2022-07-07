#!/bin/sh
module load prod_util
module load prod_envir
#
MSG="$0 EXP [para|para1|...] CYC START_DATE END_DATE"
if [ $# -lt 4 ]; then
   echo ${MSG}
   exit
fi
## set -x
export in_envir=$1
export cyc=$2
export FIRSTDAY=$3
export LASTDAY=$4

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

hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/RRFS_postprd_grib2/${in_envir}
outdir=/scratch1/NCEPDEV/stmp2/${USER}
outdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/RRFS-CMAQ
hsi mkdir -p ${hpssroot}
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    ## idir=/scratch2/NCEPDEV/stmp1/jianping.huang/expt_dirs/${envir}/${NOW}${cyc}/postprd
    ## odir=${outdir}/${envir}/aqm.${NOW}/postprd
    idir=/lfs/h2/emc/ptmp/ho-chun.huang/data/RRFSCMAQ/${in_envir}/${NOW}${cyc}/postprd
    odir=${outdir}/${out_envir}/aqm.${NOW}/postprd
    mkdir -p ${odir}
    cp -p ${idir}/*natlevf* ${odir}
    ## cp -p ${idir}/*prslevf* ${odir}
    if [ -d ${idir}/POST_STAT ]; then cp -pr ${idir}/POST_STAT ${odir}; fi
    cd ${outdir}/${out_envir}
    htar cf ${hpssroot}/aqm.${NOW}.tar aqm.${NOW} > /lfs/h2/emc/ptmp/${USER}/VERF_logs/nam_prebufr.${NOW}.log 2>&1 &
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
