terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
  required_version = ">= 0.11.11"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config {
    bucket = "${var.state_bucket}"
    region = "${var.state_region}"
    key = "${var.environment_name}/vpc/terraform.tfstate"
  }
}

provider "aws" {
  region     = "${var.aws_region}"
  version = "~> 1.59"
}

# Get any secrets needed for VM instancing
data "aws_secretsmanager_secret" "domain_admin_password" {
  arn = "${var.aws_secrets_domain_admin_password_arn}"
}

data "aws_secretsmanager_secret_version" "domain_admin_password" {
  secret_id = "${data.aws_secretsmanager_secret.domain_admin_password.id}"
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

resource "aws_directory_service_directory" "ad" {
  name     = "${var.domain_name}"
  password = "${data.aws_secretsmanager_secret_version.domain_admin_password.secret_string}"
  type     = "SimpleAD"
  size = "Small"

  vpc_settings {
    vpc_id     = "${data.terraform_remote_state.vpc.main_vpc}"
    subnet_ids = [
        "${data.terraform_remote_state.vpc.private_subnets.a}", 
        "${data.terraform_remote_state.vpc.private_subnets.b}"
        ]    
  }

  tags {
    Name = "${upper(var.environment_name)}-Directory Service"
    Env = "${var.environment_name}"
    App = "${var.app_name}"
    Terraform = true
  }
}


resource "aws_ssm_document" "directory_service_default_doc" {
	name  = "directory_service_default_docs-${var.environment_name}"
	document_type = "Command"

	content = <<DOC
    {
            "schemaVersion": "1.0",
            "description": "Join an instance to a domain",
            "runtimeConfig": {
            "aws:domainJoin": {
                "properties": {
                    "directoryId": "${aws_directory_service_directory.ad.id}",
                    "directoryName": "${var.domain_name}",
                    "dnsIpAddresses": [
                        "${aws_directory_service_directory.ad.dns_ip_addresses[0]}",
                        "${aws_directory_service_directory.ad.dns_ip_addresses[1]}"
                    ]
                }
            }
            }
    }
    DOC


    tags {
      Env = "${var.environment_name}"
      App = "${var.app_name}"
      Terraform = true
    }

	depends_on = ["aws_directory_service_directory.ad"]
}
