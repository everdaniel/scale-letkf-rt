#!/bin/bash -l
#-------------------------------------------------------------------------------

wkdir="$(cd "$( dirname "$0" )" && pwd)"
cd ${wkdir}
myname=$(basename "$0")
myname1=${myname%.*}

. admin.rc || exit $?

#-------------------------------------------------------------------------------

function unlock () {
  if (($(cat $lockfile) == $$)); then
    rm -f $lockfile
  fi
}
trap unlock EXIT

#-------------------------------------------------------------------------------

download_parse_conf () {
  mkdir -p $outdir/exp
  rsync -aLvz --remove-source-files ${r_url}:${r_rundir}/exp/ $outdir/exp
  # parse ...
}

download () {
  istime="$TIME"
  istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
  iatime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
  iatimef="$(date -ud "$iatime" +'%Y%m%d%H%M%S')"
  while ((istimef <= ETIMEf)); do
    ssh ${r_url} "cd ${r_outdir}/${istimef}/log && tar --remove-files -czf scale_init.tar.gz scale_init"
    ssh ${r_url} "cd ${r_outdir}/${istimef}/log && tar --remove-files -czf scale.tar.gz scale"
    ssh ${r_url} "cd ${r_outdir}/${iatimef}/log && tar --remove-files -czf obsope.tar.gz obsope"
    ssh ${r_url} "cd ${r_outdir}/${iatimef}/log && tar --remove-files -czf letkf.tar.gz letkf"
    ssh ${r_url} "cd ${r_outdir}/${iatimef} && tar --remove-files -czf obsgues.tar.gz obsgues"

    mkdir -p $outdir/${istimef}/hist
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${istimef}/hist/meanf/ $outdir/${istimef}/hist/meanf
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${istimef}/hist/[0-9]* $outdir/${istimef}/hist

    mkdir -p $outdir/${iatimef}/gues
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${iatimef}/gues/mean/ $outdir/${iatimef}/gues/mean
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${iatimef}/gues/meanf/ $outdir/${iatimef}/gues/meanf
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${iatimef}/gues/sprd/ $outdir/${iatimef}/gues/sprd
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${iatimef}/gues/[0-9]* $outdir/${iatimef}/gues

    mkdir -p $outdir/${iatimef}/anal
    rsync -av ${r_url}:${r_outdir}/${iatimef}/anal/mean/ $outdir/${iatimef}/anal/mean
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${iatimef}/anal/sprd/ $outdir/${iatimef}/anal/sprd
#    if (($(date -ud "${iatime}" +'%k') == 0)); then
##    if (($(date -ud "${iatime}" +'%j') % 5 == 1 && $(date -ud "${iatime}" +'%k') == 0)); then
      rsync -av ${r_url}:${r_outdir}/${iatimef}/anal/[0-9]* $outdir/${iatimef}/anal
#    fi

    mkdir -p $outdir/${istimef}/log
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${istimef}/log/scale_init.tar.gz $outdir/${istimef}/log
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${istimef}/log/scale.tar.gz $outdir/${istimef}/log

    mkdir -p $outdir/${iatimef}/log
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${iatimef}/log/obsope.tar.gz $outdir/${iatimef}/log
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${iatimef}/log/letkf.tar.gz $outdir/${iatimef}/log
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${iatimef}/obsgues.tar.gz $outdir/${iatimef}

    mkdir -p $outdir/${istimef}/anal/mean
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${istimef}/anal/mean/init_ocean.pe*.nc $outdir/${istimef}/anal/mean
    ssh ${r_url} "rm -r ${r_outdir}/${istimef}/anal/[0-9]*"
    if (($(date -ud "${FCST_TIME}" +'%Y%m%d%H%M%S') >= istimef)); then
      ssh ${r_url} "rm -r ${r_outdir}/${istimef}/anal/mean"
    fi

    ssh ${r_url} "find ${r_outdir}/${istimef} -depth -type d -empty -exec rmdir {} \;"
    ssh ${r_url} "find ${r_outdir}/${iatimef} -depth -type d -empty -exec rmdir {} \;"

    ssh ${r_url} "rm -r ${r_wrfdir_da}/${istimef}"
    ssh ${r_url} "rm ${r_obsdir}/obs_${iatimef}.dat"

    istime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
    istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
    iatime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
    iatimef="$(date -ud "$iatime" +'%Y%m%d%H%M%S')"
  done

  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [DONE] $TIMEPRINT - Download and remove remote files (background job completed)" >> $logfile
}

#-------------------------------------------------------------------------------

now="$(date -u +'%Y-%m-%d %H:%M:%S')"
if [ ! -s "$timefile" ]; then
  echo "$now [ERR ] Cannot find previous model time." >> $logfile
  exit
fi
if [ -e "$lockfile" ]; then
  echo "$now [PREV]" >> $logfile
  exit
else
  echo $$ >> $lockfile
fi

PREVIOUS_TIME="$(cat $timefile)"
TIME="$(date -ud "${PREVIOUS_TIME}" +'%Y-%m-%d %H:%M:%S')"
TIMEf="$(date -ud "$TIME" +'%Y%m%d%H%M%S')"
ATIME="$(date -ud "$LCYCLE second $TIME" +'%Y-%m-%d %H:%M:%S')"
ATIMEf="$(date -ud "$ATIME" +'%Y%m%d%H%M%S')"

if [ -s "$wkdir/admin_fcst.time" ]; then
  FCST_TIME="$(cat "$wkdir/admin_fcst.time")"
fi

TIMEstop="$(date -ud "$((LCYCLE * (MAX_CYCLE-1))) second $TIME" +'%Y-%m-%d %H:%M:%S')"

