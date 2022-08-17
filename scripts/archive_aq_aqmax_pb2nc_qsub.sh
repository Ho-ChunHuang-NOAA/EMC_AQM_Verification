#!/bin/bash
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

logdir=/lfs/h2/emc/ptmp/${USER}/archive_aqm_pb2nc_${envir}_logs
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/archive_aqm_pb2nc_${envir}_script
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang ## archive 5 year

#
# /5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aqmax_pb2nc/prod/2022
# /5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/metplus_aqm_pb2nc/prod/2022/202205
#
aqm_pb2nc_datadir=/lfs/h2/emc/physics/noscrub/Perry.Shafran/metplus_cam/cam/conus_cam
datadir=/lfs/h2/emc/physics/noscrub/${USER}/metplus_aq

NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    cd ${working_dir}
    task_cpu='04:30:00'
    job_name=arch_aqm_pb2nc_nc_${NOW}
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
#PBS -l debug=true
module load envvar/1.0
module load PrgEnv-intel/8.2.0
module load intel/19.1.3.304
module load craype/2.7.8
module load cray-mpich/8.1.9

module load prod_util
    declare -a var=( aq pm aqmax1 aqmax8 pmmax pmave )
    cd ${working_dir}
    YY=${YY}
    YM=${YM}
    NOW=${NOW}
    USER=${USER}
    hpssroot=${hpssroot}
    datadir=${datadir}
EOF
   
if [ -s ${batch_script}.add ]; then /bin/rm -f ${batch_script}.add; fi
cat > ${batch_script}.add << 'EOF'
    for i in "${var[@]}"; do
        case ${i} in
            aq) indir=${datadir}/aqm/conus_sfc/prod/aq;;
            pm) indir=${datadir}/aqm/conus_sfc/prod/pm;;
            aqmax1) indir=${datadir}/aqmmax/aqmax1/prod;;
            aqmax8) indir=${datadir}/aqmmax/aqmax8/prod;;
            pmmax) indir=${datadir}/pmmax/pmmax/prod;;
            pmave) indir=${datadir}/pmmax/pmave/prod;;
        esac
	if [ "${i}" == "aq" ]; then
           hsifile=prepbufr.aqm.${NOW}.nc
	elif [ "${i}" == "pm" ]; then
           hsifile=prepbufr.pm.${NOW}.nc
        else
           hsifile=prepbufr.aqm.${NOW}00.nc
        fi
	hpssdir=${hpssroot}/metplus_${i}_pb2nc/prod/${YY}/${YM}
        hsi mkdir -p ${hpssdir}
	cd ${indir}
        if [ -s ${hsifile} ]; then
            hsi "cd ${hpssdir}; put ${hsifile}"
        else
            echo "Can not find ${indir}/${hsifile}"
        fi
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
