resource random_password secret_key {
  length  = 50
  special = false
}

module secret_django_settings {
  source  = "../secret"
  project = var.project

  name        = "django_settings"
  secret_data = templatefile("${path.module}/env.tpl", 
    {
        database_url = var.database_url
        gs_bucket_name = google_storage_bucket.media_bucket.name
        secret_key = random_password.secret_key.result
    }) 
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
