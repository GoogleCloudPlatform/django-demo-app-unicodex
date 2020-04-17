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
  version = "7.0.2"

  project_id = var.project

  activate_apis = [
    "run.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
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

# Create a Cloud Run service
module "service" {
  source = "./service"

  project               = module.services.project_id
  service               = var.service
  region                = var.region
  database_instance     = module.database.database_instance
  service_account_email = module.permissions.service_account_email
}

# Output the results to the user
output "result" {
  value = <<EOF
    ✨ 
    
    The ${var.service} is now running at ${module.service.service_url}

    You need to perform the initial migrations: 

    cd ..
    gcloud builds submit --config .cloudbuild/build-migrate-deploy.yaml --substitutions="_REGION=${var.region},_INSTANCE_NAME=${module.database.short_instance_name},_SERVICE=${var.service}"

    You can then log into the service using the superuser name and password: 

    gcloud secrets versions access latest --secret SUPERUSER
    gcloud secrets versions access latest --secret SUPERPASS

    ✨
    EOF
}
