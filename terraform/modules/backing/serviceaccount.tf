resource google_service_account cloudrun {
  account_id   = var.service
  display_name = "${var.service} service account"
}

locals {
  cloudrun_sa   = "serviceAccount:${google_service_account.cloudrun.email}"
  cloudbuild_sa = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}