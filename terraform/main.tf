terraform {
  required_version = "~> 0.15.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.53.0"
    }
  }
  backend "gcs" {
    bucket = "unicodex-ci-023834-tfstate"
  }
}

provider "google" {
  project = var.project
}

data "google_project" "project" {
  project_id = var.project
}

resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "secretmanager.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

resource "google_service_account" "unicodex" {
  account_id   = var.service
  display_name = "${var.service} service account"
}

locals {
  unicodex_sa   = "serviceAccount:${google_service_account.unicodex.email}"
  cloudbuild_sa = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}
