#!/bin/bash
source /u/${USER}/versions/run.ver
module load prod_util/${prod_util_ver}
MSG="$0 Hourly_type [aqobs|data] FIRSTDAY LASTDAY"
## set -x
if [ $# -lt 1 ]; then
    echo ${MSG}
    TODAY=`date +%Y%m%d`
    cdate=${TODAY}"00"
    TDYm1=$(${NDATE} -24 ${cdate}| cut -c1-8)
    TDYm3=$(${NDATE} -72 ${cdate}| cut -c1-8)
    FIRSTDAY=${TDYm3}
    LASTDAY=${TDYm1}
else
    FIRSTDAY=$1
    LASTDAY=$2
fi
echo "Processing ${FIRSTDAY} ${LASTDAY}"

hpssroot="/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/dcom_ascii2nc_airnow"
dcomout=/lfs/h1/ops/prod/dcom
usr_input=/lfs/h2/emc/physics/noscrub/${USER}/epa_airnow_acsii
output_dir=/lfs/h2/emc/vpppg/noscrub/${USER}/dcom_ascii2nc_airnow

working_dir=/lfs/h2/emc/stmp/${USER}/ACSII2NC_AIRNOW
log_dir=/lfs/h2/emc/ptmp/${USER}/batch_logs

mkdir -p ${working_dir} ${log_dir}

YY0=`echo ${FIRSTDAY} | cut -c1-4`
YM0=`echo ${FIRSTDAY} | cut -c1-6`
hpssdir=${hpssroot}/${YY0}/${YM0}
hsi mkdir -p ${hpssdir}

let icount=0
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    ((icount++))
    if [ ${icount} -eq 100 ]; then
        echo "icount = ${icount}, something wrong with the date loop, stop the job"
        exit
    fi

    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`

    if [ "${YY}" != "${YY0}" ] || [ "${YM}" != "${YM0}" ]; then
        YY0=${YY}
	YM0=${YM}
        hpssdir=${hpssroot}/${YY0}/${YM0}
        hsi mkdir -p ${hpssdir}
    fi

    cd ${working_dir}
    job_name=daily_metplus_ascii2nc_airnow
    batch_script=${job_name}.${NOW}.sh
    if [ -e ${batch_script} ]; then /bin/rm -f ${batch_script}; fi

    log_dir=/lfs/h2/emc/ptmp/${USER}/batch_logs
    if [ ! -d ${log_dir} ]; then mkdir -p ${log_dir}; fi

    logfile=${log_dir}/${job_name}_${NOW}.out
    if [ -e ${logfile} ]; then /bin/rm -f ${logfile}; fi

    cmdfmt=airnowhourly

    task_cpu='04:30:00'
    task_cpu='01:30:00'
    task_cpu='00:30:00'
cat > ${batch_script} << EOF
#!/bin/bash
#PBS -o ${logfile}
#PBS -e ${logfile}
#PBS -l place=shared,select=1:ncpus=1:mem=5GB
#PBS -N j${job_name}
#PBS -q dev_transfer
#PBS -A AQM-DEV
#PBS -l walltime=${task_cpu}
#####PBS -l debug=true
##

   export OMP_NUM_THREADS=1
   cd ${working_dir}
   YY=${YY}
   YM=${YM}
   NOW=${NOW}
   USER=${USER}
   hpssdir=${hpssdir}
   working_dir=${working_dir}
   log_dir=${log_dir}
   dcomout=${dcomout}
   usr_input=${usr_input}
   output_dir=${output_dir}
   cmdfmt=${cmdfmt}
   flag_test=no
EOF
   
    if [ -s ${batch_script}.add ]; then /bin/rm -f ${batch_script}.add; fi
cat > ${batch_script}.add << 'EOF'

export HOMEevs=/lfs/h2/emc/vpppg/noscrub/$USER/EVS

###%include <envir-p1.h>

############################################################
# Load modules
############################################################

   source $HOMEevs/versions/run.ver

   evs_ver_2d=$(echo $evs_ver | cut -d'.' -f1-2)

   module reset
   module load prod_envir/${prod_envir_ver}

   source $HOMEevs/dev/modulefiles/aqm/aqm_prep.sh

   set -x 

    if [ ! -d ${output_dir} ]; then mkdir -p  ${output_dir}; fi


    idir=${dcomout}/${NOW}/airnow
    if [ ! -d ${idir} ]; then
        idir=${usr_input}/${YY}/${NOW}
	if [ ! -d ${idir} ]; then
            echo "can not find ${dcomout}/${NOW}/airnow or ${usr_input}/${YY}/${NOW}, program end"
	    exit
        fi
    fi
    if [ -s ${idir}/Monitoring_Site_Locations_V2.dat ]; then
        export MET_AIRNOW_STATIONS=${idir}/Monitoring_Site_Locations_V2.dat
    else
        echo "WARNING :: Can not find ${idir}/Monitoring_Site_Locations_V2.dat"
    fi
    odir=${output_dir}/${NOW}
    ## odir=${output_dir}/${NOW}_${version_opt}
    if [ ! -d ${odir} ]; then mkdir -p  ${odir}; fi

    hourly_opt=data
    let t=0
    let tend=23
    while [ ${t} -le ${tend} ]; do
        icnt=`printf %2.2d ${t}`
        ofile=airnow_hourly_${hourly_opt}_${NOW}${icnt}.nc
        if [ "${hourly_opt}" == "aqobs" ]; then
            ifile=HourlyAQObs_${NOW}${icnt}.dat
        else
            ifile=HourlyData_${NOW}${icnt}.dat
        fi
        if [ -s ${idir}/${ifile} ]; then
	    echo "======================================="
	    echo "processing ${ifile}"
	    echo "======================================="
            ascii2nc ${idir}/${ifile} ${odir}/${ofile} -format ${cmdfmt}
        else
            echo "Can not find ${idir}/${ifile}"
        fi
        ((t++))
    done

    hourly_opt=aqobs
    if [ "${hourly_opt}" == "aqobs" ]; then cmdfmt=${cmdfmt}aqobs; fi
    let t=0
    let tend=23
    while [ ${t} -le ${tend} ]; do
        icnt=`printf %2.2d ${t}`
        ofile=airnow_hourly_${hourly_opt}_${NOW}${icnt}.nc
        if [ "${hourly_opt}" == "aqobs" ]; then
            ifile=HourlyAQObs_${NOW}${icnt}.dat
        else
            ifile=HourlyData_${NOW}${icnt}.dat
        fi
        if [ -s ${idir}/${ifile} ]; then
	    echo "======================================="
	    echo "processing ${ifile}"
	    echo "======================================="
            ascii2nc ${idir}/${ifile} ${odir}/${ofile} -format ${cmdfmt}
        else
            echo "Can not find ${idir}/${ifile}"
        fi
        ((t++))
    done

    ifile=daily_data_v2.dat
    ofile=airnow_daily_${NOW}.nc
    logfile=${logdir}/ascii2nc_airnow_daily_${NOW}.log
    if [ -s ${idir}/${ifile} ]; then
	echo "======================================="
	echo "processing ${ifile}"
	echo "======================================="
        ascii2nc ${idir}/${ifile} ${odir}/${ofile} -format "airnowdaily_v2"
    else
        echo "Can not find ${idir}/${ifile}"
    fi

    cd ${output_dir}
    htar -cf ${hpssdir}/${NOW}.tar ${NOW}

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
       echo "${working_dir}/${batch_script}"
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done

exit
