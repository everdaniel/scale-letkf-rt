#!/bin/bash -l

wkdir="$( cd "$( dirname "$0" )" && pwd )"

cd ${wkdir}
now=`date -u +'%Y-%m-%d %H:%M:%S'`

if [ ! -s "${wkdir}/mtime" ]; then
  echo "$now [ERR ] Cannot find previous model time."
  exit
fi

if [ -e "${wkdir}/running" ]; then
  echo "$now [PREV]" >> ${wkdir}/get_ncep_gfs.log
  exit
else
  touch ${wkdir}/running
fi

PREVIOUS_TIME=`cat ${wkdir}/mtime`
GET_TIME=`date -u -d "+ 6 hour ${PREVIOUS_TIME}" +'%Y-%m-%d %H'`
YYYY=`date -u -d "$GET_TIME" +'%Y'`
MM=`date -u -d "$GET_TIME" +'%m'`
DD=`date -u -d "$GET_TIME" +'%d'`
HH=`date -u -d "$GET_TIME" +'%H'`
YYYYMMDDHH="$YYYY$MM$DD$HH"

echo "$now [TRY ] $YYYYMMDDHH" >> ${wkdir}/get_ncep_gfs.log

mkdir -p ${wkdir}/$YYYYMMDDHH
cd ${wkdir}/$YYYYMMDDHH

allget=1

t=0
while ((t <= 120)); do

  tf=`printf '%03d' $t`
  TIME_fcst=`date -ud "${t} hour $YYYY-$MM-$DD $HH" +'%Y-%m-%d %H:%M:%S'`
  YYYYMMDDHHMMSS_fcst=`date -ud "$TIME_fcst" +'%Y%m%d%H%M%S'`

  if [ ! -s "gfs.$YYYYMMDDHHMMSS_fcst" ]; then
    rm -f gfs.t${HH}z.pgrb2f${tf}
#    wget --limit-rate=500k ftp://ftp.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${YYYYMMDDHH}/gfs.t${HH}z.pgrb2f${tf}
#    wget --limit-rate=500k --cache=off http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${YYYYMMDDHH}/gfs.t${HH}z.pgrb2f${tf}
    wget --cache=off http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${YYYYMMDDHH}/gfs.t${HH}z.pgrb2.0p50.f${tf}
    if [ -s "gfs.t${HH}z.pgrb2.0p50.f${tf}" ]; then
      mv -f gfs.t${HH}z.pgrb2.0p50.f${tf} gfs.$YYYYMMDDHHMMSS_fcst
      now=`date -u +'%Y-%m-%d %H:%M:%S'`
      echo "$now [GET ] $YYYYMMDDHH -> gfs.$YYYYMMDDHHMMSS_fcst" >> ${wkdir}/get_ncep_gfs.log
    else
      allget=0
    fi
  fi

  if ((allget == 1)); then
    if [ ! -s "$wkdir/../ncepgfs_wrf/${YYYYMMDDHH}/mean/wrfout_${YYYYMMDDHHMMSS_fcst}" ]; then
      now=`date -u +'%Y-%m-%d %H:%M:%S'`
      echo "$now [CONV] $YYYYMMDDHH -> gfs.$YYYYMMDDHHMMSS_fcst - WPS" >> ${wkdir}/get_ncep_gfs.log
      bash $wkdir/run/wps/convert.sh "$TIME_fcst" "$TIME_fcst" "$wkdir/${YYYYMMDDHH}/gfs" \
       > ${wkdir}/convert_wps.log 2>&1

      now=`date -u +'%Y-%m-%d %H:%M:%S'`
      echo "$now [CONV] $YYYYMMDDHH -> gfs.$YYYYMMDDHHMMSS_fcst - WRF" >> ${wkdir}/get_ncep_gfs.log
      bash $wkdir/run/wrf/convert.sh "$TIME_fcst" "$TIME_fcst" "$wkdir/../ncepgfs_wrf/${YYYYMMDDHH}/mean" \
       > ${wkdir}/convert_wrf.log 2>&1

#      if [ ! -s "$wkdir/../ncepgfs_scale/${YYYYMMDDHH}/grads/${YYYYMMDDHHMMSS_fcst}.grd" ]; then
#        now=`date -u +'%Y-%m-%d %H:%M:%S'`
#        echo "$now [CONV] $YYYYMMDDHH -> gfs.$YYYYMMDDHHMMSS_fcst - SCALE_init" >> ${wkdir}/get_ncep_gfs.log
#        bash $wkdir/run/scale_init/convert.sh "$TIME_fcst" "$TIME_fcst" "$wkdir/../ncepgfs_wrf/${YYYYMMDDHH}/mean" "$wkdir/../ncepgfs_scale/${YYYYMMDDHH}" \
#         > ${wkdir}/convert_scale_init.log 2>&1
#      fi
    fi
  fi

t=$((t+6))
done

if ((allget == 1)); then
  now=`date -u +'%Y-%m-%d %H:%M:%S'`
  echo "$now [DONE] $YYYYMMDDHH" >> ${wkdir}/get_ncep_gfs.log
  echo "$GET_TIME" > ${wkdir}/mtime
fi

rm -f ${wkdir}/running
