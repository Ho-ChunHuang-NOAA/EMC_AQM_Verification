#!/bin/sh
MSG="$0 FIRSTDAY LASTDAY"
## set -x
if [ $# -lt 2 ]; then
   echo ${MSG}
   exit
else
   FIRSTDAY=$1
   LASTDAY=$2
fi

module use /scratch2/NCEPDEV/nwprod/hpc-stack/libs/hpc-stack/modulefiles/stack
module load hpc/1.1.0  hpc-intel/18.0.5.274
module load prod_util/1.2.2

module use -a /contrib/anaconda/modulefiles
module load intel/2022.1.2
module load anaconda/latest
module use -a /contrib/met/modulefiles/
module load met/11.0.1-rc1

logdir=/scratch1/NCEPDEV/stmp2/Ho-Chun.Huang/run_log
mkdir -p ${logdir}

input_dir=/scratch2/NCEPDEV/naqfc/Ho-Chun.Huang/noscrub/dcom
output_dir=/scratch2/NCEPDEV/naqfc/Ho-Chun.Huang/noscrub/dcom_ascii2nc_airnow
if [ ! -d ${output_dir} ]; then mkdir -p  ${output_dir}; fi

ASCII2NC_INPUT_DIR=${idir}
ASCII2NC_INPUT_TEMPLATE={valid?fmt=%Y%m%d}/HourlyAQObs_{valid?fmt=%Y%m%d%H}.dat
ASCII2NC_INPUT_TEMPLATE={valid?fmt=%Y%m%d}/daily_data_v2.dat
ASCII2NC_OUTPUT_DIR=${odir}
ASCII2NC_OUTPUT_TEMPLATE={valid?fmt=%Y%m%d}/airnow_hourly_{valid?fmt=%Y%m%d%H}.nc
ASCII2NC_OUTPUT_TEMPLATE={valid?fmt=%Y%m%d}/airnow_daily_{valid?fmt=%Y%m%d}.nc
ASCII2NC_SKIP_IF_OUTPUT_EXISTS=False
ASCII2NC_FILE_WINDOW_BEGIN=
ASCII2NC_FILE_WINDOW_END=
ASCII2NC_WINDOW_BEGIN=
ASCII2NC_WINDOW_END=
ASCII2NC_INPUT_FORMAT="airnowhourlyaqobs"
ASCII2NC_INPUT_FORMAT="airnowdaily_v2"
NOW=${FIRSTDAY}
while [ ${NOW} -le ${LASTDAY} ]; do
    YY=`echo ${NOW} | cut -c1-4`
    YM=`echo ${NOW} | cut -c1-6`
    idir=${input_dir}/${NOW}/airnow
    if [ -s ${idir}/Monitoring_Site_Locations_V2.dat ]; then
       export MET_AIRNOW_STATIONS=${idir}/Monitoring_Site_Locations_V2.dat
    else
       echo "WARNING :: Can not find ${idir}/Monitoring_Site_Locations_V2.dat"
    fi
    odir=/scratch2/NCEPDEV/naqfc/Ho-Chun.Huang/noscrub/dcom_ascii2nc_airnow/${NOW}
    if [ ! -d ${odir} ]; then mkdir -p  ${odir}; fi
    let t=0
    let tend=23
    while [ ${t} -le ${tend} ]; do
        icnt=`printf %2.2d ${t}`
        logfile=${logdir}/ascii2nc_airnow_hourly_${NOW}${icnt}.log
        ifile=HourlyAQObs_${NOW}${icnt}.dat
        ofile=airnow_hourly_${NOW}${icnt}.nc
        if [ -s ${idir}/${ifile} ]; then
            ascii2nc ${idir}/${ifile} ${odir}/${ofile} -format "airnowhourlyaqobs" > ${logfile} 2>&1 &
        else
            echo "Can not find ${idir}/${ifile}"
        fi
        ((t++))
    done
    ifile=daily_data_v2.dat
    ofile=airnow_daily_${NOW}.nc
    logfile=${logdir}/ascii2nc_airnow_daily_${NOW}.log
    if [ -s ${idir}/${ifile} ]; then
        ascii2nc ${idir}/${ifile} ${odir}/${ofile} -format "airnowdaily_v2" > ${logfile} 2>&1 &
    else
        echo "Can not find ${idir}/${ifile}"
    fi

    cdate=${NOW}"00"
    NOW=$(${NDATE} +24 ${cdate}| cut -c1-8)
done

exit
