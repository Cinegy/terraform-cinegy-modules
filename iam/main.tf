terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
}

provider "aws" {
  region  = var.aws_region
  version = "~> 2.47"
}

resource "aws_iam_user" "terragrunt_ro" {
  name = "terragrunt-${lower(var.app_name)}-${var.stage}-ro"
  path = "/terraform/"

  tags = {
    Env       = var.environment_name
    App       = var.app_name
    Terraform = true
  }
}

resource "aws_iam_user_policy_attachment" "terragrunt_ro_ops_attachment" {
  user       = aws_iam_user.terragrunt_ro.name
  policy_arn = aws_iam_policy.terragrunt_ro_operations.arn
}

resource "aws_iam_user_policy_attachment" "terragrunt_ro_core_ops_attachment" {
  user       = aws_iam_user.terragrunt_ro.name
  policy_arn = aws_iam_policy.terragrunt_core_operations.arn
}

resource "aws_iam_access_key" "terragrunt_ro" {
  user = aws_iam_user.terragrunt_ro.name
}

resource "aws_iam_user" "terragrunt_admin" {
  name = "terragrunt-${lower(var.app_name)}-${var.stage}-admin"
  path = "/terraform/"

  tags = {
    Env       = var.environment_name
    App       = var.app_name
    Terraform = true
  }
}

resource "aws_iam_user_policy_attachment" "terragrunt_admin_ops_attachment" {
  user       = aws_iam_user.terragrunt_admin.name
  policy_arn = aws_iam_policy.terragrunt_admin_operations.arn
}

resource "aws_iam_user_policy_attachment" "terragrunt_admin_core_ops_attachment" {
  user       = aws_iam_user.terragrunt_admin.name
  policy_arn = aws_iam_policy.terragrunt_core_operations.arn
}

resource "aws_iam_access_key" "terragrunt_admin" {
  user = aws_iam_user.terragrunt_admin.name
}

data "aws_iam_policy_document" "terragrunt_core_operations" {
  //S3 bucket access for allowing terragrunt to store state, limited to state bucket
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:CreateBucket"
    ]

    resources = ["arn:aws:s3:::${var.state_bucket}"]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]

    resources = ["arn:aws:s3:::${var.state_bucket}/*"]
  }

  //dynamodb access for allowing terragrunt locking limited to locking table (does not permit initial table creation)
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]

    resources = ["arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.dynamodb_table}"]
  }

  //AWS secrets access to specific secrets, for loading sensitive values (USE CAUTION EDITING RESOURCES!)
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.aws_secrets_privatekey_arn,
      var.aws_secrets_generic_account_password_arn,
      var.aws_secrets_domain_admin_password_arn
    ]
  }
}

resource "aws_iam_policy" "terragrunt_core_operations" {
  name   = "TerragruntCoreS3andDDBOperations-${var.app_name}-${var.stage}-${var.environment_name}"
  policy = data.aws_iam_policy_document.terragrunt_core_operations.json
}

//General RO access without resource restriction to AWS services, added as required during TF/TG roll-out
data "aws_iam_policy_document" "terragrunt_ro_operations" {
  statement {
    actions = [
      "ec2:Describe*",
      "s3:Get*",
      "s3:List*",
      "iam:Get*",
      "iam:List*",
      "ds:Check*",
      "ds:Describe*",
      "ds:Get*",
      "ds:List*",
      "ds:Verify*",
      "sns:List*",
      "sns:Get*",
      "organizations:Describe*",
      "organizations:List*",
      "ssm:Describe*",
      "ssm:Get*",
      "ssm:List*",
      "route53:Get*",
      "route53:List*",
      "route53:TestDNSAnswer",
      "dynamodb:BatchGet*",
      "dynamodb:Describe*",
      "dynamodb:Get*",
      "dynamodb:List*",
      "dynamodb:Query",
      "dynamodb:Scan",
      "rds:Describe*",
      "rds:ListTagsForResource",
      "elasticloadbalancing:Describe*",
      "lambda:Get*",
      "lambda:List*",
      "apigateway:Get*",
      "autoscaling:Describe*",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "logs:Get*",
      "logs:List*",
      "logs:Describe*",
      "logs:TestMetricFilter",
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "terragrunt_ro_operations" {
  name   = "TerragruntReadOnlyOperations-${var.app_name}-${var.stage}-${var.environment_name}"
  policy = data.aws_iam_policy_document.terragrunt_ro_operations.json
}

//General RW / admin access without resource restriction to AWS services, added as required during TF/TG roll-out
data "aws_iam_policy_document" "terragrunt_admin_operations" {
  statement {
    actions = [
      "ec2:*",
      "s3:*",
      "iam:*",
      "ds:*",
      "sns:*",
      "organizations:*",
      "ssm:*",
      "route53:*",
      "dynamodb:*",
      "secretsmanager:*",
      "rds:*",
      "cloudwatch:*",
      "logs:*",
      "elasticloadbalancing:*",
      "acm:*",
      "lambda:*",
      "edgelambda:*",
      "apigateway:*",
      "cognito-idp:*",
      "states:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "terragrunt_admin_operations" {
  name   = "TerragruntAdminOperations-${var.app_name}-${var.stage}-${var.environment_name}"
  policy = data.aws_iam_policy_document.terragrunt_admin_operations.json
}

/*
resource "aws_iam_role" "iam_role_domain_join" {
  name = "IAM_ROLE_DOMAIN_JOIN-${var.app_name}-${var.environment_name}"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "instance_profile_domain_join" {
  name  = "INSTANCE_PROFILE_DOMAIN_JOIN-${var.app_name}-${var.environment_name}"
  role = "${aws_iam_role.iam_role_domain_join.name}"
}

resource "aws_iam_role_policy" "policy_allow_all_ssm" {
  name = "IAM_POLICY_ALLOW_ALL_SSM-${var.app_name}-${var.environment_name}"
  role = "${aws_iam_role.iam_role_domain_join.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAccessToSSM",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:ListAssociations",
                "ssm:GetDocument",
                "ssm:ListInstanceAssociations",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceInformation",
                "ssm:UpdateInstanceAssociationStatus",
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply",
                "ds:CreateComputer",
                "ds:DescribeDirectories",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInstances",
                "ec2:DescribeTags"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}
*/
