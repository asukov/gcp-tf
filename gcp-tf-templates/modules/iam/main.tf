resource "google_project_iam_member" "service_account_admin" {
  # Grant Service Account Admin to tf-rw service account (required for creating and impersonating service accounts)
  count   = var.enable_vm_permissions || var.enable_cloudrun_permissions ? 1 : 0
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${var.terraform_service_account}"
}

resource "google_project_iam_member" "vm_admin_permissions" {
  # Grant VM admin to tf-rw service account (required for VM creation and management)
  count   = var.enable_vm_permissions ? 1 : 0
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${var.terraform_service_account}"
}

data "google_compute_default_service_account" "default" {
  # Get default compute service account data
  count   = var.enable_vm_permissions ? 1 : 0
  depends_on = [google_project_iam_member.vm_admin_permissions]
}

resource "google_service_account_iam_member" "compute_sa_user" {
  # Grant Service Account User role to tf-rw for VM service account (the default one)
  count   = var.enable_vm_permissions ? 1 : 0
  service_account_id = data.google_compute_default_service_account.default[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.terraform_service_account}" 
  depends_on = [google_project_iam_member.vm_admin_permissions]
}

resource "google_project_iam_member" "cloudrun_admin" {
  # Grant Cloud Run Admin to tf-rw service account (required for Cloud Run service creation and management)
  count   = var.enable_cloudrun_permissions ? 1 : 0
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${var.terraform_service_account}" 
}

resource "google_service_account" "cloudrun_sa" {
  # If permissions are enabled, loop over every name in the list. Otherwise, loop over nothing. This creates a service account for each Cloud Run service.
  for_each = var.enable_cloudrun_permissions ? var.cloud_run_names : []
  
  project      = var.project_id
  account_id   = each.value # Use the Cloud Run service name as the service account name
  display_name = "Identity for Cloud Run Service: ${each.value}"

  depends_on = [google_project_iam_member.service_account_admin]
}

resource "google_service_account_iam_member" "cloudrun_sa_user" {
  # Grant Service Account User role to tf-rw for Cloud Run service accounts
  for_each           = google_service_account.cloudrun_sa
  
  service_account_id = each.value.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.terraform_service_account}"
  depends_on = [google_service_account.cloudrun_sa]
}

resource "google_project_iam_member" "cloudsql_admin" {
  # Grant Cloud SQL Admin to tf-rw service account (required for Cloud SQL instance creation and management)
  count   = var.enable_cloudsql_permissions ? 1 : 0
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${var.terraform_service_account}"
}

resource "google_project_iam_member" "cloudstorage_admin" {
  # Grant Cloud Storage Admin to tf-rw service account (required for Cloud Storage bucket creation and management)
  count   = var.enable_cloudstorage_permissions ? 1 : 0
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${var.terraform_service_account}"
}