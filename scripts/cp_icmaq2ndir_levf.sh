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

logdir=/gpfs/dell2/ptmp/${USER}/rename_icmaq_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/gpfs/dell2/ptmp/Ho-Chun.Huang/rename_icmaq_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/gpfs/dell2/ptmp/Ho-Chun.Huang/rename_icmaq_run
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

in_envir=v161_a
in_envir=v150_a
declare -a cyc=( 12 )
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
idir=/gpfs/dell2/emc/retros/noscrub/Jianping.Huang/data/RRFSCMAQ/${in_envir}
odir=/gpfs/dell2/emc/modeling/noscrub/Ho-Chun.Huang/verification/aqm/${out_envir}
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    for i in "${cyc[@]}"; do
        inputdir=${idir}/${NOW}${i}
        outputdir=${odir}/aqm.${NOW}
        mkdir -p ${outputdir}
        if [ -d ${inputdir} ]; then
            cp -p ${inputdir}/aqm.t${i}z.*.grib2 ${outputdir}
        else
            echo "can not find ${inputdir}, skip to next day"
        fi
    done
    echo ${NOW}
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
echo "inputdir =${inputdir}"
echo "output_dir=${outputdir}"
exit
