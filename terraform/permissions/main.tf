###################################################################################

# Creates permissions and misc components

###################################################################################

data "google_project" "project" {
  project_id = var.project
}

resource "google_service_account" "cloudrun" {
  account_id   = var.service
  display_name = "${var.service} service account"
}

###################################################################################
# MEDIA

resource "google_storage_bucket" "media_bucket" {
  name = "${var.project}-media"
}

resource "google_storage_bucket_access_control" "media_bucket_public_rule" {
  bucket = google_storage_bucket.media_bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_iam_member" "cloudrun_admin" {
  bucket     = google_storage_bucket.media_bucket.name
  role       = "roles/storage.objectAdmin"
  member     = local.cloudrun_sa
  depends_on = [google_service_account.cloudrun, google_storage_bucket.media_bucket]
}
###################################################################################
# Permissions

locals {
  cloudrun_sa   = "serviceAccount:${google_service_account.cloudrun.email}"
  cloudbuild_sa = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}


resource "google_project_iam_binding" "service_permissions" {
  for_each = toset([
    "run.admin", "cloudsql.client"
  ])

  role       = "roles/${each.key}"
  members    = [local.cloudbuild_sa, local.cloudrun_sa]
  depends_on = [google_service_account.cloudrun]
}

resource "google_service_account_iam_binding" "cloudbuild_sa" {
  service_account_id = google_service_account.cloudrun.name
  role               = "roles/iam.serviceAccountUser"

  members = [local.cloudbuild_sa]
}

###################################################################################
# Secrets
# Secrets both Cloud Run and Cloud Build need.

module secret_database_url {
  source  = "./secret"
  project = var.project

  name        = "DATABASE_URL"
  secret_data = var.database_url
  accessors   = [local.cloudbuild_sa, local.cloudrun_sa]
}

##

module secret_gs_media_bucket {
  source  = "./secret"
  project = var.project

  name        = "GS_BUCKET_NAME"
  secret_data = google_storage_bucket.media_bucket.name
  accessors   = [local.cloudbuild_sa, local.cloudrun_sa]
}

resource "random_password" "secret_key" {
  length  = 50
  special = false
}

module secret_secret_key {
  source  = "./secret"
  project = var.project

  name        = "SECRET_KEY"
  secret_data = random_password.secret_key.result
  accessors   = [local.cloudbuild_sa, local.cloudrun_sa]
}

# Secret values only Cloud Build needs

module secret_superuser {
  source  = "./secret"
  project = var.project

  name        = "SUPERUSER"
  secret_data = var.superuser
  accessors   = [local.cloudbuild_sa]
}

resource "random_password" "superpass" {
  length  = 30
  special = false
}

module secret_superpass {
  source  = "./secret"
  project = var.project

  name        = "SUPERPASS"
  secret_data = random_password.superpass.result
  accessors   = [local.cloudbuild_sa]
}

