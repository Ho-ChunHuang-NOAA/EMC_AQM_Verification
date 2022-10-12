#!/bin/bash

declare -a file1=( pb2nc_aq.conf      pb2nc_aqmax.conf   pb2nc_cam_hi.conf  pb2nc_camtest.conf  pb2nc_pmave.conf pb2nc_aqmax1.conf  pb2nc_cam_ak.conf  pb2nc_cam_na.conf  pb2nc.conf_aq       pb2nc_pm.conf pb2nc_aqmax8.conf  pb2nc_cam.conf     pb2nc_cam_pr.conf  pb2nc.conf_nonaq    pb2nc_pmmax.conf )
declare -a file2=(point_stat_aq.conf            point_stat_aqmax8.conf  point_stat_cam.conf    point_stat_pm.conf point_stat_aqmax1.conf        point_stat_aqmax.conf   point_stat.conf_aq     point_stat_pmmax.conf point_stat_aqmax1para13.conf  point_stat_aqm.conf     point_stat_pmave.conf )

dir1=/lf/sh2/emc/vpppg/save/${USER}/METplus-4.0.0/parm/use_cases/perry
dir2=/lfs/h2/emc/physics/noscrub/Perry.Shafran/METplus-4.0.0/parm/use_cases/perry

for i in "${file1[@]}"; do
    echo ${i}
    diff ${dir1}/${i} ${dir2}/${i}
if [ 1 -eq 2 ]; then
    mv ${dir1}/${i} ${dir1}/${i}_old
    cp ${dir2}/${i} ${dir1}
    echo "after copy"
    diff ${dir1}/${i} ${dir2}/${i}
    echo "after copy"
fi
done

if [ 1 -eq 2 ]; then
for i in "${file2[@]}"; do
    echo ${i}
    diff ${dir1}/${i} ${dir2}/${i}
done
fi
