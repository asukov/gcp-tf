variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "state_bucket" {
  description = "The TF state bucket"
  type        = string
}

variable "terraform_service_account" {
  description = "The service account to impersonate for Terraform operations"
  type        = string
}