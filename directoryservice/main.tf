terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
  required_version = ">= 0.11.10"
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
  version = "~> 1.50"
}

# Get any secrets needed for VM instancing
data "aws_secretsmanager_secret" "domain_admin_password" {
  arn = "${var.aws_secrets_domain_admin_password_arn}"
}

data "aws_secretsmanager_secret_version" "domain_admin_password" {
  secret_id = "${data.aws_secretsmanager_secret.domain_admin_password.id}"
}

resource "aws_directory_service_directory" "ad" {
  name     = "${var.domain_name}"
  password = "${data.aws_secretsmanager_secret_version.domain_admin_password.secret_string}"
  edition  = "${var.directory_edition}"
  type     = "MicrosoftAD"

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
