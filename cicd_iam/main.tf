# Create the Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.project_id # The project where your tf-rw service accounts live
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions deployments"
}

# Create the OIDC Provider for GitHub Actions
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider"
  display_name                       = "GitHub Actions OIDC Provider"

  oidc {
    # The standard Issuer URL for GitHub Actions
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Map the GitHub token claims to Google Cloud attributes
  # This tells GCP *who* is calling from GitHub.
  attribute_mapping = {
    "google.subject"        = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  attribute_condition = "attribute.repository_owner == 'asukov' && attribute.repository == 'asukov/gcp-tf'"
}

# Grant the GitHub Actions workflow permission to impersonate the Terraform service account
resource "google_service_account_iam_member" "allow_github_impersonation" {
  # The service account your pipeline needs to run as
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.terraform_service_account}"
  
  role   = "roles/iam.workloadIdentityUser"
  
  # IMPORTANT: Only allow a specific GitHub repository to impersonate!
  # This uses the attribute mapping defined above.
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/asukov/gcp-tf-projects"
}

