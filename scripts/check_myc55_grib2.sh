#!/bin/bash
module load prod_util
module load prod_envir
MSG="$0 EXP [prod|para|...] START_DATE END_DATE"
if [ $# -lt 3 ]; then
    echo ${MSG}
    exit
fi
##
## set -x
## 
hname=`hostname`
hl=`hostname | cut -c1-1`
if [ -s prod_info_list ]; then /bin/rm -f prod_info_list; fi
cat /lfs/h1/ops/prod/config/prodmachinefile > prod_info_list
info_line=`head -n 1 prod_info_list`
echo ${info_line}
prodinfo=$(echo ${info_line} | awk -F":" '{print $1}')
if [ "${prodinfo}" == "primary" ]; then
    prodmachine=$(echo ${info_line} | awk -F":" '{print $2}')
else
    info_line=`head -n 2 prod_info_list | tail -n1`
    echo ${info_line}
    prodinfo=$(echo ${info_line} | awk -F":" '{print $1}')
    if [ "${prodinfo}" == "primary" ]; then
        prodmachine=$(echo ${info_line} | awk -F":" '{print $2}')
    else
	prodmachine="unknown"
    fi
fi
pm=`echo ${prodmachine} | cut -c1-1`
if [ -s prod_info_list ]; then /bin/rm -f prod_info_list; fi
exp=$1
export FIRSTDAY=$2
export LASTDAY=$3
#
# Find EXP Name if envir="EXP"_bc
#
if [[ "${exp}" == *"_bc"* ]]; then
    length=${#exp}
    cutlim=$(expr ${length} - 3)
    EXP=`echo ${exp} | cut -c1-${cutlim}`
    Bias_Corr='_bc'
else
    EXP=${exp}
    Bias_Corr=''
fi

if [ "${EXP}" == "prod" ]; then
    gridspec=148
else
    gridspec=793
fi
comout=/lfs/h2/emc/physics/noscrub/${USER}/verification/aqm/${EXP}
if [ ! -d ${comout} ]; then
    echo "Can not find ${comout}"
    exit
fi
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    #
    # Check grib2 files are all ready to be verified
    #
    from_dir=${comout}/cs.${NOW}
    if [ ! -d ${from_dir} ]; then
        echo "Can not find ${from_dir}"
	continue
    else
        echo "Check ${from_dir}"
    fi
    let tend=72
    declare -a cycle_opt=( 06 12 )
    declare -a ftype=( pm25${Bias_Corr} awpozcon${Bias_Corr} )
    for cyc_sel in "${cycle_opt[@]}"; do
        i=t${cyc_sel}z
        declare -a cpflist=( aqm.${i}.ave_24hr_pm25${Bias_Corr}.${gridspec}.grib2 aqm.${i}.max_1hr_o3${Bias_Corr}.${gridspec}.grib2 aqm.${i}.max_1hr_pm25${Bias_Corr}.${gridspec}.grib2 aqm.${i}.max_8hr_o3${Bias_Corr}.${gridspec}.grib2 )
        
        for j in "${cpflist[@]}"; do
            if [ ! -s ${from_dir}/${j} ]; then
                echo "Can not find ${from_dir}/${j}"
            fi
        done
        for k in "${ftype[@]}"; do
            let j=1
            while [ ${j} -le ${tend} ]; do
                ## jpnt=`printf %3.3d ${j}`
                jpnt=`printf %2.2d ${j}`
                cpfile=${from_dir}/aqm.${i}.${k}.f${jpnt}.${gridspec}.grib2
                if [ ! -s ${cpfile} ]; then
                    echo " Can not find ${cpfile}"
                fi
                ((j++))
            done  ## hours
        done  ## file type
    done  ## cycle time
    #
    # END Check grib2 files
    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done
exit
