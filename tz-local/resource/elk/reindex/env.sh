#!/usr/bin/env bash

apt-get update && apt install systemd curl netcat dnsutils telnet -y

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
truncate -s0 /tmp/preseed.cfg; \
  echo "tzdata tzdata/Areas select America" >> /tmp/preseed.cfg; \
  echo "tzdata tzdata/Zones/America select Los_Angeles" >> /tmp/preseed.cfg; \
  debconf-set-selections /tmp/preseed.cfg && \
  rm -f /etc/timezone /etc/localtime && \
  apt-get update && \
  apt-get install tzdata -y

echo "America/Los_Angeles" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

export STACK_VERSION=7.13.2
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${STACK_VERSION}-amd64.deb
dpkg -i filebeat-${STACK_VERSION}-amd64.deb

#telnet elasticsearch-master.elk.svc.cluster.local 9200

filebeat modules list
filebeat modules enable system nginx mysql logstash
filebeat modules disable system nginx mysql logstash
filebeat setup -e
cd /etc/filebeat/modules.d

#filebeat test config -e

echo "#########################################"
echo "env for current"
echo "#########################################"
mkdir -p /data/current
#mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml_bak
chown root:root /etc/filebeat/filebeat.yml
rm -Rf /var/lib/filebeat/filebeat.lock
filebeat test config -e -c /etc/filebeat/filebeat.yml

echo "#########################################"
echo "env for new"
echo "#########################################"
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

