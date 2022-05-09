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

declare -a cyc=( 12 )
idir=/gpfs/dell2/ptmp/Hsin-Mu.Lin
odir=/gpfs/dell2/ptmp/${USER}/icmaq
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    for i in "${cyc[@]}"; do
        inputdir=${idir}/post_fv3_${NOW}${i}
        outputdir=${odir}/${NOW}${i}/posrprd
        mkdir -p ${outputdir}
        let t=1
        let tend=72
        while [ ${t} -le ${tend} ]; do
           ic=`printf %2.2d ${t}`
           if [ -s ${inputdir}/PRSLEV${ic}.tm00 ]; then
               cp ${inputdir}/PRSLEV${ic}.tm00 ${outputdir}/rrfs.t${i}z.prslevf${ic}.tm00.grib2
           else 
               echo "Can not find ${inputdir}/PRSLEV${ic}.tm00"
           fi
           if [ -s ${inputdir}/NATLEV${ic}.tm00 ]; then
               cp ${inputdir}/NATLEV${ic}.tm00 ${outputdir}/rrfs.t${i}z.natlevf${ic}.tm00.grib2
           else 
               echo "Can not find ${inputdir}/NATLEV${ic}.tm00"
           fi
           ((t++))
        done
    done
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
echo "inputdir =${inputdir}"
echo "output_dir=${outputdir}"
exit
