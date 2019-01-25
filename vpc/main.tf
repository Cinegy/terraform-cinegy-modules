terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
  required_version = ">= 0.11.11"
}

provider "aws" {
  region     = "${var.aws_region}"
  version = "~> 1.56"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "main" {
  cidr_block = "${var.cidr_block}"
  tags {
    Name = "Cinegy ${upper(var.environment_name)} VPC"
    Env = "${var.environment_name}"
    Terraform = true
  }
}

# Create an elastic IP for the NAT gateway
resource "aws_eip" "nat_1a"
{  
  vpc=true

  tags {
    Name = "NAT GW 1a EIP"
    Env = "${var.environment_name}"
    Terraform = true
  }
}

# Create an elastic IP for the NAT gateway
resource "aws_eip" "nat_1b"
{  
  vpc=true
  
  tags {
    Name = "NAT GW 1b EIP"
    Env = "${var.environment_name}"
    Terraform = true
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Env = "${var.environment_name}"
    Terraform = true
  }
}

# Create a NAT gateway for private subnets to use
resource "aws_nat_gateway" "nat_1a" {
  allocation_id = "${aws_eip.nat_1a.id}"
  subnet_id     = "${aws_subnet.public_a.id}"

  depends_on = ["aws_internet_gateway.gw"]

  tags {
    Name = "NAT GW 1a"
    Env = "${var.environment_name}"
    Terraform = true
  }
}

# Create a 2nd NAT gateway for private subnets to use
resource "aws_nat_gateway" "nat_1b" {
  allocation_id = "${aws_eip.nat_1b.id}"
  subnet_id     = "${aws_subnet.public_b.id}"
  
  depends_on = ["aws_internet_gateway.gw"]

  tags {
    Name = "NAT GW 1b"
    Env = "${var.environment_name}"
    Terraform = true
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"  
}

# allow internet access to private subnets in AZ-A through nat #1a
resource "aws_route_table" "nat_gw_1a" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "Private 1a subnets via NAT GW 1a"
    Env = "${var.environment_name}"
    Terraform = true
  }
}

# add a default route for nat_gw1a
resource "aws_route" "default_gw_nat_gw1a" {
    route_table_id         = "${aws_route_table.nat_gw_1a.id}"
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat_1a.id}"
}

resource "aws_route_table_association" "private_a_subnet_to_nat_gw_1a" {
  route_table_id = "${aws_route_table.nat_gw_1a.id}"
  subnet_id      = "${aws_subnet.private_a.id}"
}

# allow internet access to private subnets in AZ-B through nat #1b
resource "aws_route_table" "nat_gw_1b" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "Private 1b subnets via NAT GW 1b"
    Env = "${var.environment_name}"
    Terraform = true
  }
}

# add a default route for nat_gw1b
resource "aws_route" "default_gw_nat_gw1b" {
    route_table_id         = "${aws_route_table.nat_gw_1b.id}"
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat_1b.id}"
}

resource "aws_route_table_association" "private_b_subnet_to_nat_gw_1b" {
  route_table_id = "${aws_route_table.nat_gw_1b.id}"
  subnet_id = "${aws_subnet.private_b.id}"  
}

# Create subnets to launch cinegy instances and control into
# Availability Zone A - Publically accessible
resource "aws_subnet" "public_a" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_a_subnet_cidr_block}"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags {
    Name = "public_a"
    Env = "${var.environment_name}"
    Terraform = true
    Tier = "Public"
    AZ = "A"
  }
}

# Availability Zone B - Publically accessible
resource "aws_subnet" "public_b" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_b_subnet_cidr_block}"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags {
    Name = "public_b"  
    Env = "${var.environment_name}"
    Terraform = true
    Tier = "Public"
    AZ = "B"
  }
}

# Availability Zone A - NOT Publically accessible
resource "aws_subnet" "private_a" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.private_a_subnet_cidr_block}"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false
  tags {
    Name = "private_a"
    Env = "${var.environment_name}"
    Terraform = true
    Tier = "Private"
    AZ = "A"
  }
}

# Availability Zone B - NOT Publically accessible
resource "aws_subnet" "private_b" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.private_b_subnet_cidr_block}"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false 
  tags {
    Name = "private_b" 
    Env = "${var.environment_name}"
    Terraform = true
    Tier = "Private"
    AZ = "B"
  }
}

# A default security group to access instances over RDP and WINRM
resource "aws_security_group" "remote_access" {
  name        = "Instance RDP and WINRM access"
  description = "Allows RDP access from anywhere, and WINRM internally"
  vpc_id      = "${aws_vpc.main.id}"
  
  # RDP access from anywhere (has no effect within private subnet deployments, will just be VPC local)
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # WINRM access from the VPC
  ingress {
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_block}"]
  }
  
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags {
    Env = "${var.environment_name}"
    Terraform = true
  }
}


# A default security group to access instances over SSH
resource "aws_security_group" "remote_access_ssh" {
  name        = "Instance SSH"
  description = "Allows SSH access from anywhere"
  vpc_id      = "${aws_vpc.main.id}"
  
  # SSH access from anywhere (has no effect within private subnet deployments, will just be VPC local)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags {
    Env = "${var.environment_name}"
    Terraform = true
  }
}


# A default security group with all internal ports open
resource "aws_security_group" "open_internal" {
  name        = "Instance VPC internal open access"
  description = "Allows any traffic within the VPC"
  vpc_id      = "${aws_vpc.main.id}"
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_block}"]
  }
  
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags {
    Env = "${var.environment_name}"
    Terraform = true
  }
}

# Get PEM details from AWS secrets and create AWS public key registration for use by any VM instances
data "aws_secretsmanager_secret" "privatekey" {
  arn = "${var.aws_secrets_privatekey_arn}"
}

data "aws_secretsmanager_secret_version" "privatekey" {
  secret_id = "${data.aws_secretsmanager_secret.privatekey.id}"
}

data "tls_public_key" "terraform_key" {
  private_key_pem = "${data.aws_secretsmanager_secret_version.privatekey.secret_string}"
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform-key-${var.environment_name}"
  public_key = "${data.tls_public_key.terraform_key.public_key_openssh}"
}