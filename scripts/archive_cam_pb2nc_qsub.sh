#!/bin/bash
source /u/ho-chun.huang/versions/run.ver
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

logdir=/lfs/h2/emc/ptmp/${USER}/archive_cam_pb2nc_${envir}_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/archive_cam_pb2nc_${envir}_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

datadir=/lfs/h2/emc/ptmp/${USER}/archive_cam_pb2nc_${envir}_data
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang ## archive 5 year

#
# /5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aqmax_pb2nc/prod/2022
# /5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_cam_pb2nc/prod/2022/202205
#
cam_pb2nc_datadir=/lfs/h2/emc/physics/noscrub/Perry.Shafran/metplus_cam/cam/conus_cam
cam_pb2nc_datadir=/lfs/h2/emc/physics/noscrub/${USER}/metplus_cam/cam/conus_cam

declare -a hr_type=( cam )
declare -a case=( ${envir} )


NOW=${FIRSTDAY}
YY0=`echo ${NOW} | cut -c1-4`
YM0=`echo ${NOW} | cut -c1-6`
hpssdir=${hpssroot}/metplus_cam_pb2nc/${EXP}/${YY0}/${YM0}
hsi mkdir -p ${hpssdir}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    if [ ${YY} -ne ${YY0} ] | [ ${YM} -ne ${YM0} ]; then
        echo "${YY0} ${YM0} to ${YY} ${YM}, hpss mkdir"
        YY0=${YY}
        YM0=${YM}
        hpssdir=${hpssroot}/metplus_cam_pb2nc/${EXP}/${YY}/${YM}
        hsi mkdir -p ${hpssdir}
    fi
    cd ${working_dir}
    task_cpu='04:30:00'
    job_name=arch_cam_pb2nc_nc_${NOW}
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
#PBS -A HYS-DEV
#PBS -l walltime=${task_cpu}
#####PBS -l debug=true
## module load envvar/${envvar_ver}
## module load PrgEnv-intel/${PrgEnv_intel_ver}
## module load intel/${intel_ver}
## module load craype/${craype_ver}
## module load cray-mpich/${cray_mpich_ver}

## module load prod_util
    cd ${working_dir}
    NOW=${NOW}
    USER=${USER}
    cam_pb2nc_datadir=${cam_pb2nc_datadir}
    hpssdir=${hpssdir}
EOF
   
if [ -s ${batch_script}.add ]; then /bin/rm -f ${batch_script}.add; fi
cat > ${batch_script}.add << 'EOF'
    cd ${cam_pb2nc_datadir}
    let tbeg=0
    let tend=23
    let t0=${tbeg}
    while [ ${t0} -le ${tend} ]; do
        ic=`printf %2.2d ${t0}`
        cpfile=prepbufr.nam.${NOW}${ic}.nc
        if [ -s ${cpfile} ]; then
            hsi "cd ${hpssdir}; put ${cpfile}"
        else
            echo "Can not find ${cam_pb2nc_datadir}/${cpfile}"
        fi
        ((t0++))
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

    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
