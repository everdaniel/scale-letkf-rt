#!/bin/bash

tstart="$1"
tend="$2"
outdir="$3"

#tstart='2015-05-05 18'
#tend='2015-05-06 00'
#outdir='/data5/gylien/realtime/ncepgfs_wrf/2015050518/mean'

tint=21600

#----

wkdir="$( cd "$( dirname "$0" )" && pwd )"
cd ${wkdir}

time="$tstart"
while (($(date -ud "$time" '+%s') <= $(date -ud "$tend" '+%s'))); do

  timef=$(date -ud "$time" '+%Y-%m-%d %H')
  echo "[$timef]"

  YYYYs=$(date -ud "$time" '+%Y')
  MMs=$(date -ud "$time" '+%m')
  DDs=$(date -ud "$time" '+%d')
  HHs=$(date -ud "$time" '+%H')
  YYYYe=$(date -ud "$tint second $time" '+%Y') # no use...
  MMe=$(date -ud "$tint second $time" '+%m')   #
  DDe=$(date -ud "$tint second $time" '+%d')   #
  HHe=$(date -ud "$tint second $time" '+%H')   #

  cat namelist.input.src | \
  sed -e "s/\[YYYYs\]/$YYYYs/" \
      -e "s/\[MMs\]/$MMs/" \
      -e "s/\[DDs\]/$DDs/" \
      -e "s/\[HHs\]/$HHs/" \
      -e "s/\[YYYYe\]/$YYYYs/" \
      -e "s/\[MMe\]/$MMs/" \
      -e "s/\[DDe\]/$DDs/" \
      -e "s/\[HHe\]/$HHs/" \
  > namelist.input

  rm -f met_em.d01.*
  ln -s ../wps/met_em.d01.${YYYYs}-${MMs}-${DDs}_${HHs}\:00\:00.nc met_em.d01.${YYYYs}-${MMs}-${DDs}_${HHs}\:00\:00.nc

  mpirun 4 ./real.exe
  mpirun 4 ./wrf.exe

  mkdir -p $outdir
  mv wrfout_d01_${YYYYs}-${MMs}-${DDs}_${HHs}\:00\:00 $outdir/wrfout_${YYYYs}${MMs}${DDs}${HHs}0000

time=$(date -ud "$tint second $time" '+%Y-%m-%d %H')
done
