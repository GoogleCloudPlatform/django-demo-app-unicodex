locals {
  service_url = google_cloud_run_service.unicodex.status[0].url
}

output "result" {
  value = <<EOF

    The ${var.service} is now running at ${local.service_url}

    If you haven't deployed this service before, you will need to perform the initial database migrations: 

    cd ..
    gcloud builds submit --config .cloudbuild/build-migrate-deploy.yaml --project ${var.project} \
      --substitutions="_REGION=${google_cloud_run_service.unicodex.location},_INSTANCE_NAME=${google_sql_database_instance.postgres.name},_SERVICE=${google_cloud_run_service.unicodex.name}"

    You can then log into the Django admin: ${local.service_url}/admin

    The username and password are stored in these secrets: 

    gcloud secrets versions access latest --secret SUPERUSER
    gcloud secrets versions access latest --secret SUPERPASS

    ✨
    EOF
}