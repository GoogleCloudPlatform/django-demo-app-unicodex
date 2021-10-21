resource "random_password" "superuser_password" {
  length  = 32
  special = false
}
resource "google_secret_manager_secret" "superuser_password" {
  secret_id = "superuser_password"
  replication {
    automatic = true
  }
}
resource "google_secret_manager_secret_iam_binding" "superuser_password" {
  secret_id = google_secret_manager_secret.superuser_password.id
  role      = "roles/secretmanager.secretAccessor"
  members   = [local.cloudbuild_sa]
}
resource "google_secret_manager_secret_version" "superuser_password" {
  secret      = google_secret_manager_secret.superuser_password.id
  secret_data = random_password.superuser_password.result
}

resource "random_password" "django_secret_key" {
  special = false
  length  = 50
}

resource "google_secret_manager_secret" "django_settings" {
  secret_id = "django_settings"
  replication {
    automatic = true
  }
}
resource "google_secret_manager_secret_version" "django_settings" {
  secret = google_secret_manager_secret.django_settings.id
  secret_data = templatefile("etc/env.tpl", {
    bucket     = google_storage_bucket.media.name
    secret_key = random_password.django_secret_key.result
    user       = google_sql_user.django
    instance   = google_sql_database_instance.postgres
    database   = google_sql_database.database
  })
}
resource "google_secret_manager_secret_iam_binding" "django_settings" {
  secret_id = google_secret_manager_secret.django_settings.id
  role      = "roles/secretmanager.secretAccessor"
  members   = [local.cloudbuild_sa, local.unicodex_sa]
}
