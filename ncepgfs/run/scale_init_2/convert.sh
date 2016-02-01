#!/bin/bash

tstart="$1"
tend="$2"
wrfdir="$3"
outdir="$4"

#tstart='2015-05-05 18'
#tend='2015-05-05 18'
#wrfdir='/data5/gylien/realtime/ncepgfs_wrf/2015050518/mean'
#outdir='/data5/gylien/realtime/ncepgfs_scale/2015050518'

tint=21600

#----

wkdir="$( cd "$( dirname "$0" )" && pwd )"
cd ${wkdir}

time="$tstart"
while (($(date -ud "$time" '+%s') <= $(date -ud "$tend" '+%s'))); do

  timef=$(date -ud "$time" '+%Y-%m-%d %H')
  timef2=$(date -ud "$time" '+%Y%m%d%H%M%S')
  echo "[$timef]"

  YYYY=$(date -ud "$time" '+%Y')
  MM=$(date -ud "$time" '+%m')
  DD=$(date -ud "$time" '+%d')
  HH=$(date -ud "$time" '+%H')

#  rm -f init_*.000.pe*.nc

#  cat init.conf.src | \
#  sed -e "s/\[TIME_STARTDATE\]/ TIME_STARTDATE = $YYYY, $MM, $DD, $HH, 0, 0,/" \
#  > init.conf

#  ln -sf $wrfdir/wrfout_${timef2} wrfout_00000

#  mpirun 48 nice -n 5 ./scale-les_init init.conf

#  mkdir -p $outdir/${timef2}
#  for file in $(ls init_*.000.pe*.nc 2> /dev/null); do
#    file_suffix=${file:20}
#    mv $file $outdir/${timef2}/init${file_suffix}
#  done

#  mkdir -p $outdir/grads_o
#  python3 convert_grads.py "$outdir/${timef2}/init" "$outdir/grads_o" $YYYY $MM $DD $HH

  mkdir -p $outdir/grads
  python3 convert_grads.py "$outdir/${timef2}/init" "$outdir/grads" $YYYY $MM $DD $HH

time=$(date -ud "$tint second $time" '+%Y-%m-%d %H')
done
