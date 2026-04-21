variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "terraform_service_account" {
  description = "The email of the deployer service account (e.g., tf-rw)."
  type        = string
}

variable "enable_vm_permissions" {
  description = "Set to true to grant VM creation and default SA usage permissions."
  type        = bool
  default     = false
}

variable "enable_cloudrun_permissions" {
  description = "Set to true to grant Cloud Run, SA Admin, and create the Run SA."
  type        = bool
  default     = false
}

variable "enable_cloudsql_permissions" {
  description = "Set to true to grant Cloud SQL Admin permissions."
  type        = bool
  default     = false
}

variable "enable_cloudstorage_permissions" {
  description = "Set to true to grant Cloud Storage Admin permissions."
  type        = bool
  default     = false
}

variable "cloud_run_names" {
  description = "A list of Cloud Run service names to create Service Accounts for. Required if enable_cloudrun_permissions is true."
  type        = set(string) 
  default     = []
}