
output "media_bucket" {
  description = "The mediabucket in which to store assets"
  value = google_storage_bucket.media_bucket.name
}
