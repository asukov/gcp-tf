variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default = "boxwood-bee-484209-r9"
}

variable "azure_devops_organization_id" {
  description = "The Azure DevOps organization ID (GUID). This is used to construct the OIDC issuer URL."
  type        = string
  default = "3457bf03-2bc6-4691-8798-2a2580c9eaf4"
}

variable "terraform_service_account" {
  description = "The service account to impersonate for Terraform operations"
  type        = string
  default = "asukov-tf-rw@boxwood-bee-484209-r9.iam.gserviceaccount.com"
}