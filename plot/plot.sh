#!/bin/bash -l

timestart="$1"

#timestart="2015-05-08 00:00:00"

tstart=0
tend=120
tskip=6
threads=11
tint=21600

figlist='sfc_prcp sfc_wind 850_temp 500_vort 300_wspd olr_ir max_ref'

#----

wkdir="$(cd "$( dirname "$0" )" && pwd)"

lockfile="$wkdir/plot.lock"
logfile="$wkdir/plot.log"
outfile="$wkdir/plot.out"
convertdir="$wkdir/run/tmp"
plotdir="$wkdir/run/grads"
outdir="$(cd "$wkdir/../exp/EastAsia_18km_48p" && pwd)"
web_fmdir="bowmore:/srv/www/htdocs/scale/fm"

#----

cd ${wkdir}

now=`date -u +'%Y-%m-%d %H:%M:%S'`
if [ -e "${wkdir}/running" ]; then
  echo "$now [PREV]" >> $logfile
  exit
else
  touch $lockfile
fi

TIME="$(date -ud "$timestart" +'%Y-%m-%d %H:%M:%S')"
TIMEf="$(date -ud "${TIME}" +'%Y%m%d%H%M%S')"
TIMEf2="$(date -ud "${TIME}" +'%Y%m%d%H')"

echo "$now [TRY ] $TIMEf" >> $logfile

rm -f $outfile

#----

tnum=0
it=$tstart
while ((it <= tend)); do
  tnum=$((tnum+1))
  it=$((it+tskip))
done
tnum_div=$((tnum / threads))
tnum_mod=$((tnum % threads))

#----

now=`date -u +'%Y-%m-%d %H:%M:%S'`
echo "$now [RUN ] $TIMEf - Convert to GrADS using $threads threads" >> $logfile

mkdir -p $convertdir
rm -fr $convertdir/*

ito=0
for ith in $(seq $threads); do
  mkdir -p $convertdir/${ith}/${TIMEf}
  cd $convertdir/${ith}/${TIMEf}
  ln -fs $outdir/${TIMEf}/fcst .

  if ((ith <= tnum_mod)); then
    itstart=$((tstart + ito * tskip))
    itend=$((tstart + (ito + tnum_div) * tskip + 1))
    echo "Process #${ith}: slot [$ito - $((ito + tnum_div))]" >> $outfile
    ito=$((ito + tnum_div + 1))
  else
    itstart=$((tstart + ito * tskip))
    itend=$((tstart + (ito + tnum_div - 1) * tskip + 1))
    echo "Process #${ith}: slot [$ito - $((ito + tnum_div - 1))]" >> $outfile
    ito=$((ito + tnum_div))
  fi

  python3 $wkdir/convert_letkfout.py "$convertdir/${ith}" "$TIMEf" $itstart $itend $tskip \
          > $convertdir/${ith}/convert.log 2>&1 &
  sleep 1s
done
wait

mkdir -p $outdir/${TIMEf}/fcstgp
rm -f $outdir/${TIMEf}/fcstgp/mean.grd
alldone=1
for ith in $(seq $threads); do
  if [ -s "$convertdir/${ith}/${TIMEf}/fcstgp/mean.grd" ]; then
    cat $convertdir/${ith}/${TIMEf}/fcstgp/mean.grd >> $outdir/${TIMEf}/fcstgp/mean.grd
  else
    alldone=0
    break
  fi
done

if ((alldone == 1)); then
  line_replaced=$(grep 'tdef' $convertdir/1/${TIMEf}/ctl/fcstgp_mean.ctl)
  line_new="tdef $tnum $(echo $line_replaced | cut -d ' ' -f3-)"
  mkdir -p $outdir/${TIMEf}/ctl
  sed "s/${line_replaced}/${line_new}/" $convertdir/1/${TIMEf}/ctl/fcstgp_mean.ctl > $outdir/${TIMEf}/ctl/fcstgp_mean.ctl

  now=`date -u +'%Y-%m-%d %H:%M:%S'`
  echo "$now [DONE] $TIMEf - Convert to GrADS completed" >> $logfile
fi

#----

now=`date -u +'%Y-%m-%d %H:%M:%S'`
echo "$now [RUN ] $TIMEf - Plot" >> $logfile

mkdir -p $plotdir/out
rm -fr $plotdir/out/*
cd $plotdir

ito=0
for ith in $(seq $threads); do
  if ((ith <= tnum_mod)); then
    itstart=$((ito + 1))
    itend=$((ito + tnum_div + 1))
    echo "Process #${ith}: slot [$ito - $((ito + tnum_div))]" >> $outfile
    ito=$((ito + tnum_div + 1))
  else
    itstart=$((ito + 1))
    itend=$((ito + tnum_div))
    echo "Process #${ith}: slot [$ito - $((ito + tnum_div - 1))]" >> $outfile
    ito=$((ito + tnum_div))
  fi

  grads -blc "plot_driver_6h.gs $outdir/${TIMEf}/ctl/fcstgp_mean.ctl $itstart $itend 1" \
        > /dev/null 2>&1 &
#        > plot_driver_6h_${ith}.log &
  sleep 1s
done
wait

cd $wkdir

#----

mkdir -p $outdir/${TIMEf}/fcstgpi/mean

alldone=1
itfcst=0
#itime="$TIME"
for itplot in $(seq $tnum); do
#  itimef=$(date -ud "$itime" '+%Y%m%d%H%M%S')
#  itimef2=$(date -ud "$itime" '+%Y%m%d%H')
  itfcstf=$(printf '%06d' $itfcst)
#  echo "[$itimef]"

  for prefix in $figlist; do
    if [ -s "$plotdir/out/${prefix}_f${itfcstf}.png" ]; then
      mv -f $plotdir/out/${prefix}_f${itfcstf}.png $outdir/${TIMEf}/fcstgpi/mean
    else
      alldone=0
    fi
    if [ -s "$plotdir/out/${prefix}_f${itfcstf}.eps" ]; then
      mv -f $plotdir/out/${prefix}_f${itfcstf}.eps $outdir/${TIMEf}/fcstgpi/mean
    else
      alldone=0
    fi
  done

  itfcst=$((itfcst+tint))
#  itime="$(date -ud "$tint second $itime" +'%Y-%m-%d %H:%M:%S')"
done

rsync -avz $outdir/${TIMEf}/fcstgpi/mean/*.png ${web_fmdir}/${TIMEf} >> $outfile 2>&1

now=`date -u +'%Y-%m-%d %H:%M:%S'`
if ((alldone == 1)); then
  echo "$now [DONE] $TIMEf" >> $logfile
else
  echo "$now [DONE] $TIMEf - Some error occured" >> $logfile
fi

rm -f $lockfile
