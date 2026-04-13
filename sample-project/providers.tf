terraform {
  backend "gcs" {
    # Bucket name is provided via backend.conf during terraform init
    prefix = "terraform/fast_state"
    # Impersonate tf service account to access the state bucket
    impersonate_service_account = "asukov-tf-rw@boxwood-bee-484209-r9.iam.gserviceaccount.com"
  }
}

provider "google" {
  project                     = var.project_id
  impersonate_service_account = var.terraform_service_account
}

provider "google-beta" {
  project                     = var.project_id
  impersonate_service_account = var.terraform_service_account
}
