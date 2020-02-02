output "main_vpc" {
  value = aws_vpc.main.id
}

output "main_vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnets" {
  value = {
    "a" = aws_subnet.public_a.id
    "b" = aws_subnet.public_b.id
  }
}

output "private_subnets" {
  value = {
    "a" = aws_subnet.private_a.id
    "b" = aws_subnet.private_b.id
  }
}

output "remote_access_security_group" {
  value = aws_security_group.remote_access.id
}

output "open_internal_access_security_group" {
  value = aws_security_group.open_internal.id
}

output "lambda_base_iam_arn" {
  value = aws_iam_role.iam_for_logging.arn
}

output "lambda_iam_policy_logging_arn" {
  value = aws_iam_policy.cloudwatch_logging.arn
}

/*
output "logging_iam_arn" {
  value = "${aws_iam_role.iam_for_logging.arn}"
}


output "lambda_iam_policy_logging_arn" {
  value = "${aws_iam_policy.iam_for_logging.arn}"
}*/
