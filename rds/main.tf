terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.global_state_bucket
    region = var.state_region
    key    = "${var.environment_name}/vpc/terraform.tfstate"
  }
}

provider "aws" {
  region  = var.aws_region
  version = "~> 2.9"
}

data "aws_subnet_ids" "filtered_subnets" {
  vpc_id = data.terraform_remote_state.vpc.outputs.main_vpc

  tags = {
    Tier = var.aws_subnet_tier
    AZ   = var.aws_subnet_az
  }
}

# Get general account password secret for SA password
data "aws_secretsmanager_secret" "password" {
  arn = var.aws_secrets_generic_account_password_arn
}

data "aws_secretsmanager_secret_version" "password" {
  secret_id = data.aws_secretsmanager_secret.password.id
}

resource "aws_db_subnet_group" "mssql" {
  description = "The ${var.environment_name} RDS ${var.rds_instance_name_prefix} instance private subnet group."
  subnet_ids  = data.aws_subnet_ids.filtered_subnets.ids

  tags = {
    Name      = "RDS-${var.rds_instance_name_prefix}-subnet-group-${var.environment_name}"
    Env       = var.environment_name
    Terraform = true
  }
}

resource "aws_security_group" "rds_mssql_security_group" {
  name        = "Internal-MSSQL-Traffic-To-RDS-${var.rds_instance_name_prefix}-${var.environment_name}"
  description = "Allows all VPC traffic to RDS MSSQL default port in ${var.environment_name}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.main_vpc

  ingress {
    from_port = 1433
    to_port   = 1433
    protocol  = "tcp"
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.main_vpc_cidr]
  }

  tags = {
    Env       = var.environment_name
    Terraform = true
  }
}

resource "aws_db_parameter_group" "clr_enabled" {
  name   = "clr-enabled-parameters-${var.rds_instance_name_prefix}-${var.environment_name}"
  family = var.mssql_engine_family

  parameter {
    name  = "clr enabled"
    value = "1"
  }
}

resource "aws_iam_role" "iam_role_sql_backup_restore" {
  name        = "IAM_ROLE_SQL_BACKUP_RESTORE-${var.rds_instance_name_prefix}-${var.environment_name}"
  path        = "/"
  description = "RDS SQL Server Native Backup Without Encryption "

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "name" {
  name   = "IAM_POLICY_SQL_BACKUP_S3_ACCESS-${var.rds_instance_name_prefix}-${var.environment_name}"
  role   = aws_iam_role.iam_role_sql_backup_restore.id
  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::${var.state_bucket}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload"
            ],
            "Resource": [
                "arn:aws:s3:::${var.state_bucket}/${var.environment_name}/sqlbackups/${var.rds_instance_name_prefix}/*"
            ]
        }
    ]
}
EOF

}

resource "aws_db_option_group" "sqlexpress-native-backup-restore" {
  name                     = "sqlexpress-native-backup-restore-${var.rds_instance_name_prefix}-${var.environment_name}"
  option_group_description = "DB Option Group for backup and restore on ${var.mssql_engine_family}"
  engine_name              = var.mssql_engine
  major_engine_version     = var.engine_major_version

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.iam_role_sql_backup_restore.arn
    }
  }
}

resource "aws_db_instance" "mssql" {
  depends_on                = [aws_db_subnet_group.mssql]
  identifier                = "${var.rds_instance_name_prefix}-${var.environment_name}"
  allocated_storage         = var.rds_allocated_storage
  license_model             = "license-included"
  storage_type              = "gp2"
  engine                    = var.mssql_engine
  engine_version            = var.engine_specific_version
  instance_class            = var.rds_instance_class
  multi_az                  = var.rds_multi_az
  username                  = var.mssql_admin_username
  password                  = data.aws_secretsmanager_secret_version.password.secret_string
  vpc_security_group_ids    = [aws_security_group.rds_mssql_security_group.id]
  db_subnet_group_name      = aws_db_subnet_group.mssql.id
  backup_retention_period   = 3
  skip_final_snapshot       = var.rds_skip_final_snapshot
  final_snapshot_identifier = "${var.rds_instance_name_prefix}-${var.environment_name}-final-snapshot"
  parameter_group_name      = aws_db_parameter_group.clr_enabled.name
  option_group_name         = aws_db_option_group.sqlexpress-native-backup-restore.name

  tags = {
    Env       = var.environment_name
    Terraform = true
  }
}

