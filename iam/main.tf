terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
  required_version = ">= 0.11.10"
}

provider "aws" {
  region     = "${var.aws_region}"
  version = "~> 1.50"
}

resource "aws_iam_user" "terragrunt_ro" {
  name = "terragrunt-${lower(var.app_name)}-ro"
  path = "/terraform/"

  tags {
    Env = "${var.environment_name}"
    App = "${var.app_name}"
    Terraform = true
  }
}

resource "aws_iam_user_policy_attachment" "terragrunt_ro_ops_attachment" {
  user       = "${aws_iam_user.terragrunt_ro.name}"
  policy_arn = "${aws_iam_policy.terragrunt_ro_operations.arn}"
}

resource "aws_iam_user_policy_attachment" "terragrunt_ro_core_ops_attachment" {
  user       = "${aws_iam_user.terragrunt_ro.name}"
  policy_arn = "${aws_iam_policy.terragrunt_core_operations.arn}"
}

resource "aws_iam_access_key" "terragrunt_ro" {
  user = "${aws_iam_user.terragrunt_ro.name}"
}


resource "aws_iam_user" "terragrunt_admin" {
  name = "terragrunt-${lower(var.app_name)}-admin"
  path = "/terraform/"

  tags {
    Env = "${var.environment_name}"
    App = "${var.app_name}"
    Terraform = true
  }
}

resource "aws_iam_user_policy_attachment" "terragrunt_admin_ops_attachment" {
  user       = "${aws_iam_user.terragrunt_admin.name}"
  policy_arn = "${aws_iam_policy.terragrunt_admin_operations.arn}"
}

resource "aws_iam_user_policy_attachment" "terragrunt_admin_core_ops_attachment" {
  user       = "${aws_iam_user.terragrunt_admin.name}"
  policy_arn = "${aws_iam_policy.terragrunt_core_operations.arn}"
}

resource "aws_iam_access_key" "terragrunt_admin" {
  user = "${aws_iam_user.terragrunt_admin.name}"
}

data "aws_iam_policy_document" "terragrunt_core_operations" {
  
  //S3 bucket access for allowing terragrunt to store state, limited to state bucket
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:CreateBucket"
      ]

    resources = [ "arn:aws:s3:::${var.state_bucket}" ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]

    resources = [ "arn:aws:s3:::${var.state_bucket}/*" ]
  }

  //dynamodb access for allowing terragrunt locking limited to locking table (does not permit initial table creation)
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]

    resources = [ "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.dynamodb_table}" ]
  }

  //AWS secrets access to specific secrets, for loading sensitive values (USE CAUTION EDITING RESOURCES!)
  statement {

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue"
    ]

    resources = [        
      "${var.aws_secrets_privatekey_arn}",
      "${var.aws_secrets_generic_account_password_arn}",
      "${var.aws_secrets_domain_admin_password_arn}"
    ]
  }
}

resource "aws_iam_policy" "terragrunt_core_operations" {
  name = "TerragruntCoreS3andDDBOperations"
  policy = "${data.aws_iam_policy_document.terragrunt_core_operations.json}"
}

resource "aws_iam_policy" "terragrunt_ro_operations" {
  name = "TerragruntReadOnlyOperations"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "s3:Get*",
        "s3:List*",
        "application-autoscaling:DescribeScalableTargets",
        "application-autoscaling:DescribeScalingActivities",
        "application-autoscaling:DescribeScalingPolicies",
        "cloudwatch:DescribeAlarmHistory",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "datapipeline:DescribeObjects",
        "datapipeline:DescribePipelines",
        "datapipeline:GetPipelineDefinition",
        "datapipeline:ListPipelines",
        "datapipeline:QueryObjects",
        "dynamodb:BatchGetItem",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:ListTables",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:DescribeReservedCapacity",
        "dynamodb:DescribeReservedCapacityOfferings",
        "dynamodb:ListTagsOfResource",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:DescribeLimits",
        "dynamodb:ListGlobalTables",
        "dynamodb:DescribeGlobalTable",
        "dynamodb:DescribeBackup",
        "dynamodb:ListBackups",
        "dynamodb:DescribeContinuousBackups",
        "dax:Describe*",
        "dax:List*",
        "dax:GetItem",
        "dax:BatchGetItem",
        "dax:Query",
        "dax:Scan",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "iam:GetRole",
        "iam:ListRoles",
        "sns:ListSubscriptionsByTopic",
        "sns:ListTopics",
        "lambda:ListFunctions",
        "lambda:ListEventSourceMappings",
        "lambda:GetFunctionConfiguration"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "terragrunt_admin_operations" {
  statement {
    actions = [ "s3:*" ]
    resources = [ "*" ]
  }
}

resource "aws_iam_policy" "terragrunt_admin_operations" {
  name = "TerragruntAdminOperations"
  policy = "${data.aws_iam_policy_document.terragrunt_admin_operations.json}"
}


resource "aws_iam_role" "iam_role_domain_join" {
  name = "IAM_ROLE_DOMAIN_JOIN-${var.environment_name}"
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
  name  = "INSTANCE_PROFILE_DOMAIN_JOIN-${var.environment_name}"
  role = "${aws_iam_role.iam_role_domain_join.name}"
}

resource "aws_iam_role_policy" "policy_allow_all_ssm" {
  name = "IAM_POLICY_ALLOW_ALL_SSM-${var.environment_name}"
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
