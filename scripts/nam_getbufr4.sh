#!/bin/ksh
module load prod_util/1.1.6
                                                                                      
set -x

#
# ~ 08/20/2019
# com2_nam_prod_nam.${NOW}${CYC}.bufr.tar
# 08/21/2019 -  02/26/2019
# gpfs_dell1_nco_ops_com_nam_prod_nam.${NOW}${CYC}.bufr.tar
# 02/27/2020 - present
# com_nam_prod_nam.${NOW}${CYC}.bufr.tar
#

STARTDATE=2020072700
ENDDATE=2020080118
DATE=$STARTDATE

while [ $DATE -le $ENDDATE ]; do

echo $DATE > curdate
DAY=`cut -c 1-8 curdate`
YEAR=`cut -c 1-4 curdate`
MONTH=`cut -c 1-6 curdate`
HOUR=`cut -c 9-10 curdate`

mkdir -p /gpfs/dell2/emc/modeling/noscrub/${USER}/com/nam/prod/nam.${DAY}
#cd /meso/noscrub/${USER}/com/nam/prod/nam.${DAY}

mkdir -p  /gpfs/dell2/ptmp/${USER}/bufrtmp/${DAY}
cd /gpfs/dell2/ptmp/${USER}/bufrtmp/${DAY}

htar -xvf /NCEPPROD/hpssprod/runhistory/rh${YEAR}/${MONTH}/${DAY}/com_nam_prod_nam.${DATE}.bufr.tar ./nam.t${HOUR}z.prepbufr.tm00.nr ./nam.t${HOUR}z.prepbufr.tm01.nr ./nam.t${HOUR}z.prepbufr.tm02.nr ./nam.t${HOUR}z.prepbufr.tm03.nr ./nam.t${HOUR}z.prepbufr.tm04.nr ./nam.t${HOUR}z.prepbufr.tm05.nr ./nam.t${HOUR}z.prepbufr.tm06.nr
##tar -xvf com2_nam_prod_nam.${DATE}.bufr.tar

for hr in 00 01 02 03 04 05 06
#for hr in 72
do

cp nam.t${HOUR}z.prepbufr.tm${hr}.nr /gpfs/dell2/emc/verification/noscrub/${USER}/com/nam/prod/nam.${DAY}
rm -f nam.t${HOUR}z.prepbufr.tm${hr}.nr

done

## DATE=`/gpfs/dell1/nco/oe`s/nwprod/prod_util.v1.1.2/exec/ips/ndate +06 $DATE`
DATE=$(${NDATE} +06 ${DATE})

done
exit
