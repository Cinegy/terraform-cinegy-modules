terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
  required_version = ">= 0.11.10"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config {
    bucket = "${var.global_state_bucket}"
    region = "${var.state_region}"
    key = "${var.environment_name}/vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "directoryservice" {
  backend = "s3"
  config {
    bucket = "${var.global_state_bucket}"
    region = "${var.state_region}"
    key = "${var.environment_name}/directoryservice/terraform.tfstate"
  }
}

data "template_file" "userdatascript" {
  template = "${file("${path.module}/conf/userdatascriptbase.ps1")}"
  vars {
    injected_content = "${var.user_data_script_extension}"
  }
}

provider "aws" {
  region     = "${var.aws_region}"
  version = "~> 1.50"
}

# Get any secrets needed for VM instancing
data "aws_secretsmanager_secret" "privatekey" {
  arn = "${var.aws_secrets_privatekey_arn}"
}

data "aws_secretsmanager_secret_version" "privatekey" {
  secret_id = "${data.aws_secretsmanager_secret.privatekey.id}"
}

data "aws_secretsmanager_secret" "domain_admin_password" {
  arn = "${var.aws_secrets_domain_admin_password_arn}"
}

data "aws_secretsmanager_secret_version" "domain_admin_password" {
  secret_id = "${data.aws_secretsmanager_secret.domain_admin_password.id}"
}

data "aws_subnet_ids" "filtered_subnets" {
  vpc_id = "${data.terraform_remote_state.vpc.main_vpc}"

  tags {
    Tier = "${var.aws_subnet_tier}"
    AZ = "${var.aws_subnet_az}"
  }
}

resource "aws_ssm_association" "domain_ssm" {
	name = "${data.terraform_remote_state.directoryservice.directory_service_default_doc_name}"
	instance_id = "${aws_instance.vm.id}"
}

data "aws_ami" "latest_windows" {
most_recent = true
owners = ["801119661308"] #amazon

  filter {
      name   = "name"
      values = ["${var.amazon_owned_ami_name}"]
  }

  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
}


resource "aws_ebs_volume" "data_volume" {
  availability_zone = "${var.aws_region}${lower(var.aws_subnet_az)}"
  size  = "${var.data_volume_size}"
  count = "${var.attach_data_volume}"

  tags {
    Name = "${var.host_name_prefix}-${upper(var.environment_name)}-DATAVOL"
    Env = "${var.environment_name}"
    Terraform = true
  }
}

resource "aws_volume_attachment" "data_volume" {
  device_name = "/dev/sdh"
  count = "${var.attach_data_volume}"

  volume_id   = "${element(aws_ebs_volume.data_volume.*.id, count.index)}"
  instance_id = "${aws_instance.vm.id}"
}

resource "aws_network_interface_sg_attachment" "remote_access" {
  security_group_id    = "${data.terraform_remote_state.vpc.remote_access_security_group}"
  network_interface_id = "${aws_instance.vm.primary_network_interface_id}"
}

resource "aws_network_interface_sg_attachment" "open_access" {
  count = "${var.allow_all_internal_traffic}"
  security_group_id    = "${data.terraform_remote_state.vpc.open_internal_access_security_group}"
  network_interface_id = "${aws_instance.vm.primary_network_interface_id}"
}

resource "aws_instance" "vm" {
  ami = "${data.aws_ami.latest_windows.id}"
  key_name = "terraform-key-${var.environment_name}"
  instance_type = "${var.instance_type}"
  iam_instance_profile = "${data.terraform_remote_state.directoryservice.instance_profile_domain_join_name}"
  subnet_id     = "${element(data.aws_subnet_ids.filtered_subnets.ids, count.index)}"
  get_password_data = true
  user_data = "${format("<powershell>%s</powershell>", data.template_file.userdatascript.rendered)}"

  tags {
    Name = "${var.host_description} - ${upper(var.environment_name)}"
    Hostname = "${var.host_name_prefix}-${upper(var.environment_name)}"
    Env = "${var.environment_name}"
    Terraform = true
  }
}

resource "aws_route53_record" "vm" {
  count = "${var.create_external_dns_reference}"
  zone_id = "${var.shared_route53_zone_id}"
  name    = "${lower(var.host_name_prefix)}-${lower(var.environment_name)}.${var.shared_route53_zone_suffix}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.vm.public_ip}"]
}

