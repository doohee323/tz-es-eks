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

kubectl -n devops-dev delete -f ubuntu.yaml
kubectl -n devops-dev apply -f ubuntu.yaml

sleep 30

# upload aws, k8s credentials
kubectl -n devops-dev cp /home/vagrant/.aws devops-dev/bastion:/root/.aws
kubectl -n devops-dev cp /home/vagrant/.kube devops-dev/bastion:/root/.kube
kubectl -n devops-dev cp /home/vagrant/.ssh devops-dev/bastion:/root/.ssh

# make pipeline
bash pipeline_current_index.sh
bash pipeline_new_index.sh

# apply processor
# make a template
#/vagrant/tz-local/resource/elk/reindex/reindex_test.yml

kubectl -n devops-dev exec -it bastion -- /bin/mkdir /data
kubectl cp test.sh devops-dev/bastion:/data

kubectl cp env.sh devops-dev/bastion:/data/env.sh
kubectl -n devops-dev exec -it bastion -- bash /data/env.sh
kubectl cp filebeat_current.yml devops-dev/bastion:/etc/filebeat/filebeat.yml
kubectl -n devops-dev exec -it bastion -- chown root:root /etc/filebeat/filebeat.yml

kubectl cp filebeat_new.yml devops-dev/bastion:/etc/filebeat02/filebeat.yml
kubectl -n devops-dev exec -it bastion -- chown root:root /etc/filebeat02/filebeat.yml

exit 0

# run filebeat for current
kubectl -n devops-dev exec -it bastion -- filebeat -e -d "*"
kubectl -n devops-dev exec -it bastion -- /bin/bash /data/test.sh current

# run filebeat for new
kubectl -n devops-dev exec -it bastion -- filebeat -e -d "*" \
  --path.home /usr/share/filebeat02 \
  --path.config /etc/filebeat02 \
  --path.data /var/lib/filebeat02 \
  --path.logs /var/log/filebeat02
kubectl -n devops-dev exec -it bastion -- /bin/bash /data/test.sh new

#kubectl -n devops-dev exec -it bastion -- sh
#kubectl -n devops-dev exec -it bastion -- /usr/bin/nohup /bin/bash /data/test.sh current 2>&1 &
#kubectl -n devops-dev exec -it bastion -- /usr/bin/nohup /bin/bash /data/test.sh new 2>&1 &

