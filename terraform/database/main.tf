###################################################################################

# Creates a Cloud SQL instance, database, and user. 
# Returns a database_url connection string, and database_instance triple.

###################################################################################

locals {
  database_user = "${var.service}-django"
  database_name = "${var.service}"

  database_instance_fqdn = "${var.project}:${var.region}:${google_sql_database_instance.postgres.name}"
}

###################################################################################

resource "random_password" "database_user_password" {
  length  = 30
  special = false
}

resource "google_sql_database_instance" "postgres" {
  name             = var.instance_name
  database_version = "POSTGRES_11"
  region           = var.region

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "database" {
  name     = local.database_name
  instance = google_sql_database_instance.postgres.name
}


# TODO(glasnt) - Current database user has cloudsqladmin rights. Requires reducing. 
resource "google_sql_user" "user" {
  name     = local.database_user
  instance = google_sql_database_instance.postgres.name
  password = random_password.database_user_password.result
}

locals {
  database_url = "postgres://${google_sql_user.user.name}:${google_sql_user.user.password}@//cloudsql/${local.database_instance_fqdn}/${local.database_name}"
}