if [ -s "$timestopfile" ]; then
  TIMEstoptmp="$(cat $timestopfile)"
  if (($(date -ud "$TIMEstoptmp" +'%s') < $(date -ud "$TIMEstop" +'%s'))); then
    TIMEstop="$TIMEstoptmp"
  fi
fi

if (($(date -ud "$TIME" +'%s') > $(date -ud "$TIMEstop" +'%s'))); then
  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [STOP] $ATIMEf" >> $logfile
  exit
fi

#-------------------------------------------------------------------------------

now="$(date -u +'%Y-%m-%d %H:%M:%S')"
echo "$now [TRY ] $ATIMEf" >> $logfile

n=0
istime="$TIME"
istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
iatime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
iatimef="$(date -ud "$iatime" +'%Y%m%d%H%M%S')"
while ((istimef <= $(date -ud "$TIMEstop" +'%Y%m%d%H%M%S') || n == 0)); do
  if [ ! -s "$wrfdir/$(date -ud "$istime" +'%Y%m%d%H')/mean/wrfout_${istimef}" ] ||
     [ ! -s "$wrfdir/$(date -ud "$iatime" +'%Y%m%d%H')/mean/wrfout_${iatimef}" ] ||
     [ ! -s "$wrfdir/$(date -ud "$iatime" +'%Y%m%d%H')/mean/wrfout_$(date -ud "$LCYCLE second $iatime" +'%Y%m%d%H%M%S')" ]; then
    if ((n == 0)); then
      echo "$now [WAIT] $iatimef - Model files are not ready." >> $logfile
      exit
    else
      break
    fi
  fi

  if [ ! -s "$obsdir/$(date -ud "$iatime" +'%Y%m%d%H')/obs_${iatimef}.dat" ]; then
    if ((n == 0)); then
      echo "$now [WAIT] $iatimef - Observation files are not ready." >> $logfile
      exit
    else
      break
    fi
  fi

  n=$((n+1))
  istime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
  istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
  iatime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
  iatimef="$(date -ud "$iatime" +'%Y%m%d%H%M%S')"
done

ETIME="$(date -ud "- $LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
ETIMEf="$(date -ud "$ETIME" +'%Y%m%d%H%M%S')"
EATIME="$(date -ud "$LCYCLE second $ETIME" +'%Y-%m-%d %H:%M:%S')"
EATIMEf="$(date -ud "$EATIME" +'%Y%m%d%H%M%S')"
NCYCLE=$n

if [ "$TIMEf" = "$ETIMEf" ]; then
  TIMEPRINT="$ATIMEf"
else
  TIMEPRINT="${ATIMEf}-${EATIMEf}"
fi

#-------------------------------------------------------------------------------

rm -f $outfile

now="$(date -u +'%Y-%m-%d %H:%M:%S')"
echo "$now [TRAN] $TIMEPRINT - Upload files" >> $logfile

istime="$TIME"
istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
iatime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
iatimef="$(date -ud "$iatime" +'%Y%m%d%H%M%S')"
while ((istimef <= ETIMEf)); do
  mkdir -p $tmpdir/${istimef}/mean
  rm -fr $tmpdir/${istimef}/mean/*
  ln -s $wrfdir/$(date -ud "$istime" +'%Y%m%d%H')/mean/wrfout_${istimef} $tmpdir/${istimef}/mean
  ln -s $wrfdir/$(date -ud "$iatime" +'%Y%m%d%H')/mean/wrfout_${iatimef} $tmpdir/${istimef}/mean
  ln -s $wrfdir/$(date -ud "$iatime" +'%Y%m%d%H')/mean/wrfout_$(date -ud "$LCYCLE second $iatime" +'%Y%m%d%H%M%S') $tmpdir/${istimef}/mean
  rsync -avL $tmpdir/${istimef} ${r_url}:${r_wrfdir_da} >> $outfile
  rsync -av $obsdir/$(date -ud "$iatime" +'%Y%m%d%H')/obs_${iatimef}.dat ${r_url}:${r_obsdir}/obs_${iatimef}.dat >> $outfile
  rm -fr $tmpdir/${istimef}/mean/*
  rmdir $tmpdir/${istimef}/mean
  rmdir $tmpdir/${istimef}

  istime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
  istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
  iatime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
  iatimef="$(date -ud "$iatime" +'%Y%m%d%H%M%S')"
done

success=0
ntry=0
while ((success == 0)) && ((ntry < MAX_TRY)); do
  ntry=$((ntry+1))
  total_sec=$(date -ud "1970-01-01 ${WTIME_L[$ntry]}" +'%s')
  WTIME_L_use=$(date -ud "$((total_sec * NCYCLE)) second 1970-01-01 00:00:00" +'%H:%M:%S')
  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [RUN ] $TIMEPRINT/$ntry" >> $logfile
  ssh ${r_url} "cd ${r_rundir} && ./admin.sh cycle ${TIMEf} ${ETIMEf} ${TIME_DT[$ntry]} ${TIME_DT_DYN[$ntry]} ${NNODES[$ntry]} $WTIME_L_use"
  res=$?

  if ((res == 0)); then
    success=1
  else
    now="$(date -u +'%Y-%m-%d %H:%M:%S')"
    echo "$now [ERR ] $TIMEPRINT/$ntry - Exit code: $res" >> $logfile
    if ((res >= 100 && res <= 110)); then
      download_parse_conf
    fi
    sleep 10s
  fi
done

if ((success == 1)); then
  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [TRAN] $TIMEPRINT - Download and remove remote files (background job)" >> $logfile
  download_parse_conf
  download >> $outfile 2>&1 &

  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [DONE] $TIMEPRINT" >> $logfile
  echo "$EATIME" > $timefile
else
  echo "$now [FAIL] $TIMEPRINT - All trials failed" >> $logfile
fi
