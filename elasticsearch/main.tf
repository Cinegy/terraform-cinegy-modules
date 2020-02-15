terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
  required_version = ">= 0.12.2"
}

provider "aws" {
  region  = var.aws_region
  version = "~> 2.15"
}

resource "aws_elasticsearch_domain" "mediamanor" {
  domain_name           = var.es_domain_name
  elasticsearch_version = var.es_version

  cluster_config {
    instance_type = var.instance_type
  }

  snapshot_options {
    automated_snapshot_start_hour = var.snapshot_hour
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.volume_size
  }

  tags = {
    Domain    = var.es_domain_name 
    App       = var.app_name
    Env       = var.environment_name
    Terraform = true
  }
}


resource "aws_elasticsearch_domain_policy" "main" {
  domain_name = "${aws_elasticsearch_domain.mediamanor.domain_name}"

  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "${aws_elasticsearch_domain.mediamanor.arn}/*"
        }
    ]
}
POLICIES
}
