#!/bin/bash

tt="$1"
prepbufrdir="$2"
outdir="$3"

#tt='2015-05-07 06'
#prepbufrdir='/data7/gylien/realtime/ncepobs_gdas/2015050706'
#outdir='/data7/gylien/realtime/ncepobs_gdas_letkf/2015050706'

BUFRBIN="/data/opt/bufrlib/10.1.0_intel/bin"

#----

wkdir="$( cd "$( dirname "$0" )" && pwd )"
cd ${wkdir}

timef=$(date -ud "$tt" '+%Y-%m-%d %H')
timef2=$(date -ud "$tt" '+%Y%m%d%H%M%S')
timef3=$(date -ud "$tt" '+%Y%m%d%H')
echo "[$timef]"

rm -f prepbufr.in fort.90

file="$prepbufrdir/prepbufr.${timef3}"
wc -c "$file" | $BUFRBIN/grabbufr "$file" prepbufr.in

./dec_prepbufr
touch fort.90
mkdir -p $outdir
mv fort.90 $outdir/obs_${timef2}.dat
