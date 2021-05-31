locals {
  database_user = "${var.service}-django"
  database_name = var.service
}

resource "random_password" "database_user_password" {
  length  = 30
  special = false
}

resource "google_sql_database_instance" "postgres" {
  name             = var.instance_name
  database_version = "POSTGRES_13"
  project          = var.project
  region           = var.region

  settings {
    tier = "db-f1-micro"
  }

}

resource "google_sql_database" "database" {
  name     = local.database_name
  instance = google_sql_database_instance.postgres.name
}

# NOTE: users created this way automatically gain cloudsqladmin rights.
resource "google_sql_user" "django" {
  name     = local.database_user
  instance = google_sql_database_instance.postgres.name
  password = random_password.database_user_password.result
}
