#!/bin/sh
module load prod_util/1.1.6
module load prod_envir/1.1.0
module load HPSS/5.0.2.5
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
outdir=/scratch1/NCEPDEV/stmp2/Ho-Chun.Huang
outdir=/gpfs/dell2/emc/modeling/noscrub/Ho-Chun.Huang/verification/RRFS-CMAQ
hsi mkdir -p ${hpssroot}
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    ## idir=/scratch2/NCEPDEV/stmp1/Jianping.Huang/expt_dirs/${envir}/${NOW}${cyc}/postprd
    ## odir=${outdir}/${envir}/aqm.${NOW}/postprd
    idir=/gpfs/dell2/emc/retros/noscrub/Jianping.Huang/data/RRFSCMAQ/${in_envir}/${NOW}${cyc}/postprd
    odir=${outdir}/${out_envir}/aqm.${NOW}/postprd
    mkdir -p ${odir}
    cp -p ${idir}/*natlevf* ${odir}
    ## cp -p ${idir}/*prslevf* ${odir}
    if [ -d ${idir}/POST_STAT ]; then cp -pr ${idir}/POST_STAT ${odir}; fi
    cd ${outdir}/${out_envir}
    htar cf ${hpssroot}/aqm.${NOW}.tar aqm.${NOW} > /gpfs/dell2/ptmp/Ho-Chun.Huang/VERF_logs/nam_prebufr.${NOW}.log 2>&1 &
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
