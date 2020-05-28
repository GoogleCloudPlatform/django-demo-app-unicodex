resource random_password database_user_password {
  length  = 30
  special = false
}

resource google_sql_database_instance postgres {
  name             = var.instance_name
  database_version = "POSTGRES_11"
  region           = var.region

  settings {
    tier = "db-f1-micro"
  }

  depends_on = [var.project]
}

resource google_sql_database database {
  name     = local.database_name
  instance = google_sql_database_instance.postgres.name
}


# TODO(glasnt) - Current database user has cloudsqladmin rights. Requires reducing.
resource google_sql_user user {
  name     = local.database_user
  instance = google_sql_database_instance.postgres.name
  password = random_password.database_user_password.result
}
