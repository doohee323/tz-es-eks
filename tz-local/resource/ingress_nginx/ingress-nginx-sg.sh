#!/usr/bin/env bash

#bash /vagrant/tz-local/resource/ingress_nginx/ingress-nginx-sg.sh
#cd /vagrant/tz-local/resource/ingress_nginx

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}

eks_project=$(prop 'project' 'project')
pushd `pwd`
cd /vagrant/terraform-aws-eks/workspace/base
vpc_cidr_block=$(terraform output | grep vpc_cidr_block | awk '{print $3}')
popd

SOURCES=(218.153.127.33/32:office 3.35.170.100/32:jenkins 98.234.34.27/32:doohee-home 20.10.0.0/16:devops-util ${vpc_cidr_block}:${eks_project})

# 1. find "nginx" or "nginx-internal" type ingresses   --all-namespaces
SECURITY_GROUP=()
INGRESS=($(kubectl get ingress --all-namespaces | awk '{print $1"|"$2}'))
for str in "${INGRESS[@]}"; do
  if [[ "${str}" != "NAMESPACE|NAME" ]]; then
    item=($(echo ${str} | tr '|' ' '))
    tmp=`kubectl get ingress ${item[1]} -n ${item[0]} -o json \
      | jq '.metadata.annotations' \
      | grep -e '"kubernetes.io/ingress.class": "nginx-internal"' -e '"kubernetes.io/ingress.class": "nginx"'`
    if [[ "${tmp}" != "" ]]; then
      ing=`kubectl get ing ${item[1]} -n ${item[0]} | awk '{print $4}' | tail -n 1`
      elb=`echo ${ing} | awk -F'.' '{ print $1 }' | awk -F'-' '{ for(i=1;i<=NF;i++) print $i }' | head -n -1 | tr '\n' '-'`
      if [[ "${elb}" != "" ]]; then
        elb=${elb::-1}
        securityGroup=`aws elb describe-load-balancers --load-balancer-names ${elb} | grep SecurityGroups -A 1 | tail -n 1 | awk '{print $1}' | sed 's/\"//g'`
        if [[ "${securityGroup}" == "" ]]; then
          securityGroup=`aws elbv2 describe-load-balancers --names ${elb} | grep SecurityGroups -A 1 | tail -n 1 | awk '{print $1}' | sed 's/\"//g'`
          echo securityGroup: ${securityGroup}
        fi
        if [[ " ${SECURITY_GROUP[@]} " =~ " ${securityGroup} " ]]; then
          echo "searching..."
        else
          SECURITY_GROUP[${#SECURITY_GROUP[@]}]=${securityGroup}
        fi
      fi
    fi
  fi
done
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#SECURITY_GROUP=(sg-0f3402293584d3c32)
#SOURCES=(98.234.34.27/32:doohee-home 20.10.0.0/16:devops-util 10.40.0.0/16:es-eks-a)
for securityGroup in "${SECURITY_GROUP[@]}"; do
    echo "securityGroup: ${securityGroup}"
    aws ec2 revoke-security-group-ingress --group-id ${securityGroup} \
      --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 revoke-security-group-ingress --group-id ${securityGroup} \
      --protocol tcp --port 443 --cidr 0.0.0.0/0

    for str in "${SOURCES[@]}"; do
      item=($(echo ${str} | tr ':' ' '))
      aws ec2 authorize-security-group-ingress --group-id ${securityGroup} \
        --ip-permissions "IpProtocol"="tcp","FromPort"=80,"ToPort"=80,"IpRanges"="[{CidrIp=${item[0]},Description=${item[1]}}]"
      aws ec2 authorize-security-group-ingress --group-id ${securityGroup} \
        --ip-permissions "IpProtocol"="tcp","FromPort"=443,"ToPort"=443,"IpRanges"="[{CidrIp=${item[0]},Description=${item[1]}}]"
    done
done

#      aws ec2 revoke-security-group-ingress --group-id ${securityGroup} \
#      --ip-permissions "IpProtocol"="tcp","FromPort"=443,"ToPort"=443,"IpRanges"="[{CidrIp=${IP}/32,Description=${DESC}}]"
