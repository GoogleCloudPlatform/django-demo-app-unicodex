output "database_url" {
  description = "The ODBC connetion string"
  value       = "postgres://${google_sql_user.user.name}:${google_sql_user.user.password}@//cloudsql/${local.database_instance_fqdn}/${local.database_name}"
}
output "database_instance" {
  description = "The database project-region-instance triple"
  value       = local.database_instance_fqdn
}
