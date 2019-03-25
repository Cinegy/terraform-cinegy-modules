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

variable "app_name" {
  description = "Name for labelling the deployment, for example 'sysadmin' or 'playout'"
}

# Module specific variables

variable "amazon_owned_ami_name" {
  description = "An AMI name (wildcards supported) for selecting the base image for the VM"
  default = "Windows_Server-2016-English-Full-Base*"
}

variable "aws_secrets_privatekey_arn" {
  description = "ARN representing private key secret stored within AWS Secrets Manager"
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
  default = false
}

variable "data_volume_size" {
  description = "Size of any secondary data volume (default 30GB)"
  default = "30"
}

variable "allow_all_internal_traffic" {
  description = "Allow all internal network traffic (default false)"
  default = false
}

variable "create_external_dns_reference" {
  description = "Create a DNS entry for the public IP of the VM inside the default Route53 zone (default false)"
  default = false
}

variable "shared_route53_zone_id" {
  description = "Zone ID of the default shared route 53 zone used to make helper entries (e.g. sysadmin DNS entries)"
  default = ""
}

variable "shared_route53_zone_suffix" {
  description = "Suffix to append to Route 53 generated entries, should match the value defined inside the Route53 default zone (e.g. terraform.cinegy.net)"
  default = ""
}

variable "user_data_script_extension" {
  description = "Extended element to attach to core user data script. Default renames host to match metadata name tag."
  default = <<EOF
  RenameHost
EOF

}