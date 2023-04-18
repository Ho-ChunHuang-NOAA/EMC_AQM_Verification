import sys
import datetime
import shutil
import os
import subprocess
import fnmatch

user=os.environ['USER']
current_dir=os.getcwd()
ifile="/u/ho-chun.huang/versions/run.ver"
rfile=open(ifile, 'r')
for line in rfile:
    nfind=line.find("export")
    if nfind != -1:
        line=line.rstrip("\n")
        ver=line.split("=")
        ver_name=ver[0].split(" ")
        if ver_name[1] == "envvar_ver":
            envvar_ver=ver[1]
        if ver_name[1] == "PrgEnv_intel_ver":
            PrgEnv_intel_ver=ver[1]
        if ver_name[1] == "intel_ver":
            intel_ver=ver[1]
        if ver_name[1] == "craype_ver":
            craype_ver=ver[1]
        if ver_name[1] == "cray_mpich_ver":
            cray_mpich_ver=ver[1]
        if ver_name[1] == "python_ver":
            python_ver=ver[1]
        if ver_name[1] == "netcdf_ver":
            netcdf_ver=ver[1]

if len(sys.argv) < 3:
    print("you must provide 3 arguments for start_date end_date")
    sys.exit()
else:
    envir = sys.argv[1]
    start_date = sys.argv[2]
    end_date = sys.argv[3]

working_dir="/lfs/h2/emc/stmp/"+user
if not os.path.exists(working_dir):
    os.mkdir(working_dir)

stmp_dir="/lfs/h2/emc/stmp/"+user
if not os.path.exists(stmp_dir):
    os.mkdir(stmp_dir)
ptmp_dir="/lfs/h2/emc/ptmp/"+user
if not os.path.exists(ptmp_dir):
    os.mkdir(ptmp_dir)
log_dir=ptmp_dir+"/batch_logs"

if not os.path.exists(log_dir):
    os.mkdir(log_dir)

model="aqm"
hpss_root="/5year/NCEPDEV/emc-naqfc/Ho-Chun.Huang/Verification_Grib2/"+envir
from_bkp_dir="/lfs/h2/emc/physics/noscrub/ho-chun.huang/verification/aqm/"+envir
to_bkp_dir="/lfs/h2/emc/vpppg/noscrub/ho-chun.huang/verification/aqm/"+envir
from_dir_id="cs"
to_dir_id="aqm"

sdate = datetime.datetime(int(start_date[0:4]), int(start_date[4:6]), int(start_date[6:]), 00)
edate = datetime.datetime(int(end_date[0:4]), int(end_date[4:6]), int(end_date[6:]), 23)
date_inc = datetime.timedelta(hours=24)
hour_inc = datetime.timedelta(hours=1)

Y_date_format = "%Y"
YM_date_format = "%Y%m"
YMD_date_format = "%Y%m%d"
MD_date_format = "%m%d"
H_date_format = "%H"

working_dir=stmp_dir+"/hpss_f02Tf03"
if not os.path.exists(working_dir):
    os.mkdir(working_dir)
os.chdir(working_dir)

YY0=sdate.strftime(Y_date_format)
YM0=sdate.strftime(YM_date_format)
hpssdir=hpss_root+"/"+YY0+"/"+YM0
cmd="hsi mkdir -p "+hpssdir
subprocess.call([cmd], shell=True)

date=sdate
while date <= edate:
    YY=date.strftime(Y_date_format)
    YM=date.strftime(YM_date_format)
    if YY != YY0 or YM != YM0:
        YY0=YY
        YM0=YM
        hpssdir=hpss_root+"/"+YY0+"/"+YM0
        cmd="hsi mkdir -p "+hpssdir
        subprocess.call([cmd], shell=True)
    jobname="f02tf03_grib2_"+date.strftime(YMD_date_format)
    transfer_file=os.path.join(os.getcwd(),jobname+".sh")
    if os.path.exists(transfer_file):
        os.remove(transfer_file)
    logfile=log_dir+"/"+jobname+".log"
    if os.path.exists(logfile):
        os.remove(logfile)
    with open(transfer_file, 'a') as sh:
        sh.write("#!/bin/bash\n")
        sh.write("#PBS -o "+logfile+"\n")
        sh.write("#PBS -e "+logfile+"\n")
        sh.write("#PBS -l place=shared,select=1:ncpus=1:mem=5GB\n")
        sh.write("#PBS -N j"+jobname+"\n")
        sh.write("#PBS -q dev_transfer\n")
        sh.write("#PBS -A AQM-DEV\n")
        sh.write("#PBS -l walltime=00:30:00\n")
        sh.write("\n")
        ## sh.write("module load envvar/"+envvar_ver+"\n")
        ## sh.write("module load PrgEnv-intel/"+PrgEnv_intel_ver+"\n")
        ## sh.write("module load intel/"+intel_ver+"\n")
        ## sh.write("module load craype/"+craype_ver+"\n")
        ## sh.write("module load cray-mpich/"+cray_mpich_ver+"\n")
        sh.write("export OMP_NUM_THREADS=1\n")
        sh.write("##\n")
        sh.write("set -x\n")
        sh.write("\n")
        sh.write("declare -a ftype=( pm25 awpozcon pm25_bc awpozcon_bc )\n")
        sh.write("declare -a cycle=( t06z t12z )\n")
        sh.write("let tend=72\n")
        sh.write("\n")
        sh.write("    from_dir="+from_bkp_dir+"/"+from_dir_id+"."+date.strftime(YMD_date_format)+"\n")
        sh.write("    if [ ! -d ${from_dir} ]; then\n")
        sh.write("        echo \"Can not find ${from_dir}\"\n")
        sh.write("        exit\n")
        sh.write("    fi\n")
        sh.write("    to_dir="+to_bkp_dir+"/"+to_dir_id+"."+date.strftime(YMD_date_format)+"\n")
        sh.write("    if [ ! -d ${to_dir} ]; then mkdir -p ${to_dir}; fi\n")
        sh.write("    cp -p ${from_dir}/* ${to_dir}\n")
        sh.write("    cd ${to_dir}\n")
        sh.write("    for i in \"${cycle[@]}\"; do\n")
        sh.write("        for k in \"${ftype[@]}\"; do\n")
        sh.write("            let j=1\n")
        sh.write("            while [ ${j} -le ${tend} ]; do\n")
        sh.write("                hh2=`printf %2.2d ${j}`\n")
        sh.write("                hh3=`printf %3.3d ${j}`\n")
        sh.write("                old_file=aqm.${i}.${k}.f${hh2}.793.grib2\n")
        sh.write("                if [ -s ${old+file} ]; then\n")
        sh.write("                    new_file=aqm.${i}.${k}.f${hh3}.793.grib2\n")
        sh.write("                    mv ${old_file} ${new_file}\n")
        sh.write("                fi\n")
        sh.write("                ((j++))\n")
        sh.write("            done\n")
        sh.write("        done\n")
        sh.write("    done\n")
        sh.write("\n")
        sh.write("   cd "+from_bkp_dir+"\n")
        sh.write("   htar -cf "+hpssdir+"/"+to_dir_id+"."+date.strftime(YMD_date_format)+".tar "+to_dir_id+"."+date.strftime(YMD_date_format)+"\n")
        sh.write("\n")
        sh.write("exit\n")
    print("SCRIPT = "+transfer_file)
    print("LOG    = "+logfile)
    subprocess.call(["cat "+transfer_file+" | qsub"], shell=True)
    date = date + date_inc
