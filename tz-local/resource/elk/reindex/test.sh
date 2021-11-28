#!/usr/bin/env bash

INDEX=$1
CNT=0
TZ='America/Los_Angeles'
while true; do
  echo "${INDEX},${CNT},`date '+%Y-%m-%d %H:%M:%S'`" >> /data/${INDEX}/${INDEX}-`date +%Y%m%d`.log
  sleep 1
  CNT=$((CNT+1))
done
