
resource "google_cloud_run_service" "unicodex" {
  name                       = var.service
  location                   = var.region
  autogenerate_revision_name = true
  template {
    spec {
      service_account_name = google_service_account.unicodex.email
      containers {
        image = "gcr.io/${var.project}/unicodex" #data.external.image_digest.result.image
        env {
          name = "CURRENT_HOST"
          value = "*" # Terraform workaround: can't know the service URL without the service existing.
        }
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "100"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.postgres.connection_name
        "run.googleapis.com/client-name"        = "terraform"
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}
resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.unicodex.location
  project     = google_cloud_run_service.unicodex.project
  service     = google_cloud_run_service.unicodex.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

# WORKAROUND this script ensures the most recent image is assigned to the Cloud Run service
# as Terraform doesn't process "latest" with any context. 
#data "external" "image_digest" {
#  program = ["sh", "etc/get_image_digest.sh", var.project, var.service]
#}
# END WORKAROUND
