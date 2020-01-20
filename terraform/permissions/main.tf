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


# https://github.com/hashicorp/terraform-plugin-sdk/issues/174

# following generated section from stanza.py
# GENERATED SECTION START

#
# Defining secret "superuser"
resource berglas_secret superuser {
  bucket    = var.berglas_bucket
  key       = local.berglas_key
  name      = "superuser"
  plaintext = local.berglas_secrets_list.superuser
}


resource google_storage_object_access_control superuser_sa_email {
  bucket = var.berglas_bucket
  object = berglas_secret.superuser.name
  role   = "READER"
  entity = "user-${local.sa_email}"

  depends_on = [berglas_secret.superuser]
}


resource google_storage_object_access_control superuser_sa_cb_email {
  bucket = var.berglas_bucket
  object = berglas_secret.superuser.name
  role   = "READER"
  entity = "user-${local.sa_cb_email}"

  depends_on = [berglas_secret.superuser, google_storage_object_access_control.superuser_sa_email]
}


#
# Defining secret "media_bucket"
resource berglas_secret media_bucket {
  bucket    = var.berglas_bucket
  key       = local.berglas_key
  name      = "media_bucket"
  plaintext = local.berglas_secrets_list.media_bucket
}


resource google_storage_object_access_control media_bucket_sa_email {
  bucket = var.berglas_bucket
  object = berglas_secret.media_bucket.name
  role   = "READER"
  entity = "user-${local.sa_email}"

  depends_on = [berglas_secret.media_bucket]
}


resource google_storage_object_access_control media_bucket_sa_cb_email {
  bucket = var.berglas_bucket
  object = berglas_secret.media_bucket.name
  role   = "READER"
  entity = "user-${local.sa_cb_email}"

  depends_on = [berglas_secret.media_bucket, google_storage_object_access_control.media_bucket_sa_email]
}


#
# Defining secret "superpass"
resource berglas_secret superpass {
  bucket    = var.berglas_bucket
  key       = local.berglas_key
  name      = "superpass"
  plaintext = local.berglas_secrets_list.superpass
}


resource google_storage_object_access_control superpass_sa_email {
  bucket = var.berglas_bucket
  object = berglas_secret.superpass.name
  role   = "READER"
  entity = "user-${local.sa_email}"

  depends_on = [berglas_secret.superpass]
}


resource google_storage_object_access_control superpass_sa_cb_email {
  bucket = var.berglas_bucket
  object = berglas_secret.superpass.name
  role   = "READER"
  entity = "user-${local.sa_cb_email}"

  depends_on = [berglas_secret.superpass, google_storage_object_access_control.superpass_sa_email]
}


#
# Defining secret "database_url"
resource berglas_secret database_url {
  bucket    = var.berglas_bucket
  key       = local.berglas_key
  name      = "database_url"
  plaintext = local.berglas_secrets_list.database_url
}


resource google_storage_object_access_control database_url_sa_email {
  bucket = var.berglas_bucket
  object = berglas_secret.database_url.name
  role   = "READER"
  entity = "user-${local.sa_email}"

  depends_on = [berglas_secret.database_url]
}


resource google_storage_object_access_control database_url_sa_cb_email {
  bucket = var.berglas_bucket
  object = berglas_secret.database_url.name
  role   = "READER"
  entity = "user-${local.sa_cb_email}"

  depends_on = [berglas_secret.database_url, google_storage_object_access_control.database_url_sa_email]
}


#
# Defining secret "secret_key"
resource berglas_secret secret_key {
  bucket    = var.berglas_bucket
  key       = local.berglas_key
  name      = "secret_key"
  plaintext = local.berglas_secrets_list.secret_key
}


resource google_storage_object_access_control secret_key_sa_email {
  bucket = var.berglas_bucket
  object = berglas_secret.secret_key.name
  role   = "READER"
  entity = "user-${local.sa_email}"

  depends_on = [berglas_secret.secret_key]
}


resource google_storage_object_access_control secret_key_sa_cb_email {
  bucket = var.berglas_bucket
  object = berglas_secret.secret_key.name
  role   = "READER"
  entity = "user-${local.sa_cb_email}"

  depends_on = [berglas_secret.secret_key, google_storage_object_access_control.secret_key_sa_email]
}

# GENERATED SECTION END

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


