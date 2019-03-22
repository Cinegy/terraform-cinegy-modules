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

variable "vm_name_tag_value" {
  description = "Value of the 'name' tag for the VM that will run the command"
}

variable "powershell_script_path" {
  description = "Path of the powershell script to be read and injected to SSM"
}

variable "template_vars" {
  description = "Array of variable key / values to inject to script when rendering as template"
  default = {
    somekey = "somevalue"
    anotherkey = "someothervalue"
  }
}

variable "aws_access_key" {
  description = "Optional AWS access key to pass through to the script"
  default = ""
}

variable "aws_session" {
  description = "Optional AWS session token to pass through to the script"
  default = ""
}

variable "aws_secret_access_key" {
  description = "Optional secret access key to pass through to the script"
  default = ""
}
