// This terraform manifest PROVISIONS a project ready for a Unicodex DEPLOYMENT. 
//
// Order of operations: 
//  * service enablement
//  * database configuration
//  * permissions, secrets, and access to secrets, misc items
//
// Assumptions: 
//  * project_id is an existing, billing enabled, project.
//  * berglas bootstrap on the "berglas_bucket"
//   - provider requires manual installation https://github.com/sethvargo/terraform-provider-berglas#installation


provider "google" {
  project = var.project
}

# Enable all services
module "services" {
  source = "./services"
}

# Create database
module "database" {
  source = "./database"

  project       = var.project
  instance_name = var.instance_name
  region        = var.region
  slug          = var.slug
}

# Add permissions/misc 
module "permissions" {
  source         = "./permissions"
  project        = var.project
  berglas_bucket = var.berglas_bucket
  slug           = var.slug
  database_url   = module.database.database_url
}
