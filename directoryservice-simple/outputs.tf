output "directory_service_id" {
  value = "${aws_directory_service_directory.ad.id}"
}

output "instance_profile_domain_join_name" {
 value = "${aws_iam_instance_profile.instance_profile_domain_join.name}"
}

output "directory_service_default_doc_name" {
    value = "${aws_ssm_document.directory_service_default_doc.name}"
}