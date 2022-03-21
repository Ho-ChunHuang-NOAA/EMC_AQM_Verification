#!/bin/sh
#
# /naqfc/noscrub ==> /gpfs/${phase12_id}d2/emc/naqfc/noscrub
# /naqfc2/noscrub ==> /gpfs/${phase12_id}d3/emc/naqfc/noscrub
# /meso/noscrub ==> /gpfs/${phase12_id}d1/emc/meso/noscrub
# /meso2/noscrub ==> /gpfs/${phase12_id}d3/emc/meso/noscrub
# /naqfc/save ==> /gpfs/${phase12_id}d2/emc/naqfc/save
# /meso/save ==> /gpfs/${phase12_id}d1/emc/meso/save
if [ 1 -eq 2 ]; then
module load imagemagick/6.9.9-25
module load prod_util/1.1.5
module load GrADS/2.2.0
module load prod_envir/1.1.0
hl=`hostname | cut -c1`
if [ "${hl}" == "v" ]; then
  phase12_id='g'
else
  phase12_id='t'
fi
fi
#
ls > tlist
count=0
while read line
do
  shfile[$count]=$(echo $line | awk '{print $1}')
  ((count++))
done<tlist

old_ver='module load GrADS'
new_ver='module load GrADS/2.2.0'
old_ver='\-q transfer'
new_ver='\-q "dev_transfer"'
old_ver='#BSUB \-R span\[ptile=1\]'
new_ver='####BSUB \-R span\[ptile=1\]'
old_ver='\-R affinity\[core\]'
new_ver='\-R affinity\[core(1)\]'
old_ver='\-R rusage\[mem=200\]'
new_ver='\-M 100'
old_ver='gif'
new_ver='png'
old_ver='=\/meso'
new_ver='=\/gpfs/${phase12_id}d1\/emc\/meso'
old_ver='\/${project}'
new_ver='${project}'
old_ver='\.gif'
new_ver='\.${figure_type}'
old_ver='flag_fect_gif'
new_ver='flag_fect_fig'
old_ver='png'
new_ver='gif'
old_ver='grads -blc'
new_ver='grads -d Cairo -h GD -blc'
old_ver='module load idl'
new_ver='module load idl/8.6.1'
old_ver='\/naqfc\/save'
new_ver='\/gpfs\/dell2\/emc\/verification\/save'
old_ver='\/naqfc\/noscrub'
new_ver='\/gpfs/${phase12_id}d2\/emc\/naqfc'
old_ver='/ptmpp1'
new_ver='/gpfs/dell2/ptmp'
old_ver='\/meso\/noscrub'
new_ver='\/gpfs/${phase12_id}d1\/emc\/meso\/noscrub'
old_ver='\/com2'
new_ver='${COMROOTp2}'
old_ver='\/nwprod\/util\/exec\/ndate'
new_ver='${NDATE}'
old_ver='\/naqfc\/save\/${USER}\/WEB\/base'
new_ver='\/gpfs\/dell2\/emc\/verification\/save/\/${USER}\/WEB\/base'
old_ver='wcoss\.run\.cmaq2_pm\.sh'
new_ver='wcoss\.run\.cmaq2_pm_png\.sh'
old_ver='gs_dir=`pwd`'
new_ver='gs_dir=\/gpfs\/dell2\/emc\/verification\/save\/${USER}\/plot\/cmaq'
old_ver='\$ndate'
new_ver='\${NDATE}'
old_ver='module load hpss'
new_ver='module load HPSS/5.0.2.5'
old_ver='=\/meso2'
old_ver='=\/meso2\/noscrub'
new_ver='=\/gpfs\/dell2\/emc\/modeling\/noscrub'
old_ver='\/naqfc\/save'
new_ver='=\/gpfs\/dell2\/emc\/modeling\/noscrub'
old_ver='=\/gpfs/${phase12_id}d3\/emc\/meso\/noscrub'
old_ver='=\/gpfs/${machine_id}d2\/emc\/meso\/noscrub'
old_ver='=\/gpfs/${machine_id}d3\/emc\/naqfc\/noscrub'
new_ver='=\/gpfs\/dell2\/emc\/modeling\/noscrub'
old_ver='\/com2\/'
new_ver='\/com\/'
old_ver='${DCOMROOT}\/us007003'
new_ver='${DCOMROOT}'
old_ver='\/naqfc\/save\/${USER}\/IDL\/bluesky_fire'
new_ver='\/gpfs\/dell2\/emc\/modeling\/save\/${USER}\/IDL\/bluesky_fire'
old_ver='module load prod_util'
old_ver='module load prod_util/1.1.0'
new_ver='module load prod_util/1.1.3'
old_ver='module load prod_envir/1.0.2'
new_ver='module load prod_envir/1.0.3'
old_ver='\/naqfc\/save\/${USER}\/grid2grid\/conc'
new_ver='\/gpfs\/dell2\/emc\/verification\/noscrub\/${USER}\/gyre_hysplit_plot\/conc'
old_ver='\/naqfc\/save\/${USER}\/grid2grid\/aod'
new_ver='\/gpfs\/dell2\/emc\/verification\/noscrub\/${USER}\/gyre_hysplit_plot\/aod'
old_ver='\/naqfc\/save\/${USER}\/grid2grid\/verf_g2g.v4.0.0'
new_ver='\/gpfs\/dell2\/emc\/modeling\/noscrub\/${USER}\/MET_verif\/verf_g2g.v4.0.0'
old_ver='\/naqfc\/save\/Ho-Chun.Huang\/grid2grid\/conc'
new_ver='\/gpfs\/dell2\/emc\/verification\/noscrub\/${USER}\/gyre_hysplit_plot\/conc'
old_ver='/gpfs/gd1/emc/meso/noscrub/Ho-Chun.Huang'
old_ver='/meso2/noscrub/${USER}/dcom'
old_ver='/meso/noscrub/${USER}/dcom'
old_ver='/gpfs/dell2/emc/modeling/noscrub/${USER}/dcom/us007003'
new_ver='/gpfs/dell2/emc/modeling/noscrub/${USER}/dcom'
old_ver='\/dcom\/us007003'
new_ver='${DCOMROOT}'
old_ver='dcom_us007003'
new_ver='dcom'
old_ver='=/stmpp2'
new_ver='=/gpfs/dell2/stmp'
old_ver='/ptmpp1'
new_ver='/gpfs/dell2/ptmp'
old_ver='\/gpfs\/td1\/emc\/meso\/noscrub'
old_ver='\/meso2\/noscrub\/${USER}\/com2'
new_ver='\/gpfs\/dell2\/emc\/modeling\/noscrub/com'
old_ver='\/gpfs/${phase12_id}d3\/emc\/meso\/noscrub\/${USER}'
new_ver='\/gpfs\/dell2\/emc\/modeling\/noscrub\/${USER}'
old_ver='${COMROOTp2}\/hysplit'
new_ver='${COMROOT}\/hysplit'
old_ver='\/gpfs/${phase12_id}d1\/emc\/meso\/noscrub\/${USER}'
new_ver='\/gpfs\/dell2\/emc\/modeling\/noscrub\/${USER}'
old_ver='\/stmpp1'
old_ver='\/stmpp2'
new_ver='\/gpfs/dell2/stmp'
old_ver='\/naqfc\/save\/${USER}\/WEB\/base'
new_ver='\/gpfs\/dell2\/emc\/verification\/save/\/${USER}\/WEB\/base'
old_ver='\/meso\/noscrub\/${USER}\/com'
old_ver='\/meso2\/noscrub\/${USER}\/com2'
new_ver='\/gpfs\/dell2\/emc\/modeling\/noscrub\/${USER}\/com'
old_ver='\/naqfc\/noscrub\/${USER}\/aod_smoke\/fire'
new_ver='\/gpfs\/dell2\/emc\/verification\/noscrub\/${USER}\/gyre_hysplit_plot\/fire'
old_ver='\/naqfc2\/noscrub'
new_ver='\/gpfs\/dell2\/emc\/modeling\/noscrub'
old_ver='=\/${ptmploc}'
new_ver='=\/gpfs/dell2/ptmp'
old_ver='export ptmploc=ptmpp2'
new_ver='export ptmploc=\/gpfs/dell2/ptmp'
old_ver='=${ptmploc}'
new_ver='=\/gpfs/dell2/ptmp'
old_ver='=\/${metloc}'
new_ver='=${COMROOT}'
old_ver='=\/${projloc}'
new_ver='=\/gpfs\/dell2\/emc\/modeling'
old_ver='=\/${archloc}'
new_ver='=\/gpfs\/dell2\/emc\/modeling'
old_ver='\/naqfc\/noscrub'
new_ver='\/gpfs\/dell2\/emc\/modeling\/noscrub'
old_ver='\/${comloc}'
new_ver='\/com'
old_ver='\/com2\/'
new_ver='\/com\/'
old_ver='=\/com\/'
new_ver='=${COMROOT}\/'
old_ver='\/naqfc\/save\/${USER}\/IDL\/hysplit_fire'
new_ver='\/gpfs\/dell2\/emc\/modeling\/save\/${USER}\/IDL\/hysplit_fire'
old_ver='\/naqfc\/save\/${USER}\/IDL\/bluesky_fire'
new_ver='\/gpfs\/dell2\/emc\/modeling\/save\/${USER}\/IDL\/bluesky_fire'
old_ver='\/naqfc\/save\/${USER}\/plot\/cmaq'
new_ver='\/gpfs\/dell2\/emc\/verification\/save\/${USER}\/plot\/cmaq'
old_ver='\/\/${USER}'
new_ver='\/${USER}'
old_ver='${COMROOTp2}'
new_ver='${COMROOT}'
old_ver='\/gpfs\/dell2\/emc\/verification\/save\/${USER}\/plot'
new_ver='\/gpfs\/dell2\/emc\/modeling\/save\/${USER}\/plot'
old_ver='batch\.logs'
new_ver='batch_logs'
old_ver='"dev2_transfer"'
new_ver='"dev_transfer"'
old_ver='ips\/18.0.1.163'
new_ver='ips\/18.0.5.274'
old_ver='prod_util\/1.1.4'
new_ver='prod_util\/1.1.6'
old_ver='Ho-Chun.Huang'
new_ver='${USER}'
old_ver='\/gpfs\/dell1\/ptmp\/${USER}\/batch_logs'
new_ver='\/gpfs\/dell2\/ptmp\/${USER}\/batch_logs'
old_ver='Perry.Shafran'
new_ver='Ho-Chun.Huang'
for i in "${shfile[@]}"
do
   echo ${i}
   if [ "${i}" == $0 ]; then continue; fi
   if [ "${i}" == "xtest1" ]; then continue; fi
   if [ -d ${i} ]; then continue; fi
   ## mv ${i}.bak ${i}
   if [ -e xtest1 ]; then /bin/rm -f xtest1; fi
   grep "${old_ver}" ${i} > xtest1
   if [ -s xtest1 ]; then
      mv ${i} ${i}.bak
      sed -e "s!${old_ver}!${new_ver}!" ${i}.bak > ${i}
      ## echo "diff ${i} ${i}.bak"
      chmod u+x ${i}
      diff ${i} ${i}.bak
   fi
done
exit
