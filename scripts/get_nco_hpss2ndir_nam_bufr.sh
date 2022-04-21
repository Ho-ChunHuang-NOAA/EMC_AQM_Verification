
module load prod_util/1.1.6
module load prod_envir/1.1.0
module load HPSS/5.0.2.5
#
#  HPSS tar is also handled by cronjob at
#  ~/cronjob/transfer_daily_hysplit_smoke_ncopara.sh
#

MSG="$0 FIRSTDAY LASTDAY"
## set -x
if [ $# -lt 2 ]; then
   echo ${MSG}
   exit
else
   FIRSTDAY=$1
   LASTDAY=$2
fi

task_cpu='05:00'
envir=prod
local_envir=${envir}
model=nam
runid=pm

bkpdir=/gpfs/dell2/emc/modeling/noscrub/Ho-Chun.Huang/verification/${model}/${envir}
bkpdir=/gpfs/dell2/emc/modeling/noscrub/${USER}/verification/com/${model}/${envir}
if [ ! -d ${bkpdir} ]; then mkdir -p ${bkpdir}; fi

logdir=/gpfs/dell2/ptmp/Ho-Chun.Huang/com/${model}_output/${envir}
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/gpfs/dell2/ptmp/Ho-Chun.Huang/${model}_script/${envir}
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/gpfs/dell2/ptmp/Ho-Chun.Huang/${model}_run/${envir}
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

hpssprod=/NCEPPROD/hpssprod/runhistory

SWITCH_FCSTHR=20210721
SWITCH_DAY1=20190820
SWITCH_DAY2=20200226
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    if [ ${NOW} -le ${SWITCH_DAY1} ]; then
       fhdr=com2_${model}_prod_${model}
    elif [ ${NOW} -le ${SWITCH_DAY2} ]; then
       fhdr=gpfs_dell1_nco_ops_com_${model}_prod_${model}
    else
       fhdr=com_${model}_prod_${model}
    fi
    cd ${working_dir}
    job_name=ncobufr_${NOW}
    batch_script=hpssfetch_${job_name}.sh
    if [ -e ${batch_script} ]; then /bin/rm -f ${batch_script}; fi

    logfile=${logdir}/${job_name}.out
    if [ -e ${logfile} ]; then /bin/rm -f ${logfile}; fi
    hpssuser=/5year/NCEPDEV/emc-naqfc/${USER}/Verification_Grib2/prod
    hsi mkdir -p ${hpssuser}
cat > ${batch_script} << EOF
#!/bin/bash -l
#BSUB -o ${logfile}
#BSUB -e ${logfile}
#BSUB -n 1
#BSUB -J j${job_name}
#BSUB -q "dev_transfer"
#BSUB -P CMAQ-T2O
#BSUB -W ${task_cpu}
#BSUB -R affinity[core(1)]
#BSUB -M 100
##
##  Provide fix date daily Hysplit data processing
##

module load prod_util/1.1.6
module load HPSS/5.0.2.5
   FIRSTDAY=${NOW}
   LASTDAY=${NOW}
   hpssprod=${hpssprod}
   bkpdir=${bkpdir}
   rundir=${rundir}
   fhdr=${fhdr}
   hpssuser=${hpssuser}
   model=${model}
EOF
      ##
      ##  Creat part 2 script : exact wording of scripts
      ##
cat > ${batch_script}.add  << 'EOF'

## source ~/.bashrc

   cd ${rundir}

   declare -a cyc=( 00 06 12 18 )

   NOW=${FIRSTDAY}
   while [ ${NOW} -le ${LASTDAY} ]; do
       YY=`echo ${NOW} | cut -c1-4`
       YM=`echo ${NOW} | cut -c1-6`
       target_dir=${model}.${NOW}
       mkdir -p ${bkpdir}/${target_dir}
       mkdir -p ${rundir}/${target_dir}
       cd ${rundir}/${target_dir}

       for i in "${cyc[@]}"; do
           tarfile=${hpssprod}/rh${YY}/${YM}/${NOW}/${fhdr}.${NOW}${i}.bufr.tar
           if [ -s bufr_tlist_${NOW}_${i} ]; then /bin/rm -f bufr_tlist_${NOW}_${i}; fi
           echo "./nam.t${i}z.prepbufr.tm00.nr" > bufr_tlist_${NOW}_${i}
           echo "./nam.t${i}z.prepbufr.tm01.nr" >> bufr_tlist_${NOW}_${i}
           echo "./nam.t${i}z.prepbufr.tm02.nr" >> bufr_tlist_${NOW}_${i}
           echo "./nam.t${i}z.prepbufr.tm03.nr" >> bufr_tlist_${NOW}_${i}
           echo "./nam.t${i}z.prepbufr.tm04.nr" >> bufr_tlist_${NOW}_${i}
           echo "./nam.t${i}z.prepbufr.tm05.nr" >> bufr_tlist_${NOW}_${i}
           echo "./nam.t${i}z.prepbufr.tm06.nr" >> bufr_tlist_${NOW}_${i}
           htar -xf ${tarfile} -L bufr_tlist_${NOW}_${i}
           cp -p nam.t${i}z.prepbufr.tm*.nr ${bkpdir}/${target_dir}
           echo "${NOW}_${i}"
       done  ## cycle time
       echo "Target DIR = ${bkpdir}/${target_dir}"
       ## hpssdir=${hpssuser}/${YY}/${YM}
       ## cd ${bkpdir}
       ## htar -cf ${hpssdir}/${target_dir}.tar ${target_dir}
       ## echo "HPSS archive ${hpssdir}/${target_dir}.tar"
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
    ## bsub < ${batch_script}
    bash ${batch_script} > ${logfile} 2>&1 &
    echo "working_dir=${working_dir}"
    echo "run_scrpt = ${working_dir}/${batch_script}"
    echo "log_file  = ${logfile}"
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
