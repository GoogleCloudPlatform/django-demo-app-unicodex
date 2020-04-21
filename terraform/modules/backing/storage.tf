resource google_storage_bucket media_bucket {
  name = "${var.project}-media"
}

resource google_storage_bucket_access_control media_bucket_public_rule {
  bucket = google_storage_bucket.media_bucket.name
  role   = "READER"
  entity = "allUsers"

  depends_on = [google_storage_bucket.media_bucket]
}

resource google_storage_bucket_iam_member cloudrun_admin {
  bucket = google_storage_bucket.media_bucket.name
  role   = "roles/storage.objectAdmin"
  member = local.cloudrun_sa

  depends_on = [google_service_account.cloudrun, google_storage_bucket.media_bucket]
}