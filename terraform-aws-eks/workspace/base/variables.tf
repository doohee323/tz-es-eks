variable "INSTANCE_DEVICE_NAME" {
  default = "/dev/xvdh"     # nvme1n1  xvdh
}

variable "instance_type" {
  # Smallest recommended, where ~1.1Gb of 2Gb memory is available for the Kubernetes pods after ‘warming up’ Docker, Kubelet, and OS
  default = "t3.medium"
  type    = string
}

variable "kms_key_arn" {
  default     = ""
  description = "KMS key ARN to use if you want to encrypt EKS node root volumes"
  type        = string
}

variable "container_main_port" {
  default = "31000"
}

# The port the load balancer will listen on
variable "lb_main_port" {
  default = "80"
}

# The load balancer protocol

variable "lb_main_protocol" {
  default = "HTTP"
}

variable "main_endpoint" {
  default = ["main.tztest.com"]
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = [
    "472304975363",
  ]
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      rolearn  = "arn:aws:iam::472304975363:role/es-eks-a20211127185152646200000001"
      username = "es-eks-a20211127185152646200000001"
      groups   = ["system:masters"]
    },
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      userarn  = "arn:aws:iam::472304975363:user/devops"
      username = "devops"
      groups   = ["system:masters"]
    }
  ]
}

variable "allowed_management_cidr_blocks" {
  default = [
  ]
}
