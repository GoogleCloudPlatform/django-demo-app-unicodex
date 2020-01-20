// This terraform manifest PROVISIONS a project ready for a Unicodex DEPLOYMENT. 
//
// Order of operations (hopefully): 
//  * service enablement
//  * database configuration
//  * permissions, secrets, and access to secrets
//  * deployment
//
// Assumptions: 
//  * project_id is an existing, billing enabled, project.
//  * berglas bootstrap on the "berglas_bucket"
//   - provider requires manual installation https://github.com/sethvargo/terraform-provider-berglas#installation
//
// Known issues:
//  * berglas_secrets from dynamic sources cannot be re-created
//   -> "gsutil rm <bucket>/<object>", and try again
//


provider "google" {
  project = var.project
}

module "services" {
  source = "./services"
}

module "database" {
  source = "./database"

  project       = var.project
  instance_name = var.instance_name
  region        = var.region
  slug          = var.slug
}

module "permissions" {
  source         = "./permissions"
  project        = var.project
  berglas_bucket = var.berglas_bucket
  slug           = var.slug
  database_url   = module.database.database_url
}
