output database_url {
  description = "The ODBC connetion string"
  value       = "postgres://${google_sql_user.user.name}:${google_sql_user.user.password}@//cloudsql/${var.project}:${var.region}:${google_sql_database_instance.postgres.name}/${local.database_name}"
}

output database_instance {
  description = "The database project-region-instance triple"
  value       = "${var.project}:${var.region}:${google_sql_database_instance.postgres.name}"
}

output short_instance_name {
  description = "The short-form instance-only name"
  value       = google_sql_database_instance.postgres.name
}
