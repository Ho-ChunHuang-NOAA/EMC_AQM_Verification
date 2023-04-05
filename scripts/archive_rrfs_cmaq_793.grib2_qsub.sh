#!/bin/bash
source /u/ho-chun.huang/versions/run.ver
module load prod_util
module load prod_envir
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
expid=`echo ${out_envir} | cut -c4-6`
expid=aqm   # after 4/1/2023 directory will be changed into aqm.yyyymmdd

data_in=/lfs/h2/emc/ptmp/ho-chun.huang/data/RRFSCMAQ/${in_envir}
data_in=/lfs/h2/emc/ptmp/jianping.huang/emc.para/com/aqm/v7.0/aqm.v7.0.${expid}
if [ ! -d ${data_in}.${FIRSTDAY} ]; then
    echo "Can not find ${data_in}.${FIRSTDAY}, program exit"
    exit
fi

working_dir=/lfs/h2/emc/ptmp/${USER}/rrfs_793_grib2_qsub_scripts
log_dir=/lfs/h2/emc/ptmp/${USER}/rrfs_793_grib2_logs
mkdir -p ${working_dir} ${log_dir}

hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/RRFS_postprd_grib2/${in_envir}
outdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/RRFS-CMAQ


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
    task_cpu='04:59:00'
    job_name=daily_bkp_rrfs_793_${NOW}
    batch_script=${job_name}.sh
    if [ -e ${batch_script} ]; then /bin/rm -f ${batch_script}; fi

    logfile=${log_dir}/${job_name}.out
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

##
##  Provide fix date daily Hysplit data processing
##
    ## module load prod_util
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
    odir=${outdir}/${out_envir}/aqm.${NOW}/postprd
    mkdir -p ${odir}/POST_STAT
    for i in "${cyc[@]}"; do
        idir=${data_in}.${NOW}/${i}
	if [ -d ${idir} ]; then
            cp -p ${idir}/aqm.t${i}z.all.f*.793.grib2 ${odir}
            ## cp -p ${idir}/*prslevf* ${odir}
            if [ -d ${idir}/POST_STAT ]; then cp -pr ${idir}/POST_STAT/*  ${odir}/POST_STAT; fi
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
       echo "qsub_script=${working_dir}/${batch_script}"
       echo "logfile=${logfile}"

    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done

