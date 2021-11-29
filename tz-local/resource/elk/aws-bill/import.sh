#!/usr/bin/env bash

#set -x

chown root:root /etc/filebeat/filebeat.yml
rm /var/lib/filebeat/filebeat.lock

#CSV_URL="https://s3.ap-northeast-1.amazonaws.com/dohwan.bill.userdata/user_report/472304975363-2021-10-AWS-Detail.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIA6AAO24AX2OEQQ33I%2F20211008%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20211008T233644Z&X-Amz-Expires=21600&X-Amz-Signature=0ce93e222f5f7114a12747a541d80cfec450c7d9061c765b35d9c0f0a6774d72&X-Amz-SignedHeaders=host"
CSV_URL=$2
PASSWD=$1
MONTH=`date +%m`
curl ${CSV_URL} -o /data/${MONTH}.csv
echo "############################################ 1"

mkdir -p /data/csv
rm /data/csv/*
ls -al /data/csv

mv /data/${MONTH}.csv /data/csv
echo "############################################ 2"

rm -Rf /var/lib/filebeat/registry
kill -9 `ps | grep filebeat | awk '{print $1}'`
echo "############################################ 3"

INDEX_NAME=filebeat-7.13.2-`date +%Y.%m`
echo "INDEX_NAME: ${INDEX_NAME}"
ES_URL=elasticsearch-master.elk.svc.cluster.local
curl --insecure curl -XDELETE https://elastic:${PASSWD}@${ES_URL}:9200/${INDEX_NAME}*
echo "############################################ 4"

sleep 10

filebeat run
#filebeat run -e








