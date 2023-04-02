#!/bin/bash
source /u/ho-chun.huang/versions/run.ver
module load prod_util/${prod_util_ver}
MSG="$0 Hourly_type [aqobs|data] FIRSTDAY LASTDAY"
## set -x
if [ $# -lt 1 ]; then
    echo ${MSG}
    TODAY=`date +%Y%m%d`
    cdate=${TODAY}"00"
    TDYm1=$(${NDATE} -24 ${cdate}| cut -c1-8)
    TDYm3=$(${NDATE} -72 ${cdate}| cut -c1-8)
    hourly_opt=aqobs
    FIRSTDAY=${TDYm3}
    LASTDAY=${TDYm1}
else
    hourly_opt=$1
    FIRSTDAY=$2
    LASTDAY=$3
fi
echo "Processing ${hourly_opt} ${FIRSTDAY} ${LASTDAY}"

declare -a data_type=( aqobs data )
flag_check_datatype=no
for i in "${data_type[@]}"; do
    if [ "${i}" == "${hourly_opt}" ]; then
        flag_check_datatype=tes
        break
    fi
done
if [ "${flag_check_datatype}" == "no" ]; then
    echo "input data type ${hourly_opt} is not defined, option are \"${data_type[@]}\", program stop"
    exit
fi
## hourly_opt=aqobs
## hourly_opt=data

version_opt=11.0.0
version_opt=11.0.1

working_dir=/lfs/h2/emc/stmp/${USER}/ACSII2NC_AIRNOW_${hourly_opt}
log_dir=/lfs/h2/emc/ptmp/${USER}/batch_logs

mkdir -p ${working_dir} ${log_dir}

YY0=`echo ${FIRSTDAY} | cut -c1-4`
hpssdir=${hpssroot}/epa_airnow_acsii/${YY0}
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
      SY=`echo ${NOW} | cut -c3-4`
      YM=`echo ${NOW} | cut -c1-6`
      URL=https://s3-us-west-1.amazonaws.com//files.airnowtech.org/airnow/${YY}/${NOW}

      if [ "${YY}" != "${YY0}" ]; then
	  YY0=${YY}
          hpssdir=${hpssroot}/epa_airnow_acsii/${YY0}
          hsi mkdir -p ${hpssdir}
      fi

      cd ${working_dir}
      task_cpu='04:30:00'
      job_name=daily_wget_epa_airnow
      batch_script=${job_name}.${NOW}.sh
      if [ -e ${batch_script} ]; then /bin/rm -f ${batch_script}; fi

      log_dir=/lfs/h2/emc/ptmp/${USER}/batch_logs
      if [ ! -d ${log_dir} ]; then mkdir -p ${log_dir}; fi

      logfile=${log_dir}/${job_name}_${NOW}.out
      if [ -e ${logfile} ]; then /bin/rm -f ${logfile}; fi
cat > ${batch_script} << EOF
#!/bin/bash
#PBS -o ${logfile}
#PBS -e ${logfile}
#PBS -l place=shared,select=1:ncpus=1:mem=5GB
#PBS -N j${job_name}
#PBS -q dev_transfer
#PBS -A HYS-DEV
#PBS -l walltime=${task_cpu}
#####PBS -l debug=true
##
##  Provide fix date daily Hysplit data processing
##
module load envvar/${envvar_ver}
module load PrgEnv-intel/${PrgEnv_intel_ver}
module load intel/${intel_ver}
module load craype/${craype_ver}
module load cray-mpich/${cray_mpich_ver}

set -x 

   module load prod_util/${prod_util_ver}
   export OMP_NUM_THREADS=1
   cd ${working_dir}
   NOW=${NOW}
   USER=${USER}
   hpssdir=${hpssdir}
   working_dir=${working_dir}
   log_dir=${log_dir}
   URL=${URL}
   data_root=${data_root}
   data_dir=${data_root}/${YY}/${NOW}
   YY=${YY}
   flag_test=no
   URL=${URL}
   user=${user}
   password=${password}
EOF
   
if [ -s ${batch_script}.add ]; then /bin/rm -f ${batch_script}.add; fi
cat > ${batch_script}.add << 'EOF'

if [ "${hourly_opt}" == "data" ]; then version_opt=11.0.1; fi

if [ "${version_opt}" == "11.0.0" ]; then metplus_opt=5.0.0; fi
if [ "${version_opt}" == "11.0.0" ]; then nco_opt=prod; fi

if [ "${version_opt}" == "11.0.1" ]; then metplus_opt=5.0.1; fi
if [ "${version_opt}" == "11.0.1" ]; then nco_opt=para; fi
ihost=wcoss2
if [ "${ihost}" == "wcoss2" ]; then
    module reset
    ## module use /apps/ops/prod/libs/modulefiles/compiler/intel/19.1.3.304/
    ## export HPC_OPT=/apps/ops/prod/libs
    module use /apps/ops/${nco_opt}/libs/modulefiles/compiler/intel/19.1.3.304/
    export HPC_OPT=/apps/ops/${nco_opt}/libs
    module load intel
    module load gsl/2.7
    module load python/3.8.6
    module load netcdf/4.7.4
    module load met/${version_opt}
    module load metplus/${metplus_opt}
    module load prod_util
    module load prod_envir
    logdir=/lfs/h2/emc/ptmp/ho-chun.huang/batch_logs
    mkdir -p ${logdir}

    input_dir=/lfs/h2/emc/physics/noscrub/ho-chun.huang/epa_airnow_acsii
    output_dir=/lfs/h2/emc/vpppg/noscrub/ho-chun.huang/dcom_ascii2nc_airnow
    if [ ! -d ${output_dir} ]; then mkdir -p  ${output_dir}; fi

else

    module use /scratch2/NCEPDEV/nwprod/hpc-stack/libs/hpc-stack/    modulefiles/stack
    module load hpc/1.1.0  hpc-intel/18.0.5.274
    module load prod_util/1.2.2

    module use -a /contrib/anaconda/    modulefiles
    module load intel/2022.1.2
    module load anaconda/latest
    module use -a /contrib/met/    modulefiles/
    module load met/11.0.1-rc1

    logdir=/scratch1/NCEPDEV/stmp2/Ho-Chun.Huang/run_log
    mkdir -p ${logdir}

    input_dir=/scratch2/NCEPDEV/naqfc/Ho-Chun.Huang/noscrub/dcom
    output_dir=/scratch2/NCEPDEV/naqfc/Ho-Chun.Huang/noscrub/dcom_ascii2nc_airnow
    if [ ! -d ${output_dir} ]; then mkdir -p  ${output_dir}; fi

fi
ASCII2NC_INPUT_DIR=${idir}
## ASCII2NC_INPUT_TEMPLATE={valid?fmt=%Y%m%d}/HourlyAQObs_{valid?fmt=%Y%m%d%H}.dat
## ASCII2NC_INPUT_TEMPLATE={valid?fmt=%Y%m%d}/HourlyData_{valid?fmt=%Y%m%d%H}.dat
ASCII2NC_INPUT_TEMPLATE={valid?fmt=%Y%m%d}/daily_data_v2.dat
ASCII2NC_OUTPUT_DIR=${odir}
## ASCII2NC_OUTPUT_TEMPLATE={valid?fmt=%Y%m%d}/airnow_hourly_${hourly_opt}_{valid?fmt=%Y%m%d%H}.nc
## ASCII2NC_OUTPUT_TEMPLATE={valid?fmt=%Y%m%d}/airnow_hourly_data_{valid?fmt=%Y%m%d%H}.nc
## ASCII2NC_OUTPUT_TEMPLATE={valid?fmt=%Y%m%d}/airnow_daily_{valid?fmt=%Y%m%d}.nc
ASCII2NC_SKIP_IF_OUTPUT_EXISTS=False
ASCII2NC_FILE_WINDOW_BEGIN=
ASCII2NC_FILE_WINDOW_END=
ASCII2NC_WINDOW_BEGIN=
ASCII2NC_WINDOW_END=
## ASCII2NC_INPUT_FORMAT="airnowhourly${hourly_opt}"
## ASCII2NC_INPUT_FORMAT="airnowhourly"
## ASCII2NC_INPUT_FORMAT="airnowdaily_v2"
cmdfmt=airnowhourly
if [ "${hourly_opt}" == "aqobs" ]; then cmdfmt=${cmdfmt}aqobs; fi
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    if [ "${ihost}" == "wcoss2" ]; then
        idir=${input_dir}/${YY}/${NOW}
    else
        idir=${input_dir}/${NOW}/airnow
    fi
    if [ -s ${idir}/Monitoring_Site_Locations_V2.dat ]; then
        export MET_AIRNOW_STATIONS=${idir}/Monitoring_Site_Locations_V2.dat
    else
        echo "WARNING :: Can not find ${idir}/Monitoring_Site_Locations_V2.dat"
    fi
    odir=${output_dir}/${NOW}
    ## odir=${output_dir}/${NOW}_${version_opt}
    if [ ! -d ${odir} ]; then mkdir -p  ${odir}; fi
    let t=0
    let tend=23
    while [ ${t} -le ${tend} ]; do
        icnt=`printf %2.2d ${t}`
        logfile=${logdir}/ascii2nc_airnow_hourly_${hourly_opt}_${NOW}${icnt}.log
        ## logfile=${logdir}/ascii2nc_airnow_hourly_data_${NOW}${icnt}.log
        ofile=airnow_hourly_${hourly_opt}_${NOW}${icnt}.nc
        ## ofile=airnow_hourly_data_${NOW}${icnt}.nc
        if [ "${hourly_opt}" == "aqobs" ]; then
            ifile=HourlyAQObs_${NOW}${icnt}.dat
        else
            ifile=HourlyData_${NOW}${icnt}.dat
        fi
        if [ -s ${idir}/${ifile} ]; then
            ascii2nc ${idir}/${ifile} ${odir}/${ofile} -format ${cmdfmt} > ${logfile} 2>&1 &
        else
            echo "Can not find ${idir}/${ifile}"
        fi
        ((t++))
    done
    if [ "${hourly_opt}" == "aqobs" ]; then
        ifile=daily_data_v2.dat
        ofile=airnow_daily_${NOW}.nc
        logfile=${logdir}/ascii2nc_airnow_daily_${NOW}.log
        if [ -s ${idir}/${ifile} ]; then
            ascii2nc ${idir}/${ifile} ${odir}/${ofile} -format "airnowdaily_v2" > ${logfile} 2>&1 &
        else
            echo "Can not find ${idir}/${ifile}"
        fi
    fi

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
