#!/bin/bash
#BSUB -J xxJOB
#BSUB -o xxOUTLOG
#BSUB -e xxERRLOG
#BSUB -q "dev2"
#BSUB -P CMAQ-T2O
#BSUB -R "rusage[mem=3000]"
#BSUB -n 1
#BSUB -W 04:00
#BSUB -R affinity[core(1)]

module load prod_util/1.1.6
envir=$1
EXP=`echo ${envir} | tr a-z A-Z`
echo "experiment run is ${envir} ${envir1}"

set -x
TODAY=`date +%Y%m%d`

export DATE=$2

data_dir=/gpfs/dell2/emc/verification/noscrub/Ho-Chun.Huang/metplus_aq/stat/aqm/${DATE}
if [ ! -d ${data_dir} ]; then
    echo "Can not find ${data_dir}"
    exit
fi
declare -a filelist=( ${EXP}_AQ_${DATE}.stat ${EXP}_BC_AQMAX_${DATE}.stat ${EXP}_BC_PMMAX_${DATE}.stat ${EXP}_PMMAX_${DATE}.stat ${EXP}_AQMAX_${DATE}.stat ${EXP}_BC_PM_${DATE}.stat ${EXP}_PM_${DATE}.stat ${EXP}_BC_AQ_${DATE}.stat ${EXP}_BC_PMAVE_${DATE}.stat ${EXP}_PMAVE_${DATE}.stat )

let num_check=72
let ncheck=0
## while [ ${ncheck} -lt 96 ]; do
while [ ${ncheck} -lt ${num_check} ]; do
    flag_send_to_AWS=yes
    for i in "${filelist[@]}"; do
        if [ ! -s ${data_dir}/${i} ]; then
            echo "Can not find ${data_dir}/${i}"
            flag_send_to_AWS=no
            break
        fi
    done
    if [ "${flag_send_to_AWS}" == "yes" ]; then break; fi
    sleep 10m
    echo ${ncheck}
    ((ncheck++))
done
if [ "${flag_send_to_AWS}" == "no" ]; then
    echo "Do not have all files ready to be upload to the AWS database"
    exit
fi
#
# Load statistic to AWS MET database
# Can interfere with others hourly prod, prodbc and max prod_prod_bc for removing the LOAD_DIR
#
script_dir=/gpfs/dell2/emc/modeling/noscrub/Ho-Chun.Huang/METviewer_AWS
script_name=cron_load_g2o_met_verf_o3pm.sh
bash ${script_dir}/${script_name} ${envir} ${DATE} ${DATE}
echo "Load ${script_name} ${envir} ${DATE} ${DATE}"

exit
