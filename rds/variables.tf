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

variable "global_state_bucket" {
  description = "Name of bucket used to hold state for the global deployment."
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

variable "stage" {
  description = "Deployment stage label, e.g. blue or green"
  default = "blue"
}

variable "shared_route53_zone_suffix" {
  description = "Zone DNS suffix for helper entries (e.g. sysadmin DNS entries)"
}

variable "debug_logging" {
  description = "Debugging flag, used to increase debug logging (e.g. from within Lambda functions)"
  default = "false"
}

# Module specific variables

variable "aws_subnet_tier" {
  description = "Tier of subnet for deployment (Private / Public)"
}

variable "aws_subnet_az" {
  description = "Availability Zone for deployment (A/B/...)"
}

variable "rds_instance_class" {
  description = "Required instance class for RDS server"
  default     = "db.t2.micro"
}

variable "rds_multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  default     = "false"
}

variable "rds_allocated_storage" {
  description = "The allocated storage in gigabytes"
  default     = "20"
}

variable "rds_skip_final_snapshot" {
  description = "Specifies if a final snapshot should be created upon RDS destruction"
  default     = false
}

variable "mssql_engine" {
  description = "AWS RDS string matching the MSSQL engine type to instance (e.g. sqlserver-ex)"
  default     = "sqlserver-ex"
}

variable "mssql_engine_family" {
  description = "AWS RDS string matching the MSSQL engine family to instance (e.g. sqlserver-ex-13.0)"
  default     = "sqlserver-ex-13.0"
}

variable "engine_specific_version" {
  description = "AWS RDS string matching the MSSQL engine specific version to instance (e.g. 13.00.5216.0.v1)"
  default     = "13.00.5216.0.v1"
}

variable "engine_major_version" {
  description = "AWS RDS string matching the MSSQL engine major version to instance (e.g. 13.00)"
  default     = "13.00"
}

variable "mssql_admin_username" {
  description = "Username for the administrator DB user"
  default     = "sa"
}

variable "rds_instance_name_prefix" {
  description = "Prefix value to use when naming created RDS instance (e.g. CINARC1)"
}
