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

#agent package specifications
data "aws_s3_bucket_object" "default_agent_manifest" {
  bucket = "${var.state_bucket}"
  key = "${var.environment_name}/vpc/default_base_manifest.txt"
}

data "template_file" "userdatascript" {
  template = "${file("${path.module}/conf/userdatascriptbase.ps1")}"
  vars {
    default_pacakge_manifest = "${data.aws_s3_bucket_object.default_agent_manifest.body}"
    injected_content = "${var.user_data_script_extension}"
  }
}

provider "aws" {
  region     = "${var.aws_region}"
  version = "~> 1.56"
}

# Get any secrets needed for VM instancing
data "aws_secretsmanager_secret" "privatekey" {
  arn = "${var.aws_secrets_privatekey_arn}"
}

data "aws_secretsmanager_secret_version" "privatekey" {
  secret_id = "${data.aws_secretsmanager_secret.privatekey.id}"
}

data "aws_subnet_ids" "filtered_subnets" {
  vpc_id = "${data.terraform_remote_state.vpc.main_vpc}"

  tags {
    Tier = "${var.aws_subnet_tier}"
    AZ = "${var.aws_subnet_az}"
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
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  key_name = "terraform-key-${var.environment_name}"
  instance_type = "${var.instance_type}"
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

