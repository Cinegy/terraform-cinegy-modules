output "mssql_id" {
  description = "Identifier of the mssql DB instance"
  value       = aws_db_instance.mssql.id
}

output "mssql_address" {
  description = "Address of the mssql DB instance"
  value       = aws_db_instance.mssql.address
}

