resource google_secret_manager_secret secret {
  provider = google-beta
  project  = var.project

  secret_id = var.name
  replication {
    automatic = true
  }
}

resource google_secret_manager_secret_version secret {
  provider = google-beta

  secret      = google_secret_manager_secret.secret.id
  secret_data = var.secret_data
}

resource google_secret_manager_secret_iam_binding secret {
  provider = google-beta

  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  members   = var.accessors
}
