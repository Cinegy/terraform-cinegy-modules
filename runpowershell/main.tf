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

data "terraform_remote_state" "directoryservice" {
  backend = "s3"
  config {
    bucket = "${var.state_bucket}"
    region = "${var.state_region}"
    key = "${var.environment_name}/directoryservice/terraform.tfstate"
  }
}

provider "aws" {
  region     = "${var.aws_region}"
  version = "~> 2.3"
}


data "template_file" "script" {
  template = "${file(var.powershell_script_path)}"

  vars = "${
    merge(var.template_vars, 
    map("aws_access_key", var.aws_access_key), 
    map("aws_session", var.aws_session), 
    map("aws_secret_access_key", var.aws_secret_access_key)
    )
  }"
}

resource "aws_ssm_association" "command" {
  name = "AWS-RunPowerShellScript"
  targets = {
    key = "tag:Hostname"
    values = ["${var.vm_name_tag_value}"]
  }

  parameters {
    commands = "${data.template_file.script.rendered}"
  }
}