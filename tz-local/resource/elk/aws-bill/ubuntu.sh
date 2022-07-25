#!/usr/bin/env bash

#https://phoenixnap.com/kb/elasticsearch-helm-chart
#https://www.elastic.co/guide/en/elasticsearch/reference/7.1/configuring-tls-docker.html

#bash /vagrant/tz-local/resource/elk/install.sh
cd /vagrant/tz-local/resource/elk/aws-bill

shopt -s expand_aliases

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
admin_password=$(prop 'project' 'admin_password')
NS=elk

kubectl -n devops-dev delete -f copy-volume.yaml
kubectl -n devops-dev delete -f copy-ubuntu.yaml

kubectl -n devops-dev apply -f copy-volume.yaml
kubectl -n devops-dev apply -f copy-ubuntu.yaml

# upload aws, k8s credentials
kubectl -n devops-dev cp /home/vagrant/.aws devops-dev/bastion:/root/.aws
kubectl -n devops-dev cp /home/vagrant/.kube devops-dev/bastion:/root/.kube
kubectl -n devops-dev cp /home/vagrant/.ssh devops-dev/bastion:/root/.ssh
#kubectl -n devops-dev cp /vagrant/terraform-aws-eks/resource/8.zip devops-dev/bastion:/data

kubectl -n devops-dev exec -it bastion -- sh

apt-get update && apt install curl netcat dnsutils telnet -y
export STACK_VERSION=7.13.2
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${STACK_VERSION}-amd64.deb
dpkg -i filebeat-${STACK_VERSION}-amd64.deb

telnet elasticsearch-master.elk.svc.cluster.local 9200

filebeat modules list
filebeat modules enable system nginx mysql logstash
filebeat modules disable system nginx mysql logstash
filebeat setup -e
cd /etc/filebeat/modules.d
filebeat test config -e

# apply processor
# make a template
#/vagrant/tz-local/resource/elk/aws-bill/es.yml
kubectl -n devops-dev exec -it bastion -- mkdir -p /etc/filebeat/inputs.d
kubectl -n devops-dev exec -it bastion -- mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml_bak

cp -Rf filebeat.yaml filebeat.yml_bak
sed -i "s/admin_password/${admin_password}/g" filebeat.yml_bak
kubectl cp filebeat.yml_bak devops-dev/bastion:/etc/filebeat
kubectl -n devops-dev exec -it bastion -- chown root:root /etc/filebeat/filebeat.yml

kubectl -n devops-dev exec -it bastion -- rm /var/lib/filebeat/filebeat.lock
kubectl -n devops-dev exec -it bastion -- filebeat test config -e
kubectl -n devops-dev exec -it bastion -- filebeat run -e -d "*"
#filebeat run -e

rm -Rf /var/lib/filebeat/registry
filebeat run -e -d "*"

mv /data/csv2/*.csv /data/csv
head -n 20 /data/csv2/472304975363-202105.csv > /data/csv/472304975363-202105.csv

kubectl cp /vagrant/tz-local/resource/elk/aws-bill/filebeat.yml devops-dev/bastion:/etc/filebeat
kubectl cp /vagrant/tz-local/resource/elk/aws-bill/import.sh devops-dev/bastion:/data
kubectl -n devops-dev exec -it bastion -- bash /data/import.sh ${admin_password} ${CSV_URL}

#kubectl cp /vagrant/terraform-aws-eks/resource/10.zip devops-dev/bastion:/data/csv
#kubectl -n devops-dev exec -it bastion -- chown -Rf root:root /data/csv
#
#kubectl -n devops-dev cp /vagrant/terraform-aws-eks/resource/9.zip devops-dev/bastion:/data
#kubectl -n devops-dev exec -it bastion -- tar xvfz /data/9.zip -C /data/csv
