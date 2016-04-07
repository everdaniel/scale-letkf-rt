#!/bin/bash -l
#-------------------------------------------------------------------------------

wkdir="$(cd "$( dirname "$0" )" && pwd)"
cd ${wkdir}
myname=$(basename "$0")
myname1=${myname%.*}

. admin.rc
(($? != 0)) && exit $?

#-------------------------------------------------------------------------------

download_parse_conf () {
  mkdir -p $outdir/exp
  rsync -aLvz --remove-source-files ${r_url}:${r_rundir}/exp/ $outdir/exp
  # parse ...
}

download () {
  ssh ${r_url} "cd ${r_outdir}/${TIMEf}/log && tar --remove-files -czf scale_init.tar.gz scale_init"
  ssh ${r_url} "cd ${r_outdir}/${TIMEf}/log && tar --remove-files -czf scale.tar.gz scale"
  ssh ${r_url} "cd ${r_outdir}/${ETIMEf}/log && tar --remove-files -czf obsope.tar.gz obsope"
  ssh ${r_url} "cd ${r_outdir}/${ETIMEf}/log && tar --remove-files -czf letkf.tar.gz letkf"
  ssh ${r_url} "cd ${r_outdir}/${ETIMEf} && tar --remove-files -czf obsgues.tar.gz obsgues"

  mkdir -p $outdir/${TIMEf}/hist
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${TIMEf}/hist/meanf/ $outdir/${TIMEf}/hist/meanf
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${TIMEf}/hist/[0-9]* $outdir/${TIMEf}/hist

  mkdir -p $outdir/${ETIMEf}/gues
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${ETIMEf}/gues/mean/ $outdir/${ETIMEf}/gues/mean
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${ETIMEf}/gues/meanf/ $outdir/${ETIMEf}/gues/meanf
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${ETIMEf}/gues/sprd/ $outdir/${ETIMEf}/gues/sprd
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${ETIMEf}/gues/[0-9]* $outdir/${ETIMEf}/gues

  mkdir -p $outdir/${ETIMEf}/anal
  rsync -av ${r_url}:${r_outdir}/${ETIMEf}/anal/mean/ $outdir/${ETIMEf}/anal/mean
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${ETIMEf}/anal/sprd/ $outdir/${ETIMEf}/anal/sprd
#  if ((ETIMEh == 0)); then
##  if ((ETIMEdoy % 5 == 1 && ETIMEh == 0)); then
    rsync -av ${r_url}:${r_outdir}/${ETIMEf}/anal/[0-9]* $outdir/${ETIMEf}/anal
#  fi

  mkdir -p $outdir/${TIMEf}/log
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${TIMEf}/log/scale_init.tar.gz $outdir/${TIMEf}/log
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${TIMEf}/log/scale.tar.gz $outdir/${TIMEf}/log

  mkdir -p $outdir/${ETIMEf}/log
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${ETIMEf}/log/obsope.tar.gz $outdir/${ETIMEf}/log
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${ETIMEf}/log/letkf.tar.gz $outdir/${ETIMEf}/log
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${ETIMEf}/obsgues.tar.gz $outdir/${ETIMEf}

  mkdir -p $outdir/${TIMEf}/anal/mean
  rsync -av --remove-source-files ${r_url}:${r_outdir}/${TIMEf}/anal/mean/init_ocean.pe*.nc $outdir/${TIMEf}/anal/mean
  ssh ${r_url} "rm -r ${r_outdir}/${TIMEf}/anal/[0-9]*"
  if ((FCST_TIMEf >= TIMEf)); then
    ssh ${r_url} "rm -r ${r_outdir}/${TIMEf}/anal/mean"
  fi

  ssh ${r_url} "find ${r_outdir}/${TIMEf} -depth -type d -empty -exec rmdir {} \;"
  ssh ${r_url} "find ${r_outdir}/${ETIMEf} -depth -type d -empty -exec rmdir {} \;"

  ssh ${r_url} "rm -r ${r_wrfdir}/${TIMEf}_da"
  ssh ${r_url} "rm ${r_obsdir}/obs_${ETIMEf}.dat"

  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [DONE] $ETIMEf - Download and remove remote files (background job completed)" >> $logfile
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
TIME="$(date -ud "${PREVIOUS_TIME}" +'%Y-%m-%d %H:%M:%S')"
TIMEf="$(date -ud "${TIME}" +'%Y%m%d%H%M%S')"
TIMEf2="$(date -ud "${TIME}" +'%Y%m%d%H')"
ETIME="$(date -ud "$LCYCLE second ${TIME}" +'%Y-%m-%d %H:%M:%S')"
ETIMEf="$(date -ud "${ETIME}" +'%Y%m%d%H%M%S')"
ETIMEf2="$(date -ud "${ETIME}" +'%Y%m%d%H')"
ETIMEdoy="$(date -ud "${ETIME}" +'%j')"
ETIMEh="$(date -ud "${ETIME}" +'%k')"
EETIMEf="$(date -ud "$((LCYCLE*2)) second ${TIME}" +'%Y%m%d%H%M%S')"
PTIMEf="$(date -ud "-$LCYCLE second ${TIME}" +'%Y%m%d%H%M%S')"

FCST_TIME="$(cat "$wkdir/admin_fcst.time")"
FCST_TIMEf="$(date -ud "${FCST_TIME}" +'%Y%m%d%H%M%S')"

#-------------------------------------------------------------------------------

now="$(date -u +'%Y-%m-%d %H:%M:%S')"
echo "$now [TRY ] $ETIMEf" >> $logfile

if [ ! -s "$wrfdir/${TIMEf2}/mean/wrfout_${TIMEf}" ] ||
   [ ! -s "$wrfdir/${ETIMEf2}/mean/wrfout_${ETIMEf}" ] ||
   [ ! -s "$wrfdir/${ETIMEf2}/mean/wrfout_${EETIMEf}" ]; then
  echo "$now [WAIT] $ETIMEf - Model files are not ready." >> $logfile
  rm -f $lockfile
  exit
fi
if [ ! -s "$obsdir/${ETIMEf2}/obs_${ETIMEf}.dat" ]; then
  echo "$now [WAIT] $ETIMEf - Observation files are not ready." >> $logfile
  rm -f $lockfile
  exit
fi

#-------------------------------------------------------------------------------

rm -f $outfile

now="$(date -u +'%Y-%m-%d %H:%M:%S')"
echo "$now [TRAN] $ETIMEf - Upload files" >> $logfile
mkdir -p $tmpdir/${TIMEf}_da/mean
rm -fr $tmpdir/${TIMEf}_da/mean/*
ln -s $wrfdir/${TIMEf2}/mean/wrfout_${TIMEf} $tmpdir/${TIMEf}_da/mean
ln -s $wrfdir/${ETIMEf2}/mean/wrfout_${ETIMEf} $tmpdir/${TIMEf}_da/mean
ln -s $wrfdir/${ETIMEf2}/mean/wrfout_${EETIMEf} $tmpdir/${TIMEf}_da/mean
rsync -avL $tmpdir/${TIMEf}_da ${r_url}:${r_wrfdir} >> $outfile
rsync -av $obsdir/${ETIMEf2}/obs_${ETIMEf}.dat ${r_url}:${r_obsdir}/obs_${ETIMEf}.dat >> $outfile
rm -fr $tmpdir/${TIMEf}_da/mean/*
rmdir $tmpdir/${TIMEf}_da/mean
rmdir $tmpdir/${TIMEf}_da

success=0
max_try=3
ntry=0
while ((success == 0)) && ((ntry < max_try)); do
  ntry=$((ntry+1))
  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [RUN ] $ETIMEf/$ntry" >> $logfile
  ssh ${r_url} "cd ${r_rundir} && ./admin.sh cycle ${TIMEf} ${TIME_DT[$ntry]} ${TIME_DT_DYN[$ntry]} ${NNODES[$ntry]} ${WTIME_L[$ntry]}"
#  ssh ${r_url} "cd ${r_rundir} && ./admin_micro.sh cycle ${TIMEf} ${TIME_DT[$ntry]} ${TIME_DT_DYN[$ntry]} ${NNODES_m[$ntry]} ${WTIME_L_m[$ntry]}"
  res=$?

  if ((res == 0)); then
    success=1
  else
    now="$(date -u +'%Y-%m-%d %H:%M:%S')"
    echo "$now [ERR ] $ETIMEf/$ntry - Exit code: $res" >> $logfile
    if ((res >= 100 && res <= 110)); then
      download_parse_conf
    fi
    sleep 10s
  fi
done

if ((success == 1)); then
  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [TRAN] $ETIMEf - Download and remove remote files (background job)" >> $logfile
  download_parse_conf
  download >> $outfile 2>&1 &

  now="$(date -u +'%Y-%m-%d %H:%M:%S')"
  echo "$now [DONE] $ETIMEf" >> $logfile
  echo "$ETIME" > $timefile
else
  echo "$now [FAIL] $ETIMEf - All trials failed" >> $logfile
fi

#-------------------------------------------------------------------------------

rm -f $lockfile
