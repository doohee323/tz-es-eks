#!/usr/bin/env bash

# Custom domain lookup on Kubernetes
# https://www.jacobbaek.com/1195

cd /vagrant/tz-local/resource/local-dns

kubectl get pod -n kube-system | grep dns

kubectl describe configmap -n kube-system coredns > coredns.configmap
#
#ping docker.default.es-eks-a.tztest.com
#15.165.109.71
#
#  hosts {
#    15.165.109.71 registry-1.docker.io
#  }
#
kubectl delete pod -n kube-system -l k8s-app=kube-dns

kubectl create pod/nginx -n ${NS}

kubectl run -it busybox --image=ubuntu:16.04 -n ${NS} --overrides='{ "spec": { "nodeSelector": { "team": "devops", "environment": "prod" } } }' -- sh
#cat /etc/resolv.conf
#nameserver 172.20.0.10
#search devops.svc.cluster.local svc.cluster.local cluster.local ap-northeast-2.compute.internal
#options ndots:5

kubectl describe configmap -n kube-system node-local-dns > node-local-dns.configmap
#registry-1.docker.io:53 {
#  errors
#  cache 30
#  reload
#  loop
#  bind 172.20.0.10
#  forward . __PILLAR__CLUSTER__DNS__ {
#          force_tcp
#  }
#  prometheus :9253
#}
kubectl delete pod -n kube-system -l k8s-app=node-local-dns

apt update && apt install curl dnsutils iputils-ping -y
#nslookup registry-1.docker.io
#ping google.com
#ping registry-1.docker.io

exit 0

NS=devops
kubectl run -it busybox --image=ubuntu:16.04 -n ${NS} --overrides='{ "spec": { "nodeSelector": { "team": "'${NS}'", "environment": "prod" } } }' -- sh
apt-get update && apt install curl netcat dnsutils telnet traceroute iputils-ping -y

telnet flanet-prod.cluster-ro-c01spz81v11d.ap-northeast-2.rds.amazonaws.com 5432
telnet devops.cluster-c01spz81v11d.ap-northeast-2.rds.amazonaws.com 3306

telnet flanet-cache.etokrl.0001.apn2.cache.amazonaws.com 6379

nc devops.cluster-c01spz81v11d.ap-northeast-2.rds.amazonaws.com 3306
nc flanet-prod.cluster-ro-c01spz81v11d.ap-northeast-2.rds.amazonaws.com 5432
traceroute flanet-prod.cluster-ro-c01spz81v11d.ap-northeast-2.rds.amazonaws.com
traceroute devops.cluster-c01spz81v11d.ap-northeast-2.rds.amazonaws.com

flanet-rds-sg (sg-049ccd7eb7da54d1a)

