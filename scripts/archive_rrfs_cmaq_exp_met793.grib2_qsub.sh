#!/bin/bash
MSG="$0 EXP [para|para1|...] START_DATE END_DATE"
if [ $# -lt 3 ]; then
   echo ${MSG}
   exit
fi
## set -x
export in_envir=$1
export FIRSTDAY=$2
export LASTDAY=$3

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
expid=aqm   # after 4/1/2023 directory will be changed into aqm.yyyymmdd
expid=`echo ${out_envir} | cut -c4-6`

data_in=/lfs/h2/emc/ptmp/ho-chun.huang/data/RRFSCMAQ/${in_envir}
data_in=/lfs/h2/emc/ptmp/jianping.huang/emc.para/com/aqm/v7.0/${expid}
if [ ! -d ${data_in}.${FIRSTDAY} ]; then
    echo "Can not find ${data_in}.${FIRSTDAY}, program exit"
    exit
fi

working_dir=/lfs/h2/emc/ptmp/${USER}/rrfs_met793_grib2_qsub_scripts
log_dir=/lfs/h2/emc/ptmp/${USER}/rrfs_met793_grib2_logs
mkdir -p ${working_dir} ${log_dir}

hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/Verification_met_Grib2/${in_envir}
outdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/met


NOW=${FIRSTDAY}
YY0=`echo ${NOW} | cut -c1-4`
YM0=`echo ${NOW} | cut -c1-6`
hsi mkdir -p ${hpssroot}/${YY0}/${YM0}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    if [ ${YY} -ne ${YY0} ] || [ ${YM} -ne ${YM0} ]; then
	echo "${YY0} ${YM0} to ${YY} ${YM}, hpss mkdir"
	YY0=${YY}
	YM0=${YM}
        hsi mkdir -p ${hpssroot}/${YY}/${YM}
    fi
    cd ${working_dir}
    task_cpu='01:00:00'
    job_name=daily_bkp_rrfs_met793_${NOW}
    batch_script=${job_name}.sh
    if [ -e ${batch_script} ]; then /bin/rm -f ${batch_script}; fi

    logfile=${log_dir}/${job_name}.out
    if [ -e ${logfile} ]; then /bin/rm -f ${logfile}; fi
cat > ${batch_script} << EOF
#!/bin/bash
#PBS -o ${logfile}
#PBS -e ${logfile}
#PBS -S /bin/bash
#PBS -l place=shared,select=1:ncpus=1:mem=5GB
#PBS -N j${job_name}
#PBS -q dev_transfer
#PBS -A AQM-DEV
#PBS -l walltime=${task_cpu}
#####PBS -l debug=true
## module load envvar/1.0
## module load PrgEnv-intel/8.2.0
## module load intel/19.1.3.304
## module load craype/2.7.8
## module load cray-mpich/8.1.9

##
##  Provide fix date daily Hysplit data processing
##
    ## module load prod_util
set -x
    cd ${working_dir}
    NOW=${NOW}
    USER=${USER}
    hpssroot=${hpssroot}/${YY}/${YM}
    working_dir=${working_dir}
    outdir=${outdir}
    data_in=${data_in}
    out_envir=${out_envir}
EOF
   
if [ -s ${batch_script}.add ]; then /bin/rm -f ${batch_script}.add; fi
cat > ${batch_script}.add << 'EOF'
    declare -a cyc=( 06 12 )
    odir=${outdir}/${out_envir}/aqm.${NOW}
    mkdir -p ${odir}
    for i in "${cyc[@]}"; do
        idir=${data_in}.${NOW}/${i}
	if [ -d ${idir} ]; then
            cp -p ${idir}/aqm.t${i}z.cmaq.f*.793.grib2 ${odir}
	    echo "${NOW} ${i}"
        else
	    echo "Can not find ${idir}"
	fi
    done
    cd ${outdir}/${out_envir}
    if [ -d aqm.${NOW} ]; then
        htar -cf ${hpssroot}/aqm.${NOW}.tar aqm.${NOW} 
    else
        echo "Can not find ${outdir}/${out_envir}/aqm.${NOW}"	    
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
       echo "SCRIPT   = ${working_dir}/${batch_script}"
       echo "LOG FILE = ${logfile}"

    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done

