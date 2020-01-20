locals {
  database_user    = "${var.slug}-django-user"
  database_name    = "${var.slug}-database"

  database_instance_fqdn = "${var.project}:${var.region}:${google_sql_database_instance.postgres.name}"
}

###################################################################################
# DATABASE

resource "random_password" "database_user_password" {
  length  = 30
  special = false
}

resource "google_sql_user" "user" {
  name     = local.database_user
  instance = google_sql_database_instance.postgres.name
  password = random_password.database_user_password.result
}

resource "google_sql_database" "database" {
  name     = local.database_name
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_database_instance" "postgres" {
  name             = var.instance_name
  database_version = "POSTGRES_11"
  region           = var.region

  settings {
    tier = "db-f1-micro"
  }
}

# TODO(glasnt) - check default user rights for database user, check how to grant if missing. 

locals { 
database_url = "postgres://${google_sql_user.user.name}:${google_sql_user.user.password}@//cloudsql/${local.database_instance_fqdn}/${local.database_name}"
} 
