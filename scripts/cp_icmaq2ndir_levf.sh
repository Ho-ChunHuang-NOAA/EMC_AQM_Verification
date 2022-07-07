#!/bin/bash
module load prod_util
module load prod_envir
#
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

logdir=/lfs/h2/emc/ptmp/${USER}/rename_icmaq_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/rename_icmaq_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/lfs/h2/emc/ptmp/${USER}/rename_icmaq_run
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
idir=/lfs/h2/emc/ptmp/ho-chun.huang/data/RRFSCMAQ/${in_envir}
odir=/lfs/h2/emc/physics/noscrub/${USER}/verification/aqm/${out_envir}
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
