resource "google_storage_bucket" "media" {
  name     = "${var.project}-media"
  location = "US"
}

data "google_iam_policy" "mediaaccess" {
  binding {
    role = "roles/storage.objectAdmin"
    members = [local.unicodex_sa]
  }
}

resource "google_storage_bucket_iam_policy" "policy" {
  bucket = google_storage_bucket.media.name
  policy_data = data.google_iam_policy.mediaaccess.policy_data
}