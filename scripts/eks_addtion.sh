#!/usr/bin/env bash

# sudo bash /vagrant/scripts/eks_addtion.sh

PROJECT_BASE='/vagrant/terraform-aws-eks/workspace/base'
cd ${PROJECT_BASE}

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
aws_region=$(prop 'config' 'region')
eks_project=$(prop 'project' 'project')

bash /vagrant/tz-local/resource/makeuser/eks/eks-users.sh

bash /vagrant/tz-local/resource/docker-repo/install.sh
bash /vagrant/tz-local/resource/local-dns/install.sh
bash /vagrant/tz-local/resource/autoscaler/install.sh

bash /vagrant/tz-local/resource/elb-controller/install.sh
bash /vagrant/tz-local/resource/elb-controller/update.sh
bash /vagrant/tz-local/resource/ingress_nginx/install.sh

bash /vagrant/tz-local/resource/persistent-storage/install.sh

bash /vagrant/tz-local/resource/elk/install.sh

exit 0

