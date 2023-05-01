
module load prod_util
module load prod_envir
#
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
runid=pm

flag_hpss=yes
flag_hpss=no

bkpdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/${model}/${envir}
bkpdir=/lfs/h2/emc/physics/noscrub/${USER}/verification/com/${model}/${envir}
if [ ! -d ${bkpdir} ]; then mkdir -p ${bkpdir}; fi

logdir=/lfs/h2/emc/ptmp/${USER}/com/${model}_output/${envir}
if [ ! -d ${logdir} ]; then mkdir -p ${logdir}; fi

working_dir=/lfs/h2/emc/ptmp/${USER}/${model}_script/${envir}
if [ ! -d ${working_dir} ]; then mkdir -p ${working_dir}; fi

rundir=/lfs/h2/emc/ptmp/${USER}/${model}_run/${envir}
if [ ! -d ${rundir} ]; then mkdir -p ${rundir}; fi

hpssroot=/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/Verification_nam_bufr/prod
declare -a cyc=( 00 06 12 18 )

YY0=`echo ${FIRSTDAY} | cut -c1-4`
YM0=`echo ${FIRSTDAY} | cut -c1-6`
hpssdir=${hpssroot}/${YY0}/${YM0}
hsi mkdir -p ${hpssdir}

NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    if [ ${YY} -ne ${YY0} ] | [ ${YM} -ne ${YM0} ]; then
        echo "${YY0} ${YM0} to ${YY} ${YM}, hpss mkdir"
        YY0=${YY}
        YM0=${YM}
        hpssdir=${hpssroot}/${YY}/${YM}
        hsi mkdir -p ${hpssdir}
    fi

    target_dir=${model}.${NOW}
    if [ -d  ${bkpdir}/${target_dir} ]; then
        cd ${bkpdir}/${target_dir}
        flag_check=yes
        for i in "${cyc[@]}"; do
            let t=0
            while [ ${t} -le 6 ]; do
                icnt=`printf %2.2d ${t}`
                ckfile=nam.t${i}z.prepbufr.tm${icnt}.nr
                if [ ! -s ${ckfile} ]; then
                    echo "Can not find ${ckfile}"
                    flag_check=no
                fi
                ((t++))
            done
        done  ## cycle time
        if [ "${flag_hpss}" == "yes" ] && [ "${flag_check}" == "yes" ]; then
            cd ${bkpdir}
            htar -cf ${hpssdir}/${target_dir}.tar ${target_dir}
            echo "HPSS archive ${hpssdir}/${target_dir}.tar"
        fi
        echo "Target DIR = ${bkpdir}/${target_dir}"
    else
        echo "Can not find ${bkpdir}/${target_dir}"
    fi

    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
