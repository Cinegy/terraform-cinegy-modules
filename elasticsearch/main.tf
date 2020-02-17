terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
  required_version = ">= 0.12.2"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    region = var.state_region
    key    = "${var.environment_name}/vpc/terraform.tfstate"
  }
}

provider "aws" {
  region  = var.aws_region
  version = "~> 2.15"
}

/*
resource "aws_security_group" "es" {
  name        = "Elasticsearch-${var.es_domain_name} Internal Access"
  description = "Managed by Terraform"
  vpc_id      = data.terraform_remote_state.vpc.outputs.main_vpc

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [ data.terraform_remote_state.vpc.outputs.main_vpc_cidr ]
  }
  
  tags = {
    Env       = var.environment_name
    App       = var.app_name
    Terraform = true
  }

}*/

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
/*
  vpc_options {
    subnet_ids = [
      data.terraform_remote_state.vpc.outputs.private_subnets.a
    ]

    security_group_ids = ["${aws_security_group.es.id}"]
  }
*/
  tags = {
    Domain    = var.es_domain_name 
    App       = var.app_name
    Env       = var.environment_name
    Terraform = true
  }
}

/*

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name = aws_elasticsearch_domain.mediamanor.domain_name

  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Action": "es:*",
          "Principal": "*",
          "Effect": "Allow",
          "Resource": "${aws_elasticsearch_domain.mediamanor.arn}/*",
          "Condition": {
            "IpAddress": {
              "aws:SourceIp": "127.0.0.0/24"
            }
          }
        }
    ]
}
POLICIES
}
*/