#!/usr/bin/env bash

# https://kubernetes.io/ko/docs/tasks/configure-pod-container/pull-image-private-registry/
# bash /vagrant/tz-local/resource/docker-repo/install.sh
cd /vagrant/tz-local/resource/docker-repo

#set -x
shopt -s expand_aliases
alias k='kubectl'

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
eks_project=$(prop 'project' 'project')
eks_domain=$(prop 'project' 'domain')
basic_password=$(prop 'project' 'basic_password')
admin_password=$(prop 'project' 'admin_password')

sudo apt-get update -y
sudo apt-get -y install docker.io jq
sudo usermod -G docker vagrant
sudo chown -Rf vagrant:vagrant /var/run/docker.sock

mkdir -p ~/.docker

#sudo vi /etc/docker/daemon.json
#{
#  "insecure-registries":["harbor.default.es-eks-k.tztest.com"]
#}
#sudo systemctl restart docker
#docker login harbor.default.es-eks-k.tztest.com -u="admin" -p="${admin_password}"

docker login -u="tzdevops" -p="${admin_password}"

sleep 2

cat ~/.docker/config.json
mkdir -p /home/vagrant/.docker
cp -Rf ~/.docker/config.json /home/vagrant/.docker/config.json
sudo chown -Rf vagrant:vagrant /home/vagrant/.docker

kubectl delete secret tz-harborkey
kubectl -n tgd-dev create secret generic tz-harborkey \
    --from-file=.dockerconfigjson=/home/vagrant/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson

kubectl create secret generic tz-harborkey \
    -n devops-dev \
    --from-file=.dockerconfigjson=/home/vagrant/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
#PROJECTS=($(kubectl get namespaces | awk '{print $1}' | tr '\n' ' '))
#PROJECTS=(devops-dev devops-prod)
PROJECTS=(argocd consul common common-dev datateam datateam-dev default devops devops-dev extension extension-dev monitoring tgd tgd-dev devops devops-dev vault)
for item in "${PROJECTS[@]}"; do
  if [[ "${item}" != "NAME" ]]; then
    echo "===================== ${item}"
    kubectl delete secret tz-harborkey -n ${item}
    kubectl create secret generic tz-harborkey \
      -n ${item} \
      --from-file=.dockerconfigjson=/home/vagrant/.docker/config.json \
      --type=kubernetes.io/dockerconfigjson
  fi
done

#echo "
#apiVersion: v1
#kind: Secret
#metadata:
#  name: tz-harborkey
#data:
#  .dockerconfigjson: docker-config
#type: kubernetes.io/dockerconfigjson
#" > docker-config.yaml
#
#DOCKER_CONFIG=$(cat /home/vagrant/.docker/config.json | base64 | tr -d '\r')
#DOCKER_CONFIG=$(echo $DOCKER_CONFIG | sed 's/ //g')
#echo "${DOCKER_CONFIG}"
#cp docker-config.yaml docker-config.yaml_bak
#sed -i "s/DOCKER_CONFIG/${DOCKER_CONFIG}/g" docker-config.yaml_bak
#k apply -f docker-config.yaml_bak

kubectl get secret tz-harborkey --output=yaml
kubectl get secret tz-harborkey -n vault --output=yaml

kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode

exit 0

spec:
  containers:
  - name: private-reg-container
    image: <your-private-image>
  imagePullSecrets:
    - name: tz-harborkey
