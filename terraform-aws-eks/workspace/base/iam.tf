resource "aws_iam_role_policy_attachment" "es-eks-ecr-policy" {
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-ecr-policy"
  role       = module.eks.cluster_iam_role_name
}
#########################################
# IAM S3 policy
#########################################
resource "aws_iam_role_policy_attachment" "es-eks-a3full-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = module.eks.cluster_iam_role_name
}
module "es_s3_iam_policy" {
  source = "../../modules/iam-policy"
  name        = "${local.cluster_name}-es-s3-policy"
  path        = "/"
  description = "${local.cluster_name}-es-s3-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::devops-es-${local.cluster_name}",
        "arn:aws:s3:::devops-es-${local.cluster_name}/*"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "es-eks-es-s3-policy" {
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-es-s3-policy"
  role       = var.map_roles[0].username
  depends_on = [module.es_s3_iam_policy]
}
#########################################
# IAM SES policy
#########################################
module "iam_ses_policy" {
  source = "../../modules/iam-policy"
  name        = "${local.cluster_name}-ses-policy"
  path        = "/"
  description = "${local.cluster_name}-ses-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ses:SendRawEmail"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "es-eks-aes-policy" {
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-ses-policy"
  role       = module.eks.cluster_iam_role_name
  depends_on = [module.iam_ses_policy]
}

#########################################
# cert-manager dns-01
#########################################
module "cert_manager_irsa" {
  source = "../../modules/iam-assumable-role-with-oidc"
  create_role = true
  role_name = "cert_manager-${local.cluster_name}"
  tags = {Role = "cert_manager-${local.cluster_name}-with-oidc"}
  provider_url  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns = [aws_iam_policy.cert_manager_policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"
  ]
}

resource "aws_iam_policy" "cert_manager_policy" {
  name        = "${local.cluster_name}-cert-manager-policy"
  path        = "/"
  description = "Policy, which allows CertManager to create Route53 records"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "route53:GetChange",
        "Resource" : "arn:aws:route53:::change/*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        "Resource": "arn:aws:route53:::hostedzone/*"
      },
      {
        "Effect": "Allow",
        "Action": "route53:ListHostedZonesByName",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "es-eks-cert_manager_policy" {
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.cluster_name}-cert-manager-policy"
  role       = var.map_roles[0].username
  depends_on = [aws_iam_policy.cert_manager_policy]
}

##################
