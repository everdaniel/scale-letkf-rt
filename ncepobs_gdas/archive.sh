#!/bin/sh
#-------------------------------------------------------------------------------

START_TIME="2013-09-29 00:00:00"
END_TIME="2013-12-01 18:00:00"
PERIOD=21600

time=`date -u -d "${START_TIME}" +'%Y-%m-%d %H:%M:%S'`
timef=`date -u -d "${time}" +'%Y%m%d%H'`
while [ `date -u -d "${time}" +'%s'` -le `date -u -d "${END_TIME}" +'%s'` ]; do

  echo "[${timef}]"
  tar -czpf ${timef}.tar.gz ${timef}

  rm -rf ${timef}

time=`date -u -d "${PERIOD} second ${time}" +'%Y-%m-%d %H:%M:%S'`
timef=`date -u -d "${time}" +'%Y%m%d%H'`
done
