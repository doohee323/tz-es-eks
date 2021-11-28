locals {
  cluster_name                  = "es-eks-a"
  region                        = "ap-northeast-2"
  environment                   =  "dev"
  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler-chart"
  tzcorp_zone_id               = "ZEGN8MOW1060B"
  tags                          = {
    application: local.cluster_name,
    environment: local.environment,
    service: "web",
    team: "devops"
  }
  VCP_BCLASS = "10.40"
  VPC_CIDR   = "${local.VCP_BCLASS}.0.0/16"
  instance_type = "t3.medium"

  allowed_management_cidr_blocks = [
    // Dewey Hong
    "98.51.38.238/32",
    local.VPC_CIDR,
  ]

  map_roles = [
    {
      rolearn  = "arn:aws:iam::215559030652:role/es-eks-xxxx"
      username = "es-eks-xxxx"
      groups   = ["system:masters"]
    },
  ]

  map_users = [
    {
      userarn  = "arn:aws:iam::215559030652:user/devops"
      username = "devops"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::215559030652:user/adminuser"
      username = "adminuser"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::215559030652:user/doohee.hong"
      username = "doohee.hong"
      groups   = ["system:masters"]
    },
  ]

}
