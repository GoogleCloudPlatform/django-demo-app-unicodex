resource "google_storage_bucket" "media" {
  name     = "${var.project}-media"
  location = "US"
}
