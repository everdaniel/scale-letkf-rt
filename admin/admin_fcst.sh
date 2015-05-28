#!/bin/bash -l
#-------------------------------------------------------------------------------

wkdir="$(cd "$( dirname "$0" )" && pwd)"
cd ${wkdir}
myname=$(basename "$0")
myname1=${myname%.*}

. admin.rc
(($? != 0)) && exit $?

#-------------------------------------------------------------------------------

fcst_download () {
#  ssh ${r_url} "cd ${r_outdir}/${TIMEf}/log && tar --remove-files -czf scale_init.tar.gz scale_init"
#  ssh ${r_url} "cd ${r_outdir}/${TIMEf}/log && tar --remove-files -czf scale.tar.gz scale"

  mkdir -p $outdir/${TIMEf}
  rsync -avz --remove-source-files ${r_url}:${r_outdir}/${TIMEf}/fcst_conf $outdir/${TIMEf}
#  mkdir -p $outdir/${TIMEf}/log
#  rsync -av --remove-source-files ${r_url}:${r_outdir}/${TIMEf}/log/scale_init.tar.gz $outdir/${TIMEf}/log
#  rsync -av --remove-source-files ${r_url}:${r_outdir}/${TIMEf}/log/scale.tar.gz $outdir/${TIMEf}/log

  mkdir -p $outdir/${TIMEf}/fcst
  if ((CYCLE_TIMEf >= $(date -ud "$LCYCLE second ${TIME}" +'%Y%m%d%H%M%S'))); then
    rsync -av --remove-source-files ${r_url}:${r_outdir}/${TIMEf}/fcst/mean $outdir/${TIMEf}/fcst
  else
    rsync -av ${r_url}:${r_outdir}/${TIMEf}/fcst/mean $outdir/${TIMEf}/fcst
  fi

  ssh ${r_url} "rm -r ${r_wrfdir}/${TIMEf}"

  ssh ${r_url} "rm -r ${r_outdir}/${TIMEf}/anal/mean"

  ssh ${r_url} "find ${r_outdir}/${TIMEf} -depth -type d -empty -exec rmdir {} \;"

  $plotdir/plot.sh "${TIME}"

  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [DONE] $TIMEf - Download files and plot figures (background job completed)" >> $logfile
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
  touch $lockfile
fi

PREVIOUS_TIME="$(cat $timefile)"
TIME="$(date -ud "$LCYCLE second ${PREVIOUS_TIME}" +'%Y-%m-%d %H:%M:%S')"
TIMEf="$(date -ud "${TIME}" +'%Y%m%d%H%M%S')"
TIMEf2="$(date -ud "${TIME}" +'%Y%m%d%H')"
TIMEh="$(date -ud "${TIME}" +'%k')"

CYCLE_TIME="$(cat "$wkdir/admin_cycle.time")"
CYCLE_TIMEf="$(date -ud "${FCST_TIME}" +'%Y%m%d%H%M%S')"

#-------------------------------------------------------------------------------

now="$(date -u +'%Y-%m-%d %H:%M:%S')"
echo "$now [TRY ] $TIMEf" >> $logfile

#if (($(date -u +'%s') - $(date -ud "$TIME" +'%s') > 86400)); then
#  echo "$now [SKIP] $TIMEf - Initial conditions are too old." >> $logfile
#  echo "$TIME" > $timefile
#  rm -f $lockfile
#  exit
#fi

#if ((TIMEh == 6 || TIMEh == 18)); then
#  echo "$now [SKIP] $TIMEf - Do not run forecast at this time." >> $logfile
#  echo "$TIME" > $timefile
#  rm -f $lockfile
#  exit
#fi

tfcst=0
while ((tfcst <= FCSTLEN)); do
  itimef="$(date -ud "$tfcst second $TIME" +'%Y%m%d%H%M%S')"
  if [ ! -s "$wrfdir/${TIMEf2}/mean/wrfout_${itimef}" ]; then
    echo "$now [WAIT] $TIMEf - Model files are not ready." >> $logfile
    rm -f $lockfile
    exit
  fi
  tfcst=$((tfcst+LCYCLE))
done

if [ ! -s "$outdir/${TIMEf}/anal/mean/init.pe000000.nc" ]; then
  echo "$now [WAIT] $TIMEf - LETKF analyses are not ready." >> $logfile
  rm -f $lockfile
  exit
fi

#-------------------------------------------------------------------------------

rm -f $outfile

now="$(date -u +'%Y-%m-%d %H:%M:%S')"
echo "$now [TRAN] $TIMEf - Upload files" >> $logfile
mkdir -p $tmpdir/${TIMEf}/mean
rm -fr $tmpdir/${TIMEf}/mean/*
tfcst=0
while ((tfcst <= FCSTLEN)); do
  itimef="$(date -ud "$tfcst second $TIME" +'%Y%m%d%H%M%S')"
  ln -s $wrfdir/${TIMEf2}/mean/wrfout_${itimef} $tmpdir/${TIMEf}/mean
  tfcst=$((tfcst+LCYCLE))
done
rsync -avL $tmpdir/${TIMEf} ${r_url}:${r_wrfdir} >> $outfile
rm -fr $tmpdir/${TIMEf}/mean/*
rmdir $tmpdir/${TIMEf}/mean
rmdir $tmpdir/${TIMEf}

success=0
max_try=3
ntry=0
while ((success == 0)) && ((ntry < max_try)); do
  ntry=$((ntry+1))
  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [RUN ] $TIMEf/$ntry" >> $logfile
  ssh ${r_url} "cd ${F_r_rundir} && ./admin.sh fcst ${TIMEf} ${TIME_DT[$ntry]} ${TIME_DT_DYN[$ntry]} ${F_NNODES[$ntry]} ${F_WTIME_L[$ntry]}"
  res=$?

  if ((res == 0)); then
    success=1
  else
    now="$(date -u +'%Y-%m-%d %H:%M:%S')"
    echo "$now [ERR ] $TIMEf/$ntry - Exit code: $res" >> $logfile
    sleep 10s
  fi
done

if ((success == 1)); then
  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [TRAN] $TIMEf - Download files and plot figures (background job)" >> $logfile
  fcst_download >> $outfile 2>&1 &

  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [DONE] $TIMEf" >> $logfile
  echo "$TIME" > $timefile
else
  echo "$now [FAIL] $TIMEf - All trials failed" >> $logfile
fi

#-------------------------------------------------------------------------------

rm -f $lockfile
