resource "aws_s3_bucket" "terraform-state-es-eks" {
  bucket = "terraform-state-${local.cluster_name}-${random_string.random.result}"
  acl    = "private"

  tags = {
    Name = "Terraform state"
  }
}

resource "random_string" "random" {
  length  = 4
  special = false
  upper   = false
}

resource "aws_s3_bucket" "devops-es-backup" {
  bucket = "devops-es-${local.cluster_name}"
  acl    = "private"
  tags = {
    Name = "devops-es"
  }
}

