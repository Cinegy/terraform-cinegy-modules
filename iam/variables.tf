# Standard variables for managing state and deployment
variable "environment_name" {
  description = "Name to used to label environment deployment, for example 'dev' or 'test-lk'."
}

variable "aws_account_id" {
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

variable "aws_secrets_generic_account_password_arn" {
  description = "ARN representing general password secret stored within AWS Secrets Manager"
}

variable "aws_secrets_domain_admin_password_arn" {
  description = "ARN representing domain admin password key secret stored within AWS Secrets Manager"
}

variable "aws_secrets_privatekey_arn" {
  description = "ARN representing private PEM key secret stored within AWS Secrets Manager"
}


variable "dynamodb_table" {
  description = "DynamoDB table used for controlling terragrunt locks"
}

variable "stage" {
  description = "Deployment stage label, e.g. global or global-temp"
  default = "global"
}

# Module specific variables
