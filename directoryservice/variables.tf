# Standard variables for managing state and deployment
variable "aws_region" {
  description = "AWS region to launch infrastructure within."
}

variable "state_bucket" {
  description = "Name of bucket used to hold state."
}

variable "state_region" {
  description = "Region associated with state bucket."
  default     = "eu-west-1"
}

variable "environment_name" {
  description = "Name to used to label environment deployment, for example 'dev' or 'test-lk'."
}

variable "app_name" {
  description = "Name for labelling the deployment, for example 'sysadmin' or 'playout'"
}

variable "domain_name" {
  description = "Active Directory Domain Name"
}

variable "domain_default_computer_ou" {
  description = "Default OU for new computer account creation"
}

variable "aws_secrets_privatekey_arn" {
  description = "ARN representing private key secret stored within AWS Secrets Manager"
}

variable "aws_secrets_domain_admin_password_arn" {
  description = "ARN representing domain admin password key secret stored within AWS Secrets Manager"
}

variable "aws_secrets_generic_account_password_arn" {
  description = "ARN representing a key / value set of generic account names and passwords secrets stored within AWS Secrets Manager"
  default     = ""
}

variable "aws_account_id" {
  description = "Account ID for the AWS account related to the executing user"
}

variable "dynamodb_table" {
  description = "DynamoDB table used for controlling terragrunt locks"
}

variable "shared_route53_zone_id" {
  description = "Zone ID of the default shared route 53 zone used to make helper entries (e.g. sysadmin DNS entries)"
  default     = ""
}

variable "shared_route53_zone_suffix" {
  description = "Suffix to append to Route 53 generated entries, should match the value defined inside the Route53 default zone (e.g. terraform.cinegy.net)"
  default     = ""
}

# Module specific variables
variable "directory_type" {
  description = "Directory type to create - can be SimpleAD or MicrosoftAD (default SimpleAD)"
  default     = "SimpleAD"  
}

variable "directory_edition" {
  description = "Directory edition to instance, applies only to MS AD instances (default null, creates a cheaper and quicker simple AD)"
  default     = null
}
