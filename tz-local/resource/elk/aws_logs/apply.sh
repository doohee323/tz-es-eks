#!/usr/bin/env bash

# https://www.elastic.co/blog/getting-aws-logs-from-s3-using-filebeat-and-the-elastic-stack
cd /vagrant/tz-local/resource/elk/aws_logs

shopt -s expand_aliases

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
admin_password=$(prop 'project' 'admin_password')
aws_access_key_id=$(prop 'credentials' 'aws_access_key_id')
aws_secret_access_key=$(prop 'credentials' 'aws_secret_access_key')
NS=elk

kubectl -n elk apply -f ubuntu.yaml

# s3_sqs.tf
# - elblog
#aws s3 ls | grep elbaccess-bucket
#aws sqs list-queues --region=ap-northeast-2 | grep elbaccess-event-queue
#aws s3 cp myfile.log s3://elbaccess-bucket-gao1
#aws s3 ls s3://elbaccess-bucket-gao1
#aws sqs --region ap-northeast-2 receive-message --queue-url https://ap-northeast-2.queue.amazonaws.com/472304975363/elbaccess-event-queue
# - s3accesslog
#aws s3 ls | grep s3access-bucket
#aws sqs list-queues --region=ap-northeast-2 | grep s3access-event-queue
#aws s3 cp s3access.log s3://s3access-bucket-gao1
#aws s3 ls s3://s3access-bucket-gao1
#aws sqs --region ap-northeast-2 receive-message --queue-url https://ap-northeast-2.queue.amazonaws.com/472304975363/s3access-event-queue

# upload aws, k8s credentials
kubectl -n elk cp /home/vagrant/.aws elk/elk-bastion:/root/.aws
kubectl -n elk cp /home/vagrant/.kube elk/elk-bastion:/root/.kube
kubectl -n elk cp /home/vagrant/.ssh elk/elk-bastion:/root/.ssh

kubectl -n elk exec -it elk-bastion -- sh

apt-get update && apt install curl netcat dnsutils telnet vim awscli jq unzip -y
curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/aws-iam-authenticator
chmod +x aws-iam-authenticator
mv aws-iam-authenticator /usr/local/bin
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.23.6/bin/linux/amd64/kubectl
chmod 777 kubectl
mv kubectl /usr/bin/kubectl
export STACK_VERSION=7.13.2
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${STACK_VERSION}-amd64.deb
dpkg -i filebeat-${STACK_VERSION}-amd64.deb

telnet elasticsearch-master.elk.svc.cluster.local 9200

filebeat modules list
filebeat modules enable system nginx mysql logstash aws
filebeat setup -e
cd /etc/filebeat/modules.d
filebeat test config -e
#filebeat -e

cp -Rf aws.yml aws.yml_bak
sed -i "s/aws_access_key_id/${aws_access_key_id}/g" aws.yml_bak
sed -i "s/aws_secret_access_key/${aws_secret_access_key}/g" aws.yml_bak
kubectl cp aws.yml_bak elk/elk-bastion:/etc/filebeat/modules.d/aws.yml
kubectl -n elk exec -it elk-bastion -- chown root:root /etc/filebeat/modules.d/aws.yml

## [ ELB log ] ###########################################################################
cd elbaccess
# apply processor
# make a template
# run pipeline_elb.yml
kubectl -n elk exec -it elk-bastion -- mkdir -p /etc/filebeat/inputs.d
kubectl -n elk exec -it elk-bastion -- mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml_bak

cp -Rf filebeat_elbaccess.yml filebeat_elbaccess.yml_bak
sed -i "s/admin_password/${admin_password}/g" filebeat_elbaccess.yml_bak
kubectl cp filebeat_elbaccess.yml_bak elk/elk-bastion:/etc/filebeat/filebeat.yml
kubectl -n elk exec -it elk-bastion -- chown root:root /etc/filebeat/filebeat.yml

kubectl -n elk exec -it elk-bastion -- rm /var/lib/filebeat/filebeat.lock
kubectl -n elk exec -it elk-bastion -- filebeat -c /etc/filebeat/filebeat.yml test config -e
kubectl -n elk exec -it elk-bastion -- filebeat -c /etc/filebeat/filebeat.yml run -e -d "*"
#filebeat run -e
rm -Rf /var/lib/filebeat/registry
#/usr/bin/nohup
filebeat --path.config /etc/filebeat -c /etc/filebeat/filebeat.yml run -e -d "*" 2>&1 &
cd ..

## [ s3access log ] ###########################################################################
cd s3access
# run pipeline_s3access.yml
cp -Rf filebeat_s3access.yml filebeat_s3access.yml_bak
sed -i "s/admin_password/${admin_password}/g" filebeat_s3access.yml_bak
kubectl -n elk exec -it elk-bastion -- cp -Rf  /etc/filebeat /etc/filebeat_s3access
kubectl cp filebeat_s3access.yml_bak elk/elk-bastion:/etc/filebeat_s3access/filebeat.yml
kubectl -n elk exec -it elk-bastion -- chown root:root /etc/filebeat_s3access/filebeat.yml

#kubectl -n elk exec -it elk-bastion -- rm /var/lib/filebeat_s3access/filebeat.lock
kubectl -n elk exec -it elk-bastion -- filebeat --path.config /etc/filebeat_s3access -c /etc/filebeat_s3access/filebeat.yml test config -e
kubectl -n elk exec -it elk-bastion -- filebeat --path.config /etc/filebeat_s3access --path.data /var/lib/filebeat_s3access run -e -d "*"
#filebeat run -e

rm -Rf /var/lib/filebeat/registry

#/usr/bin/nohup
filebeat --path.config /etc/filebeat_s3access --path.data /var/lib/filebeat_s3access run -e -d "*" 2>&1 &
cd ..

## [  cloudfront log ] ###########################################################################
cd cloudfront
# run pipeline_cloudfront.yml
cp -Rf filebeat_cloudfront.yml filebeat_cloudfront.yml_bak
sed -i "s/admin_password/${admin_password}/g" filebeat_cloudfront.yml_bak
kubectl -n elk exec -it elk-bastion -- cp -Rf  /etc/filebeat /etc/filebeat_cloudfront
kubectl cp filebeat_cloudfront.yml_bak elk/elk-bastion:/etc/filebeat_cloudfront/filebeat.yml
kubectl -n elk exec -it elk-bastion -- chown root:root /etc/filebeat_cloudfront/filebeat.yml

#kubectl -n elk exec -it elk-bastion -- rm /var/lib/filebeat_cloudfront/filebeat.lock
kubectl -n elk exec -it elk-bastion -- filebeat --path.config /etc/filebeat_cloudfront -c /etc/filebeat_cloudfront/filebeat.yml test config -e
kubectl -n elk exec -it elk-bastion -- filebeat --path.config /etc/filebeat_cloudfront --path.data /var/lib/filebeat_cloudfront run -e -d "*"
#filebeat run -e

#/usr/bin/nohup
filebeat --path.config /etc/filebeat_cloudfront --path.data /var/lib/filebeat_cloudfront run -e -d "*" 2>&1 &
cd ..



shipping aws-logs to elasticsearch by filebeat and sqs

- aws's access log types
  elbaccess
  cloudfront
  s3access

-

