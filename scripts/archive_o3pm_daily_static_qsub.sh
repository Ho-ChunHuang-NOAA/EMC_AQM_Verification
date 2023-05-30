#!/bin/bash
source /u/ho-chun.huang/versions/run.ver
module load prod_util
module load prod_envir
#
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

logdir=/lfs/h2/emc/ptmp/${USER}/arch_o3pm_stat_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/arch_o3pm_stat_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/lfs/h2/emc/ptmp/${USER}/arch_o3pm_stat_data
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

hpsshourly=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aq_hourly_point_stat
hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aq_daily_point_stat

datadir=/lfs/h2/emc/physics/noscrub/${USER}/metplus_aq/stat/aqm

cd ${working_dir}
task_cpu='01:00:00'
job_name=arch_o3pm_stat_${envir}_${FIRSTDAY}_${LASTDAY}
batch_script=${job_name}.sh
if [ -e ${batch_script} ]; then /bin/rm -f ${batch_script}; fi

logfile=${logdir}/${job_name}.out
if [ -e ${logfile} ]; then /bin/rm -f ${logfile}; fi
cat > ${batch_script} << EOF
#!/bin/bash
#PBS -o ${logfile}
#PBS -e ${logfile}
#PBS -S /bin/bash
#PBS -l place=shared,select=1:ncpus=1:mem=4500MB
#PBS -N j${job_name}
#PBS -q dev_transfer
#PBS -A VERF-DEV
#PBS -l walltime=${task_cpu}
####PBS -l debug=true
## module load envvar/${envvar_ver}
## module load PrgEnv-intel/${PrgEnv_intel_ver}
## module load intel/${intel_ver}
## module load craype/${craype_ver}
## module load cray-mpich/${cray_mpich_ver}

## module load prod_util

envir=${envir}
EXP=${EXP}
FIRSTDAY=${FIRSTDAY}
LASTDAY=${LASTDAY}
hpssroot=${hpssroot}
datadir=${datadir}
rundir=${rundir}
EOF
   
if [ -s ${batch_script}.add ]; then /bin/rm -f ${batch_script}.add; fi
cat > ${batch_script}.add << 'EOF'
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
            ls ${datadir}/${NOW}/${EXP}*
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
EOF
##
##  Combine both working script together
##
    cat ${batch_script}.add >> ${batch_script}
##
##  Submit run scripts
##
    cat ${batch_script} | qsub
    echo "batch_script=${working_dir}/${batch_script}"
    echo "logfile=${logfile}"
