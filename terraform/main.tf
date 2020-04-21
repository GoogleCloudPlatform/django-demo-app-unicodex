provider google {
  project = var.project
}

# Enable all services
module services {
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

module database {
  source = "./modules/database"

  project       = module.services.project_id
  service       = var.service
  region        = var.region
  instance_name = var.instance_name
}

module backing {
  source = "./modules/backing"

  project      = module.services.project_id
  service      = var.service
  region       = var.region
  database_url = module.database.database_url
}

module unicodex {
  source = "./modules/unicodex"

  project               = module.services.project_id
  service               = var.service
  region                = var.region
  database_instance     = module.database.database_instance
  service_account_email = module.backing.service_account_email
}

output result {
  value = <<EOF

    The ${var.service} is now running at ${module.unicodex.service_url}

    If you haven't deployed this service before, you will need to perform the initial database migrations: 

    cd ..
    gcloud builds submit --config .cloudbuild/build-migrate-deploy.yaml \
      --substitutions="_REGION=${var.region},_INSTANCE_NAME=${module.database.short_instance_name},_SERVICE=${var.service}"

    You can then log into the Django admin: ${module.unicodex.service_url}/admin

    The username and password are stored in these secrets: 

    gcloud secrets versions access latest --secret SUPERUSER
    gcloud secrets versions access latest --secret SUPERPASS

    ✨
    EOF
}
