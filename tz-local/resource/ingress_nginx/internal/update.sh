#!/usr/bin/env bash

#https://box0830.tistory.com/311
#bash /vagrant/tz-local/resource/ingress_nginx/internal/update.sh extension-dev es-eks-w tztest.com

cd /vagrant/tz-local/resource/ingress_nginx/internal

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}

NS=$1
if [[ "${NS}" == "" ]]; then
  NS=devops
fi
eks_project=$2
if [[ "${eks_project}" == "" ]]; then
  eks_project=$(prop 'project' 'project')
fi
eks_domain=$3
if [[ "${eks_domain}" == "" ]]; then
  eks_domain=$(prop 'project' 'domain')
fi
HOSTZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '${eks_domain}.']" | grep '"Id"'  | awk '{print $2}' | sed 's/\"//g;s/,//' | cut -d'/' -f3)
echo $HOSTZONE_ID

#set -x
shopt -s expand_aliases
alias k="kubectl -n ${NS} --kubeconfig ~/.kube/config"

#kubectl delete ns ${NS}
kubectl create ns ${NS}

DEVOPS_ELB=$(kubectl -n devops get svc | grep ingress-nginx-internal-controller | grep LoadBalancer | head -n 1 | awk '{print $4}')
if [[ "${DEVOPS_ELB}" == "" ]]; then
  echo "No elb! check nginx-ingress-controller with LoadBalancer type!"
  exit 1
fi
#sleep 20
echo "DEVOPS_ELB: $DEVOPS_ELB"
# Creates route 53 records based on DEVOPS_ELB
CUR_ELB=$(aws route53 list-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} --query "ResourceRecordSets[?Name == '\\052.${NS}-internal.${eks_project}.${eks_domain}.']" | grep 'Value' | awk '{print $2}' | sed 's/"//g')
echo "CUR_ELB: $CUR_ELB"
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
 --change-batch '{ "Comment": "'"${eks_project}"' utils", "Changes": [{"Action": "DELETE", "ResourceRecordSet": {"Name": "*.'"${NS}-internal"'.'"${eks_project}"'.'"${eks_domain}"'", "Type": "CNAME", "TTL": 120, "ResourceRecords": [{"Value": "'"${CUR_ELB}"'"}]}}]}'
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTZONE_ID} \
 --change-batch '{ "Comment": "'"${eks_project}"' utils", "Changes": [{"Action": "CREATE", "ResourceRecordSet": { "Name": "*.'"${NS}-internal"'.'"${eks_project}"'.'"${eks_domain}"'", "Type": "CNAME", "TTL": 120, "ResourceRecords": [{"Value": "'"${DEVOPS_ELB}"'"}]}}]}'

kubectl apply -f ingress-nginx-configmap.yaml -n ${NS}
#kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission -n ${NS}

#k delete deployment nginx
#k create deployment nginx --image=nginx
#k delete svc/nginx
##k port-forward deployment/nginx 80
##k expose deployment/nginx --port 80 --type LoadBalancer
#k expose deployment/nginx --port 80

cp -Rf nginx-ingress.yaml nginx-ingress.yaml_bak
sed -i "s|NS|${NS}|g" nginx-ingress.yaml_bak
sed -i "s/eks_project/${eks_project}/g" nginx-ingress.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" nginx-ingress.yaml_bak
k delete -f nginx-ingress.yaml_bak -n ${NS}
k delete ingress $(k get ingress nginx-test-internal-tls -n ${NS}) -n ${NS}
k delete svc nginx -n ${NS}
k apply -f nginx-ingress.yaml_bak -n ${NS}
curl -v http://test.${NS}-internal.${eks_project}.${eks_domain}
#sleep 30
echo curl http://test.${NS}-internal.${eks_project}.${eks_domain}
k delete -f nginx-ingress.yaml_bak

#### https ####

cp -Rf nginx-ingress-https.yaml nginx-ingress-https.yaml_bak
sed -i "s/NS/${NS}/g" nginx-ingress-https.yaml_bak
sed -i "s/eks_project/${eks_project}/g" nginx-ingress-https.yaml_bak
sed -i "s/eks_domain/${eks_domain}/g" nginx-ingress-https.yaml_bak
k delete -f nginx-ingress-https.yaml_bak -n ${NS}
k delete ingress nginx-test-internal-tls -n ${NS}
k apply -f nginx-ingress-https.yaml_bak -n ${NS}
kubectl get csr -o name | xargs kubectl certificate approve
k apply -f nginx-ingress-https.yaml_bak -n ${NS}
curl -v http://test.${NS}-internal.${eks_project}.${eks_domain}
curl -v https://test.${NS}-internal.${eks_project}.${eks_domain}
#sleep 10
echo curl http://test.${NS}-internal.${eks_project}.${eks_domain}
echo curl https://test.${NS}-internal.${eks_project}.${eks_domain}

exit 0

