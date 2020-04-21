module secret_database_url {
  source  = "../secret"
  project = var.project

  name        = "DATABASE_URL"
  secret_data = var.database_url
  accessors   = [local.cloudbuild_sa, local.cloudrun_sa]
}

module secret_gs_media_bucket {
  source  = "../secret"
  project = var.project

  name        = "GS_BUCKET_NAME"
  secret_data = google_storage_bucket.media_bucket.name
  accessors   = [local.cloudbuild_sa, local.cloudrun_sa]
}

resource random_password secret_key {
  length  = 50
  special = false
}

module secret_secret_key {
  source  = "../secret"
  project = var.project

  name        = "SECRET_KEY"
  secret_data = random_password.secret_key.result
  accessors   = [local.cloudbuild_sa, local.cloudrun_sa]
}

module secret_superuser {
  source  = "../secret"
  project = var.project

  name        = "SUPERUSER"
  secret_data = var.superuser
  accessors   = [local.cloudbuild_sa]
}

resource random_password superpass {
  length  = 30
  special = false
}

module secret_superpass {
  source  = "../secret"
  project = var.project

  name        = "SUPERPASS"
  secret_data = random_password.superpass.result
  accessors   = [local.cloudbuild_sa]
}
