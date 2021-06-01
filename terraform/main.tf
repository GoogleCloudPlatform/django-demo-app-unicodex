terraform {
  required_version = "~> 0.15.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.53.0"
    }
  }
}

provider "google" {
  project = var.project
}

data "google_project" "project" {
  project_id = var.project
}

resource "google_service_account" "unicodex" {
  account_id   = var.service
  display_name = "${var.service} service account"
}

locals {
  unicodex_sa   = "serviceAccount:${google_service_account.unicodex.email}"
  cloudbuild_sa = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}
