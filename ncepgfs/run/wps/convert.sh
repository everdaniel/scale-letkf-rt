#!/bin/bash

tstart="$1"
tend="$2"
gribfile_prefix="$3"

#tstart='2015-05-05 18'
#tend='2015-05-06 00'
#gribfile_prefix='/data5/gylien/realtime/ncepgfs/2015050518/gfs'

tint=21600

#----

wkdir="$( cd "$( dirname "$0" )" && pwd )"
cd ${wkdir}

timef=$(date -ud "$tstart" '+%Y-%m-%d %H')
time2f=$(date -ud "$tend" '+%Y-%m-%d %H')
echo "[$timef] - [$time2f]"

YYYYs=$(date -ud "$tstart" '+%Y')
MMs=$(date -ud "$tstart" '+%m')
DDs=$(date -ud "$tstart" '+%d')
HHs=$(date -ud "$tstart" '+%H')
YYYYe=$(date -ud "$tend" '+%Y')
MMe=$(date -ud "$tend" '+%m')
DDe=$(date -ud "$tend" '+%d')
HHe=$(date -ud "$tend" '+%H')

cat namelist.wps.src | \
sed -e "s/\[YYYYs\]/$YYYYs/" \
    -e "s/\[MMs\]/$MMs/" \
    -e "s/\[DDs\]/$DDs/" \
    -e "s/\[HHs\]/$HHs/" \
    -e "s/\[YYYYe\]/$YYYYe/" \
    -e "s/\[MMe\]/$MMe/" \
    -e "s/\[DDe\]/$DDe/" \
    -e "s/\[HHe\]/$HHe/" \
> namelist.wps

rm -f FILE* met_em.d01.*

./geogrid.exe
./rmter.exe
./link_grib.csh ${gribfile_prefix}.*
./ungrib.exe
./metgrid.exe
