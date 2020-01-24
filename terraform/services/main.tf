# SERVCICES
#
# Ensure all services we require are enabled. 
# Source https://www.terraform.io/docs/providers/google/guides/version_3_upgrade.html#new-config-google_project_service-

resource "google_project_service" "enable" {
  for_each = toset([
    "run.googleapis.com",
    "compute.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "storage-component.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "storage-api.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ])

  service = each.key

  disable_on_destroy = false
}
