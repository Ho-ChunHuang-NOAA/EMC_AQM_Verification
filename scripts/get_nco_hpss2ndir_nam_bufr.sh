#!/bin/bash
module load prod_util
module load prod_envir
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

task_cpu='05:00:00'
envir=prod
local_envir=${envir}
model=nam

bkpdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/${model}/${envir}
bkpdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/com/${model}/${envir}
if [ ! -d ${bkpdir} ]; then mkdir -p ${bkpdir}; fi

logdir=/lfs/h2/emc/ptmp/${USER}/com/${model}_output/${envir}
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/${model}_script/${envir}
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/lfs/h2/emc/ptmp/${USER}/${model}_run/${envir}
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
    declare -a cyc=( 00 06 12 18 )
    for cycle in "${cyc[@]}"; do
        cd ${working_dir}
        job_name=ncobufr_${NOW}${cycle}
        batch_script=hpssfetch_${job_name}.sh
        if [ -e ${batch_script} ]; then /bin/rm -f ${batch_script}; fi

        logfile=${logdir}/${job_name}.out
        if [ -e ${logfile} ]; then /bin/rm -f ${logfile}; fi
cat > ${batch_script} << EOF
#!/bin/bash -l
#PBS -o ${logfile}
#PBS -e ${logfile}
#PBS -l place=shared,select=1:ncpus=1:mem=4GB
#PBS -N j${job_name}
#PBS -q dev_transfer
#PBS -A AQM-DEV
#PBS -l walltime=${task_cpu}
#PBS -l debug=true
##
##  Provide fix date daily Hysplit data processing
##

module load prod_util
   FIRSTDAY=${NOW}
   LASTDAY=${NOW}
   hpssprod=${hpssprod}
   bkpdir=${bkpdir}
   rundir=${rundir}
   fhdr=${fhdr}
   model=${model}
   declare -a cyc=( ${cycle} )
EOF
      ##
      ##  Creat part 2 script : exact wording of scripts
      ##
cat > ${batch_script}.add  << 'EOF'

## source ~/.bashrc

   cd ${rundir}


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
        qsub < ${batch_script}
        ## bash ${batch_script} > ${logfile} 2>&1 &
        echo "working_dir=${working_dir}"
        echo "run_scrpt = ${working_dir}/${batch_script}"
        echo "log_file  = ${logfile}"
    done
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
