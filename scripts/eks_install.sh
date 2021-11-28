#!/usr/bin/env bash

# sudo bash /vagrant/scripts/eks_install.sh

rm -Rf /vagrant/info

export AWS_PROFILE=default
function propProject {
	grep "${1}" "/vagrant/resources/project" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
export EKS_PROJECT=$(propProject 'project')
export aws_account_id=$(propProject 'aws_account_id')
PROJECT_BASE='/vagrant/terraform-aws-eks/workspace/base'

function propConfig {
  grep "${1}" "/vagrant/resources/config" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
aws_region=$(propConfig 'region')
export AWS_DEFAULT_REGION="${aws_region}"

echo "
export AWS_DEFAULT_REGION=${aws_region}
alias k='kubectl'
alias KUBECONFIG='~/.kube/config'
alias base='cd /vagrant/terraform-aws-eks/workspace/base'
alias scripts='cd /vagrant/scripts'
alias tapply='terraform apply -auto-approve'
" >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc
echo "
export AWS_DEFAULT_REGION=${aws_region}
alias k='kubectl'
" >> /root/.bashrc

echo "###############"

INSTALL_INIT="$(aws eks describe-cluster --name ${EKS_PROJECT} | grep ${EKS_PROJECT})"
echo "INSTALL_INIT:"$INSTALL_INIT
if [[ "${INSTALL_INIT}" == "" ]]; then
  INSTALL_INIT='true'
  bash /vagrant/scripts/eks_remove_all.sh cleanTfFiles
fi

if [[ "${INSTALL_INIT}" == 'true' || ! -f "/home/vagrant/.aws/config" ]]; then
  # config DNS
  sudo service systemd-resolved stop
  sudo systemctl disable systemd-resolved
  sudo rm -Rf /etc/resolv.conf

cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1 #cloudflare DNS
nameserver 8.8.8.8 #Google DNS
EOF

  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
  sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
  sudo apt-get update -y
  sudo apt purge terraform -y
  #sudo apt install terraform
  sudo apt install terraform=0.13.6
  terraform -v
  sudo apt install awscli jq unzip -y
  sudo apt install ntp -y
  sudo systemctl enable ntp

  wget "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
  tar xvfz "eksctl_$(uname -s)_amd64.tar.gz"
  rm -Rf "eksctl_$(uname -s)_amd64.tar.gz"
  sudo mv eksctl /usr/local/bin

  curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/aws-iam-authenticator
  chmod +x aws-iam-authenticator
  sudo mv aws-iam-authenticator /usr/local/bin

  echo "## [ install helm3 ] ######################################################"
  sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
  sudo bash get_helm.sh
  sudo rm -Rf get_helm.sh
  sleep 10
  helm repo add stable https://charts.helm.sh/stable
  helm repo update

  sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2 curl
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update
  sudo apt-get install -y kubectl

#  curl -LO https://dl.k8s.io/release/v1.19/bin/linux/amd64/kubectl

  #wget https://github.com/lensapp/lens/releases/download/v4.1.5/Lens-4.1.5.amd64.deb
  #sudo dpkg -i Lens-4.1.5.amd64.deb

  curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
  sudo apt install ./keybase_amd64.deb -y
  rm -Rf keybase_amd64.deb

  #  https://github.com/ahmetb/kubectx
  #  sudo apt install kubectx
  wget https://github.com/ahmetb/kubectx/releases/download/v0.9.3/kubectx
  sudo mv kubectx /usr/sbin
  chmod +x /usr/sbin/kubectx
  wget https://github.com/ahmetb/kubectx/releases/download/v0.9.3/kubens
  sudo mv kubens /usr/sbin
  chmod +x /usr/sbin/kubens

  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/sbin/

  curl -L -o kubectl-cert-manager.tar.gz https://github.com/jetstack/cert-manager/releases/latest/download/kubectl-cert_manager-linux-amd64.tar.gz
  tar xzf kubectl-cert-manager.tar.gz
  sudo mv kubectl-cert_manager /usr/local/bin

  VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
  sudo chmod +x /usr/local/bin/argocd
fi

sudo mkdir -p /home/vagrant/.aws
sudo cp -Rf /vagrant/resources/config /home/vagrant/.aws/config
sudo cp -Rf /vagrant/resources/credentials /home/vagrant/.aws/credentials
sudo cp -Rf /vagrant/resources/project /home/vagrant/.aws/project
sudo chown -Rf vagrant:vagrant /home/vagrant/.aws
sudo rm -Rf /root/.aws
sudo cp -Rf /home/vagrant/.aws /root/.aws

cd ${PROJECT_BASE}
if [ ! -f "${PROJECT_BASE}/terraform.tfstate" ]; then
  ############################################################
  # make aws credentials
  ############################################################
  rm -Rf ${EKS_PROJECT}*
  ssh-keygen -t rsa -C ${EKS_PROJECT} -P "" -f ${EKS_PROJECT} -q
  chmod -Rf 600 ${EKS_PROJECT}*
  cp -Rf ${EKS_PROJECT}* /home/vagrant/.ssh
  cp -Rf ${EKS_PROJECT}* /vagrant/resources
  chown -Rf vagrant:vagrant /home/vagrant/.ssh
  chown -Rf vagrant:vagrant /vagrant/resources

  sed -i "s/aws_region/${aws_region}/g" /vagrant/terraform-aws-eks/local.tf
  sed -i "s/eks_project/${EKS_PROJECT}/g" /vagrant/terraform-aws-eks/local.tf
  sed -i "s/aws_region/${aws_region}/g" ${PROJECT_BASE}/locals.tf
  sed -i "s/eks_project/${EKS_PROJECT}/g" ${PROJECT_BASE}/locals.tf
  sed -i "s/aws_account_id/${aws_account_id}/g" ${PROJECT_BASE}/locals.tf

  terraform init
  terraform plan
#  terraform plan | sed 's/\x1b\[[0-9;]*m//g' > a.txt
  terraform apply -auto-approve
  S3_BUCKET=$(terraform output | grep s3-bucket | awk '{print $3}')
  echo $S3_BUCKET > s3_bucket_id
  # terraform destroy -auto-approve
  eks_role=$(aws iam list-roles --out=text | grep "${EKS_PROJECT}2" | grep "0000000" | head -n 1 | awk '{print $7}')
  echo eks_role: ${eks_role}
  sed -i "s/ELK_EKS_ROLE/${eks_role}/g" ${PROJECT_BASE}/locals.tf
  terraform init
  terraform plan
  terraform apply -auto-approve
fi

#wget https://github.com/lensapp/lens/releases/download/v4.1.5/Lens-4.1.5.amd64.deb
#sudo dpkg -i Lens-4.1.5.amd64.deb

export KUBECONFIG=`ls kubeconfig_${EKS_PROJECT}*`
cp -Rf $KUBECONFIG /vagrant/config_${EKS_PROJECT}
sudo mkdir -p /root/.kube
sudo cp -Rf $KUBECONFIG /root/.kube/config
sudo chmod -Rf 600 /root/.kube/config
mkdir -p /home/vagrant/.kube
cp -Rf $KUBECONFIG /home/vagrant/.kube/config
sudo chown -Rf vagrant:vagrant /home/vagrant/.kube
sudo chmod -Rf 600 /home/vagrant/.kube/config
export KUBECONFIG=/home/vagrant/.kube/config

export s3_bucket_id=`terraform output | grep s3-bucket | awk '{print $3}'`
echo $s3_bucket_id > s3_bucket_id

#export s3_bucket_id=`terraform output | grep s3-bucket | awk '{print $3}'`
#echo $s3_bucket_id > s3_bucket_id
#master_ip=`terraform output | grep -A 2 "public_ip" | head -n 1 | awk '{print $3}'`
#export master_ip=`echo $master_ip | sed -e 's/\"//g;s/ //;s/,//'`

bash /vagrant/scripts/eks_addtion.sh

#bastion_ip=$(terraform output | grep "bastion" | awk '{print $3}')
#echo "
#Host ${bastion_ip}
#  StrictHostKeyChecking   no
#  LogLevel                ERROR
#  UserKnownHostsFile      /dev/null
#  IdentitiesOnly yes
#  IdentityFile /home/vagrant/.ssh/${EKS_PROJECT}
#" >> /home/vagrant/.ssh/config
#sudo chown -Rf vagrant:vagrant /home/vagrant/.ssh/config
#
#secondary_az1_ip=$(terraform output | grep "secondary-az1" | awk '{print $3}')

echo "
##[ Summary ]##########################################################
  - in VM
    export KUBECONFIG='/vagrant/config_${EKS_PROJECT}'

  - outside of VM
    export KUBECONFIG='config_${EKS_PROJECT}'

  - kubectl get nodes
  - S3 bucket: ${s3_bucket_id}

#  - ${EKS_PROJECT} bastion:
#    ssh ubuntu@${bastion_ip}
#    chmod 600 /home/ubuntu/resources/${EKS_PROJECT}
#  - secondary-az1: ssh -i /home/ubuntu/resources/${EKS_PROJECT} ubuntu@${secondary_az1_ip}

#######################################################################
" >> /vagrant/info
cat /vagrant/info

exit 0

#helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
#helm repo update
#helm install prometheus-operator prometheus-community/kube-prometheus-stack




