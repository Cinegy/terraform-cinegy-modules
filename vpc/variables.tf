# Standard variables for managing state and deployment
variable "aws_region" {
  description = "AWS region to launch infrastructure within."
}

variable "state_bucket" {
  description = "Name of bucket used to hold state."
}

variable "state_region" {
  description = "Region associated with state bucket."
  default = "eu-west-1"
}

variable "environment_name" {
  description = "Name to used to label environment deployment, for example 'dev' or 'test-lk'."
}

# Module specific variables
variable "aws_secrets_privatekey_arn" {
  description = "ARN representing private key secret stored within AWS Secrets Manager"
}

variable "cidr_block" {
  description = "IP range in CIDR format for VPC usage"
}

variable "public_a_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
}
variable "public_b_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
}
variable "private_a_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
}
variable "private_b_subnet_cidr_block" {
  description = "IP range in CIDR format for subnet usage"
}
