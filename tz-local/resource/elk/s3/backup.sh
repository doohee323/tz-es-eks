#!/usr/bin/env bash

cd /vagrant/tz-local/resource/elk/s3

set -x

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}

export AWS_ACCESS_KEY_ID=$(prop 'credentials' 'aws_access_key_id')
export AWS_SECRET_ACCESS_KEY=$(prop 'credentials' 'aws_secret_access_key')
export AWS_REGION=$(prop 'config' 'region')
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
admin_password=$(prop 'project' 'admin_password')
NS=elk

aws_account_id=$(aws sts get-caller-identity --query Account --output text)

id_password="elastic:${admin_password}"
echo ${id_password}
ES_URL="es.${NS}.${eks_project}.${eks_domain}"

policy_name="tz-aws-usage"

aws iam create-policy \
    --policy-name ${policy_name} \
    --policy-document file://iam_role_policy_s3.json

aws iam create-role --role-name tz-aws-usage --assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Sid": "", "Effect": "Allow", "Principal": {"Service": "es.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'

curl -XPUT -u ${id_password} \
${ES_URL}/_snapshot/tz-aws-usage \
-H 'Content-Type: application/json' \
-d '{
	"type": "s3",
	"settings": {
    "bucket": "tz-aws-usage",
    "region": "ap-northeast-2",
    "client": "default",
    "role_arn": "arn:aws:iam::'${aws_account_id}':role/tz-aws-usage",
    "compress": true
	}
}'

#kubectl -n elk exec -it $(kubectl -n elk get pod | grep elasticsearch-master-0 | awk '{print $1}') -- sh
#  elasticsearch-keystore remove s3.client.default.access_key
#  elasticsearch-keystore remove s3.client.default.secret_key
#
#  elasticsearch-keystore add s3.client.default.access_key
#  elasticsearch-keystore add s3.client.default.secret_key
#  elasticsearch-keystore list
#
#  POST _nodes/reload_secure_settings

aws iam create-role --role-name tz-aws-usage \
  --assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Sid": "", "Effect": "Allow", "Principal": {"Service": "es.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
















