# Standard variables for managing state and deployment
variable "environment_name" {
  description = "Name to used to label environment deployment, for example 'dev' or 'test-lk'."
}

variable "state_bucket" {
  description = "Name of bucket used to hold state."
}

variable "state_region" {
  description = "Region associated with state bucket."
  default = "eu-west-1"
}

variable "aws_region" {
  description = "AWS region to launch infrastructure within."
}

# Module specific variables
variable "domain_name" {
  description = "Active Directory Domain Name"
}

variable "domain_default_computer_ou" {
  description = "Default OU for new computer account creation"
}

variable "aws_secrets_domain_admin_password_arn" {
  description = "ARN representing domain admin password key secret stored within AWS Secrets Manager"
}

variable "directory_edition" {
  description = "Directory edition to instance, applies only to MS AD instances (default Standard)"
  default = "Standard"
}
