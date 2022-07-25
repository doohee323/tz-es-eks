#!/usr/bin/env bash

mkdir -p /data/current
#mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml_bak
chown root:root /etc/filebeat/filebeat.yml
rm -Rf /var/lib/filebeat/filebeat.lock
filebeat test config -e -c /etc/filebeat/filebeat.yml

rm -Rf /var/log/filebeat02
rm -Rf /etc/filebeat02
rm -Rf /var/lib/filebeat02
rm -Rf /usr/share/filebeat02

mkdir -p /var/log/filebeat02
cp -Rf /etc/filebeat /etc/filebeat02
cp -Rf /var/lib/filebeat /var/lib/filebeat02
cp -Rf /usr/share/filebeat /usr/share/filebeat02

mkdir -p /data/new
chown root:root /etc/filebeat02/filebeat.yml
rm -Rf /var/lib/filebeat02/filebeat.lock
filebeat test config -e -c /etc/filebeat02/filebeat.yml

