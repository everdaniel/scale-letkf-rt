#!/bin/bash

wkdir="$( cd "$( dirname "$0" )" && pwd )"

cd ${wkdir}

tstart="2016-05-25 18:00:00"
tend="2016-05-25 18:00:00"
tint=21600

time=$(date -ud "$tstart" +'%Y-%m-%d %H:%M:%S')
while (($(date -ud "$time" +'%s') <= $(date -ud "$tend" +'%s'))); do

  YYYYMMDDHHIISS=$(date -ud "${time}" +'%Y%m%d%H%M%S')
  YYYYMMDDHH=$(date -ud "${time}" +'%Y%m%d%H')
  YYYY=$(date -ud "${time}" +'%Y')
  MM=$(date -ud "${time}" +'%m')
  DD=$(date -ud "${time}" +'%d')
  HH=$(date -ud "${time}" +'%H')

  echo "[${YYYYMMDDHH}]"

  cd ${wkdir}/$YYYYMMDDHH

  t=0
  while ((t <= 120)); do

    tf=$(printf '%03d' $t)
    TIME_fcst=`date -ud "${t} hour $YYYY-$MM-$DD $HH" +'%Y-%m-%d %H:%M:%S'`
    YYYYMMDDHHMMSS_fcst=`date -ud "$TIME_fcst" +'%Y%m%d%H%M%S'`

#    if [ ! -s "gfs.$YYYYMMDDHHMMSS_fcst" ]; then
#      rm -f gfs.t${HH}z.pgrb2f${tf}
#      wget --cache=off http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${YYYYMMDDHH}/gfs.t${HH}z.pgrb2.0p50.f${tf}
#      if [ -s "gfs.t${HH}z.pgrb2.0p50.f${tf}" ]; then
#        mv -f gfs.t${HH}z.pgrb2.0p50.f${tf} gfs.$YYYYMMDDHHMMSS_fcst
#        echo "[GET ] $YYYYMMDDHH -> gfs.$YYYYMMDDHHMMSS_fcst"
#      fi
#    fi

#    echo "[CONV] $YYYYMMDDHH -> gfs.$YYYYMMDDHHMMSS_fcst - WPS"
#    bash $wkdir/run/wps/convert.sh "$TIME_fcst" "$TIME_fcst" "$wkdir/${YYYYMMDDHH}/gfs"

#    echo "[CONV] $YYYYMMDDHH -> gfs.$YYYYMMDDHHMMSS_fcst - WRF"
#    bash $wkdir/run/wrf/convert.sh "$TIME_fcst" "$TIME_fcst" "$wkdir/../ncepgfs_wrf/${YYYYMMDDHH}/mean"

    echo "[CONV] $YYYYMMDDHH -> gfs.$YYYYMMDDHHMMSS_fcst - GrADS"
    bash $wkdir/run/grads/convert.sh "$TIME_fcst" "$TIME_fcst" "$wkdir/${YYYYMMDDHH}/gfs"

#    echo "[CONV] $YYYYMMDDHH -> gfs.$YYYYMMDDHHMMSS_fcst - Plot"
#    bash $wkdir/run/plot/plot.sh "$TIME_fcst" "$GET_TIME" $((t/6+1)) "$wkdir/${YYYYMMDDHH}/gfs"

#    if ((t == 0)); then
        
#    fi

  t=$((t+6))
  done

time=$(date -ud "$tint second $time" +'%Y-%m-%d %H:%M:%S')
done

