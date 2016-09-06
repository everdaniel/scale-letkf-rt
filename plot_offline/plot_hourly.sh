#!/bin/bash -l

tsteps=21
tint=21600
stncode='63518'
stnname='Kobe'
fcststncode='332_0'

#----

wkdir="$(cd "$( dirname "$0" )" && pwd)"

lockfile="$wkdir/plot_hourly.lock"
logfile="$wkdir/plot_hourly.log"
outfile="$wkdir/plot_hourly.out"
plotdir="$wkdir/python"
web_fmdir="bowmore:/srv/www/htdocs/scale/fm"

#----

cd ${wkdir}

now=$(date -u +'%Y-%m-%d %H:%M:%S')
echo "$now [RUN ] Start hourly potting" >> $logfile

if [ -e "$lockfile" ]; then
  echo "$now [Err ] A previous job exists" >> $logfile
  exit
fi
touch $lockfile
rm -f $outfile

#----

alldone=1

cd $plotdir

now=$(date -u +'%Y-%m-%d %H:%M:%S')
YYYYMMDD="$(date -ud "$now" +'%Y-%m-%d')"
HH="$(date -ud "$now" +'%H')"
hour=$((10#$HH))
hourstart=$((hour - hour % 6))
TIME="$(date -ud "$YYYYMMDD $hourstart" +'%Y-%m-%d %H:%M:%S')"
TIMEf="$(date -ud "$TIME" +'%Y%m%d%H%M%S')"
for i in $(seq $tsteps); do
  now=$(date -u +'%Y-%m-%d %H:%M:%S')
  echo "$now [RUN ] $TIMEf " >> $logfile

  python3 plot_forecast.py $TIMEf $stncode $stnname $fcststncode >> $outfile 2>&1

  if [ -s "stn_${stncode}_temp.png" ]; then
    rsync -av stn_${stncode}_temp.png ${web_fmdir}/${TIMEf}/stn_${stncode}_temp.png >> $outfile 2>&1
    rm -f stn_${stncode}_temp.png
  fi

  TIME="$(date -ud "- $tint second $TIME" +'%Y-%m-%d %H:%M:%S')"
  TIMEf="$(date -ud "$TIME" +'%Y%m%d%H%M%S')"
done

cd $wkdir

#----

now=$(date -u +'%Y-%m-%d %H:%M:%S')
if ((alldone == 1)); then
  echo "$now [DONE]" >> $logfile
else
  echo "$now [DONE] - Some error occured" >> $logfile
fi

rm -f $lockfile
