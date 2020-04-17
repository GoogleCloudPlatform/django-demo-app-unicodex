###################################################################################

# Creates a Cloud Run Service

###################################################################################

resource google_cloud_run_service unicodex {
  name                       = var.service
  location                   = var.region
  autogenerate_revision_name = true

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}/${var.service}"
        env {
          name  = "CURRENT_HOST"
          value = "*"
        }
        env {
          name  = "DEBUG"
          value = "True"
        }
      }
      service_account_name = var.service_account_email
    }
    metadata {
      annotations = {
        "run.googleapis.com/cloudsql-instances" = var.database_instance
        "run.googleapis.com/client-name"        = "terraform"
      }
    }
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
  location = google_cloud_run_service.unicodex.location
  project  = google_cloud_run_service.unicodex.project
  service  = google_cloud_run_service.unicodex.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
