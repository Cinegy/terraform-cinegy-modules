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

variable "aws_secrets_privatekey_arn" {
  description = "ARN representing private PEM key secret stored within AWS Secrets Manager"
}

variable "stage" {
  description = "Deployment stage label, e.g. global or global-temp"
  default = "global"
}

# Module specific variables
variable "es_domain_name" {
  description = "Domain name associated to the ES instance"
}

variable "es_version" {
  description = "Version of ElasticSearch to deploy (must be one of the valid AWS versions)"
  default = "7.1"
}

variable "instance_type" {
  description = "Instance within which to run the ElasticSearch main node"
}

variable "snapshot_hour" {
  description = "Hour of the day for which snapshot backup to be executed"
  default = "23"
}

variable "volume_size" {
  description = "Size of the EBS volume attached to nodes (GB)"
  default = 10
}


