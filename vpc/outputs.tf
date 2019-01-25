output "main_vpc" {
  value = "${aws_vpc.main.id}"
}

output "main_vpc_cidr" {
  value = "${aws_vpc.main.cidr_block}"
}
output "public_subnets" {
  value = "${
    map(
      "a", "${aws_subnet.public_a.id}",
      "b", "${aws_subnet.public_b.id}"
    )
  }"
}

output "private_subnets" {
  value = "${
    map(
      "a", "${aws_subnet.private_a.id}",
      "b", "${aws_subnet.private_b.id}"
    )
  }"
}

output "remote_access_security_group"{
  value = "${aws_security_group.remote_access.id}"
}

output "open_internal_access_security_group"{
  value = "${aws_security_group.open_internal.id}"
}
