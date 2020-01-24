output "database_url" {
  description = "The ODBC connetion string"
  value       = local.database_url
}

output "database_instance" {
  description = "The database project-region-instance triple"
  value       = local.database_instance_fqdn
}
