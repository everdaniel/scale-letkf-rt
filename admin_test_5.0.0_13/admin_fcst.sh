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
  rsync -aLvz --remove-source-files ${r_url}:${F_r_rundir}/exp/ $outdir/exp
  # parse ...
}

download () {
  istime="$TIME"
  istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
  while ((istimef <= ETIMEf)); do
    ssh ${r_url} "cd ${r_outdir}/${istimef}/log && tar --remove-files -czf fcst_scale_init.tar.gz fcst_scale_init"
    ssh ${r_url} "cd ${r_outdir}/${istimef}/log && tar --remove-files -czf fcst_scale.tar.gz fcst_scale"

    mkdir -p $outdir/${istimef}/fcst
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${istimef}/fcst/mean/ $outdir/${istimef}/fcst/mean

    mkdir -p $outdir/${istimef}/log
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${istimef}/log/fcst_scale_init.tar.gz $outdir/${istimef}/log
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${istimef}/log/fcst_scale.tar.gz $outdir/${istimef}/log

#    if (($(date -ud "${CYCLE_TIME}" +'%Y%m%d%H%M%S') >= $(date -ud "$LCYCLE second ${istime}" +'%Y%m%d%H%M%S'))); then
#      ssh ${r_url} "rm -r ${r_outdir}/${istimef}/anal/mean"
#    fi

    ssh ${r_url} "find ${r_outdir}/${istimef} -depth -type d -empty -exec rmdir {} \;"

    ssh ${r_url} "rm -r ${r_gradsdir}/${istimef}"

    $plotdir/plot.sh "${istime}"

    istime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
    istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
  done

  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [DONE] $TIMEPRINT - Download files and plot figures (background job completed)" >> $logfile
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
TIME="$(date -ud "$LCYCLE second ${PREVIOUS_TIME}" +'%Y-%m-%d %H:%M:%S')"
TIMEf="$(date -ud "${TIME}" +'%Y%m%d%H%M%S')"

TIMEstop="$(date -ud "$((LCYCLE * (F_MAX_CYCLE-1))) second $TIME" +'%Y-%m-%d %H:%M:%S')"

if [ -s "$timestopfile" ]; then
  TIMEstoptmp="$(cat $timestopfile)"
  if (($(date -ud "$TIMEstoptmp" +'%s') < $(date -ud "$TIMEstop" +'%s'))); then
    TIMEstop="$TIMEstoptmp"
  fi
fi

if [ -s "$wkdir/admin_cycle.time" ]; then
  CYCLE_TIME="$(cat "$wkdir/admin_cycle.time")"
  if (($(date -ud "$CYCLE_TIME" +'%s') < $(date -ud "$TIMEstop" +'%s'))); then
    TIMEstop="$CYCLE_TIME"
  fi
fi

if (($(date -ud "$TIME" +'%s') > $(date -ud "$TIMEstop" +'%s'))); then
  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [STOP] $TIMEf" >> $logfile
  exit
fi

#-------------------------------------------------------------------------------

now="$(date -u +'%Y-%m-%d %H:%M:%S')"
echo "$now [TRY ] $TIMEf" >> $logfile

n=0
istime="$TIME"
istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
while ((istimef <= $(date -ud "$TIMEstop" +'%Y%m%d%H%M%S') || n == 0)); do
  ready=1

  tfcst=0
  while ((tfcst <= FCSTLEN)); do
    itimef="$(date -ud "$tfcst second $istime" +'%Y%m%d%H%M%S')"
    if [ ! -s "$gradsdir/$(date -ud "$istime" +'%Y%m%d%H')/atm_${itimef}.grd" ] ||
       [ ! -s "$gradsdir/$(date -ud "$istime" +'%Y%m%d%H')/sfc_${itimef}.grd" ] ||
       [ ! -s "$gradsdir/$(date -ud "$istime" +'%Y%m%d%H')/land_${itimef}.grd" ]; then
      ready=0
      break
    fi
    tfcst=$((tfcst+LCYCLE))
  done
  if ((ready == 0)); then
    if ((n == 0)); then
      echo "$now [WAIT] $istimef - Model files are not ready." >> $logfile
      exit
    else
      break
    fi
  fi

  if [ ! -s "$outdir/${istimef}/anal/mean/init.pe000000.nc" ]; then
    if ((n == 0)); then
      echo "$now [WAIT] $istimef - LETKF analyses are not ready." >> $logfile
      exit
    else
      break
    fi
  fi

  n=$((n+1))
  istime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
  istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
done

ETIME="$(date -ud "- $LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
ETIMEf="$(date -ud "${ETIME}" +'%Y%m%d%H%M%S')"
NCYCLE=$n

if [ "$TIMEf" = "$ETIMEf" ]; then
  TIMEPRINT="$TIMEf"
else
  TIMEPRINT="${TIMEf}-${ETIMEf}"
fi

#-------------------------------------------------------------------------------

rm -f $outfile

now="$(date -u +'%Y-%m-%d %H:%M:%S')"
echo "$now [TRAN] $TIMEPRINT - Upload files" >> $logfile

istime="$TIME"
istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
while ((istimef <= ETIMEf)); do
  mkdir -p $tmpdir/${istimef}/mean
  rm -fr $tmpdir/${istimef}/mean/*
  tfcst=0
  while ((tfcst <= FCSTLEN)); do
    itimef="$(date -ud "$tfcst second $istime" +'%Y%m%d%H%M%S')"
    ln -s $gradsdir/$(date -ud "$istime" +'%Y%m%d%H')/atm_${itimef}.grd $tmpdir/${istimef}/mean
    ln -s $gradsdir/$(date -ud "$istime" +'%Y%m%d%H')/sfc_${itimef}.grd $tmpdir/${istimef}/mean
    ln -s $gradsdir/$(date -ud "$istime" +'%Y%m%d%H')/land_${itimef}.grd $tmpdir/${istimef}/mean
    tfcst=$((tfcst+LCYCLE))
  done
  rsync -avL $tmpdir/${istimef} ${r_url}:${r_gradsdir} >> $outfile
  rm -fr $tmpdir/${istimef}/mean/*
  rmdir $tmpdir/${istimef}/mean
  rmdir $tmpdir/${istimef}

  istime="$(date -ud "$LCYCLE second $istime" +'%Y-%m-%d %H:%M:%S')"
  istimef="$(date -ud "$istime" +'%Y%m%d%H%M%S')"
done

success=0
ntry=0
while ((success == 0)) && ((ntry < F_MAX_TRY)); do
  ntry=$((ntry+1))
  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [RUN ] $TIMEPRINT/$ntry" >> $logfile
  ssh ${r_url} "cd ${F_r_rundir} && ./admin.sh fcst ${TIMEf} ${ETIMEf} ${TIME_DT[$ntry]} ${TIME_DT_DYN[$ntry]} $((${F_NNODES[$ntry]} * NCYCLE)) ${F_WTIME_L[$ntry]}"
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
  echo "$now [TRAN] $TIMEPRINT - Download files and plot figures (background job)" >> $logfile
  download_parse_conf
  download >> $outfile 2>&1 &

  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [DONE] $TIMEPRINT" >> $logfile
  echo "$ETIME" > $timefile
else
  echo "$now [FAIL] $TIMEPRINT - All trials failed" >> $logfile
fi
