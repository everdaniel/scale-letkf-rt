#!/bin/bash -l

timestart="$1"

#timestart="2015-05-08 00:00:00"

tstart=0
tend=120
tskip=6
threads=21
tint=21600

figlist='sfc_prcp sfc_wind sfc_2mtemp sfc_temp sfc_aprcp sfc_asnow 850_temp 700_vvel 500_vort 300_wspd olr_ir max_ref'

#----

wkdir="$(cd "$( dirname "$0" )" && pwd)"

lockfile="$wkdir/plot.lock"
logfile="$wkdir/plot.log"
outfile="$wkdir/plot.out"
plotdir="$wkdir/run/grads"
outdir="$(cd "$wkdir/../exp/EastAsia_18km_48p" && pwd)"
web_fmdir="bowmore:/home/gylien/public_html/scale/data/ctl"

#----

cd ${wkdir}

while [ -e "$lockfile" ]; do
  sleep 10s
done
touch $lockfile

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
echo "$now [RUN ] $TIMEf - Convert to GrADS (gues/anal) using 5 threads" >> $logfile

mpirun 5 python3 $wkdir/convert_letkfout.py "$outdir" "$TIMEf" \
        > $wkdir/convert_letkfout.log 2>&1

now=`date -u +'%Y-%m-%d %H:%M:%S'`
echo "$now [RUN ] $TIMEf - Convert to GrADS (fcst) using $threads threads" >> $logfile

mpirun $threads python3 $wkdir/convert_letkfout_fcst.py "$outdir" "$TIMEf" \
                        > $wkdir/convert_letkfout_fcst.log 2>&1

if [ -s "$outdir/${TIMEf}/fcstgp/mean.grd" ]; then
  now=`date -u +'%Y-%m-%d %H:%M:%S'`
  echo "$now [DONE] $TIMEf - Convert to GrADS completed" >> $logfile
fi

#----

now=`date -u +'%Y-%m-%d %H:%M:%S'`
echo "$now [RUN ] $TIMEf - ANN forecasts" >> $logfile

cd $wkdir/../station/ANN-160208
/home/gulan/anaconda3/bin/python AnnForecast.py --time "$TIMEf"
cd ${wkdir}

if [ -s "$wkdir/../station/ANN-160208/forecast/63518.${TIMEf}.ann" ]; then
  now=`date -u +'%Y-%m-%d %H:%M:%S'`
  echo "$now [DONE] $TIMEf - ANN forecasts completed" >> $logfile
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

for prefix in $figlist; do
  mkdir -p $outdir/${TIMEf}/fcstgpi/mean/${prefix}
done

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
      mv -f $plotdir/out/${prefix}_f${itfcstf}.png $outdir/${TIMEf}/fcstgpi/mean/${prefix}
    else
      alldone=0
    fi
    if [ -s "$plotdir/out/${prefix}_f${itfcstf}.eps" ]; then
      mv -f $plotdir/out/${prefix}_f${itfcstf}.eps $outdir/${TIMEf}/fcstgpi/mean/${prefix}
    else
      alldone=0
    fi
  done

  itfcst=$((itfcst+tint))
#  itime="$(date -ud "$tint second $itime" +'%Y-%m-%d %H:%M:%S')"
done

rsync -avz --include="*/" --include="*.png" --exclude="*" $outdir/${TIMEf}/fcstgpi/mean/ ${web_fmdir}/${TIMEf} >> $outfile 2>&1

now=`date -u +'%Y-%m-%d %H:%M:%S'`
if ((alldone == 1)); then
  echo "$now [DONE] $TIMEf" >> $logfile
else
  echo "$now [DONE] $TIMEf - Some error occured" >> $logfile
fi

rm -f $lockfile
