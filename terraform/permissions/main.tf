###################################################################################

# Creates permissions and misc components

###################################################################################
# MEDIA

resource "google_storage_bucket" "media_bucket" {
  name = "${var.project}-${var.slug}-media"
}
resource "google_storage_bucket_access_control" "media_bucket_public_rule" {
  bucket = google_storage_bucket.media_bucket.name
  role   = "READER"
  entity = "allUsers"
}

###################################################################################
# BERGLAS

resource "google_service_account" "berglas" {
  account_id   = "cloudrun-berglas-python"
  display_name = "Unicodex service account"
}

resource "random_password" "secret_key" {
  length  = 50
  special = false
}

resource "random_password" "superpass" {
  length  = 30
  special = false
}

locals {
  berglas_key = "projects/${var.project}/locations/global/keyRings/berglas/cryptoKeys/berglas-key"
  berglas_secrets_list = {
    database_url = var.database_url
    superuser    = "admin"
    superpass    = random_password.superpass.result
    secret_key   = random_password.secret_key.result
    media_bucket = google_storage_bucket.media_bucket.name
  }

  sa_email    = "${google_service_account.berglas.account_id}@${var.project}.iam.gserviceaccount.com"
  sa_cb_email = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

}

resource "google_kms_crypto_key_iam_member" "service_account" {
  crypto_key_id = local.berglas_key
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  member        = "serviceAccount:${local.sa_email}"
}


resource "google_kms_crypto_key_iam_member" "cloudbuild" {
  crypto_key_id = local.berglas_key
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  member        = "serviceAccount:${local.sa_cb_email}"
}

###################################################################################

# IAM Permissions for service accounts. 

data "google_project" "project" {
  project_id = var.project
}

resource "google_project_iam_binding" "sa_runview" {
  role = "roles/run.viewer"

  members = ["serviceAccount:${local.sa_email}"]
}

resource "google_project_iam_binding" "cloudbuild" {
  for_each = toset([
    "run.admin", "iam.serviceAccountUser", "cloudsql.admin"
  ])

  role    = "roles/${each.key}"
  members = ["serviceAccount:${local.sa_cb_email}"]
}

resource "google_project_iam_binding" "cloudrun" {
  for_each = toset([
    "run.admin", "cloudsql.client"
  ])
  role    = "roles/cloudsql.client"
  members = ["serviceAccount:${local.sa_email}"]
}

