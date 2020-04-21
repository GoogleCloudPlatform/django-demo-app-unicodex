resource google_project_iam_binding service_permissions {
  for_each = toset([
    "run.admin", "cloudsql.client"
  ])

  role       = "roles/${each.key}"
  members    = [local.cloudbuild_sa, local.cloudrun_sa]
  depends_on = [google_service_account.cloudrun]
}

resource google_service_account_iam_binding cloudbuild_sa {
  service_account_id = google_service_account.cloudrun.name
  role               = "roles/iam.serviceAccountUser"

  members = [local.cloudbuild_sa]
}