// This terraform manifest PROVISIONS a project ready for a Unicodex DEPLOYMENT. 
//
// Order of operations: 
//  * service enablement
//  * database configuration
//  * permissions, secrets, and access to secrets, misc items
//
// Assumptions: 
//  * project_id is an existing, billing enabled, project.


provider "google" {
  project = var.project
}

# Enable all services
module "services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "4.0.0"

  project_id = var.project

  activate_apis = [
    "run.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "storage-component.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "storage-api.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

# Create database
module "database" {
  source = "./database"

  project       = module.services.project_id
  service       = var.service
  region        = var.region
  instance_name = var.instance_name
}

# Add permissions/secrets 
module "permissions" {
  source = "./permissions"

  project      = module.services.project_id
  service      = var.service
  region       = var.region
  database_url = module.database.database_url
}
