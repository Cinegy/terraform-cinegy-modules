# Standard variables for managing state and deployment
variable "environment_name" {
  description = "Name to used to label environment deployment, for example 'dev' or 'test-lk'."
}

variable "account_id" {
  description = "AWS account ID, used when constructing ARNs for API Gateway."
}

variable "state_bucket" {
  description = "Name of bucket used to hold state."
}

variable "state_region" {
  description = "Region associated with state bucket."
  default     = "eu-west-1"
}

variable "aws_region" {
  description = "AWS region to launch infrastructure within."
}

variable "app_name" {
  description = "Name to used to label application deployment, for example 'central' or 'air'."
}

variable "route53_zone_id" {
  description = "Zone ID of the route 53 zone used to make entries (e.g. sysadmin DNS entries)"
  default     = ""
}

variable "route53_zone_suffix" {
  description = "Zone DNS suffix for public facing entries"
}

variable "aws_secrets_generic_account_password_arn" {
  description = "ARN representing general password secret stored within AWS Secrets Manager"
}

variable "aws_secrets_domain_admin_password_arn" {
  description = "ARN representing domain admin password key secret stored within AWS Secrets Manager"
}

variable "aws_secrets_privatekey_arn" {
  description = "ARN representing private PEM key secret stored within AWS Secrets Manager"
}

variable "shared_route53_zone_id" {
  description = "Zone ID of the default shared route 53 zone used to make helper entries (e.g. sysadmin DNS entries)"
  default     = ""
}

variable "dynamodb_table" {
  description = "DynamoDB table used for controlling terragrunt locks"
}

variable "shared_route53_zone_suffix" {
  description = "Zone DNS suffix for helper entries (e.g. sysadmin DNS entries)"
}

variable "domain_name" {
  description = "Active Directory Domain Name"
}

variable "domain_default_computer_ou" {
  description = "Default OU for new computer account creation"
}

variable "stage" {
  description = "Deployment stage label, e.g. global or global-temp"
  default = "global"
}

# Module specific variables
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

variable "cinegy_agent_default_manifest_path" {
  description = "Path to a file containing the defaults to use when creating an Cinegy Agent manifest file"
  default     = "./conf/defaultproducts.manifest"
}

