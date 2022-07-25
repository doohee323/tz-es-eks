#!/usr/bin/env bash

#https://phoenixnap.com/kb/elasticsearch-helm-chart
#https://www.elastic.co/guide/en/elasticsearch/reference/7.1/configuring-tls-docker.html

#bash /vagrant/tz-local/resource/elk/install.sh
cd /vagrant/tz-local/resource/elk/reindex

shopt -s expand_aliases

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
admin_password=$(prop 'project' 'admin_password')
NS=elk

apt-get install tzdata -y

kubectl -n devops-dev delete -f copy-volume.yaml
kubectl -n devops-dev delete -f copy-ubuntu.yaml

kubectl -n devops-dev apply -f copy-volume.yaml
kubectl -n devops-dev apply -f copy-ubuntu.yaml

# upload aws, k8s credentials
kubectl -n devops-dev cp /home/vagrant/.aws devops-dev/bastion:/root/.aws
kubectl -n devops-dev cp /home/vagrant/.kube devops-dev/bastion:/root/.kube
kubectl -n devops-dev cp /home/vagrant/.ssh devops-dev/bastion:/root/.ssh
#kubectl -n devops-dev cp /vagrant/terraform-aws-eks/resource/8.zip devops-dev/bastion:/data

bash pipeline_current_index.sh
bash pipeline_new_index.sh

kubectl -n devops-dev exec -it bastion -- sh

apt-get update && apt install systemd curl netcat dnsutils telnet -y
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
#/vagrant/tz-local/resource/elk/reindex/reindex_test.yml

kubectl -n devops-dev exec -it bastion -- mkdir -p /data/current
#kubectl -n devops-dev exec -it bastion -- mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml_bak
kubectl cp env.sh devops-dev/bastion:/data/env.sh
kubectl -n devops-dev exec -it bastion -- bash /data/env.sh
kubectl cp filebeat_current.yml devops-dev/bastion:/etc/filebeat/filebeat.yml
kubectl -n devops-dev exec -it bastion -- chown root:root /etc/filebeat/filebeat.yml
kubectl -n devops-dev exec -it bastion -- filebeat -e -d "*"

kubectl cp test.sh devops-dev/bastion:/data

kubectl cp filebeat_new.yml devops-dev/bastion:/etc/filebeat02/filebeat.yml
kubectl -n devops-dev exec -it bastion -- chown root:root /etc/filebeat02/filebeat.yml

kubectl -n devops-dev exec -it bastion -- filebeat -e -d "*" \
  --path.home /usr/share/filebeat02 \
  --path.config /etc/filebeat02 \
  --path.data /var/lib/filebeat02 \
  --path.logs /var/log/filebeat02

kubectl -n devops-dev exec -it bastion -- /bin/bash /data/test.sh current
kubectl -n devops-dev exec -it bastion -- /bin/bash /data/test.sh new
#kubectl -n devops-dev exec -it bastion -- /usr/bin/nohup /bin/bash /data/test.sh current 2>&1 &
#kubectl -n devops-dev exec -it bastion -- /usr/bin/nohup /bin/bash /data/test.sh new 2>&1 &

#ps -ef | grep test
# echo "doohee,1,2021-11-26 00:00:00" >> /data/log/test-20211126.log
# echo "doohee,2,2021-11-26 00:00:01" >> /data/log/test-20211126.log
# echo "doohee,3,2021-11-26 00:00:02" >> /data/log/test-20211126.log
echo `date +%Y%m%d`

timedatectl set-timezone America/Los_Angeles --adjust-system-clock

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#filebeat run -e
#rm -Rf /var/lib/filebeat/registry

kubectl cp /vagrant/tz-local/resource/elk/reindex/filebeat.yml devops-dev/bastion:/etc/filebeat
kubectl cp /vagrant/tz-local/resource/elk/reindex/import.sh devops-dev/bastion:/data
kubectl -n devops-dev exec -it bastion -- bash /data/import.sh ${admin_password} ${CSV_URL}

#kubectl cp /vagrant/terraform-aws-eks/resource/10.zip devops-dev/bastion:/data/csv
#kubectl -n devops-dev exec -it bastion -- chown -Rf root:root /data/csv
#
#kubectl -n devops-dev cp /vagrant/terraform-aws-eks/resource/9.zip devops-dev/bastion:/data
#kubectl -n devops-dev exec -it bastion -- tar xvfz /data/9.zip -C /data/csv



