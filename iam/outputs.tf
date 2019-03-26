output "terragrunt_ro_access_key_id" {
  value = "${aws_iam_access_key.terragrunt_ro.id}"
}

output "instance_profile_domain_join_name" {
 value = "${aws_iam_instance_profile.instance_profile_domain_join.name}"
}
