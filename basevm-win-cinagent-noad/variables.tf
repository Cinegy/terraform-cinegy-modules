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

variable "stage" {
  description = "Deployment stage label, e.g. blue or green"
  default = "blue"
}

# Module specific variables

variable "amazon_owned_ami_name" {
  description = "An AMI name (wildcards supported) for selecting the base image for the VM"
  default     = "Windows_Server-2016-English-Full-Base*"
}

variable "instance_type" {
  description = "Required instance type for server"
}

variable "aws_subnet_tier" {
  description = "Tier of subnet for deployment (Private / Public)"
}

variable "aws_subnet_az" {
  description = "Availability Zone for deployment (A/B/...)"
}

variable "host_name_prefix" {
  description = "Prefix value to use in Hostname metadata tag (e.g. CIS1A)"
}

variable "host_description" {
  description = "Prefix description to use in Name metadata tag (e.g. Cinegy Identity Service (CIS) 01)"
}

variable "attach_data_volume" {
  description = "Attach a secondary data volume to the host (default false)"
  default     = false
}

variable "data_volume_size" {
  description = "Size of any secondary data volume (default 30GB)"
  default     = "30"
}

variable "allow_all_internal_traffic" {
  description = "Allow all internal network traffic (default false)"
  default     = false
}

variable "create_external_dns_reference" {
  description = "Create a DNS entry for the public IP of the VM inside the default Route53 zone (default false)"
  default     = false
}

variable "user_data_script_extension" {
  description = "Extended element to attach to core user data script. Default installs Cinegy Agent with base elements and renames host to match metadata name tag."
  default     = <<EOF
  InstallAgent
  AddDefaultPackages
  RenameHost
EOF

}

