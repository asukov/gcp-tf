variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "terraform_service_account" {
  description = "The service account to impersonate for Terraform operations"
  type        = string
}

variable "instance_name" {
  description = "The name of the GCE instance"
  type        = string
  default     = "minimal-linux-vm"
}

variable "machine_type" {
  description = "The machine type for the instance (e2-micro is cheapest)"
  type        = string
  default     = "e2-micro"
}

variable "windows_instance_name" {
  description = "The name of the Windows VM"
  type        = string
  default     = "minimal-windows-vm"
}

variable "windows_machine_type" {
  description = "The machine type for Windows (e2-medium is recommended minimum)"
  type        = string
  default     = "e2-medium"
}

variable "network" {
  description = "The VPC network for the VM. Use self link for Shared VPC if needed."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The VPC subnetwork for the VM. Use self link for Shared VPC if needed."
  type        = string
  default     = "default"
}

variable "assign_external_ip" {
  description = "Whether to assign an external IP to the VM."
  type        = bool
  default     = true
}

variable "boot_disk_image_project" {
  description = "The GCP image project for the VM boot disk."
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "boot_disk_image_family" {
  description = "The GCP image family for the VM boot disk."
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "cloud_run_name" {
  description = "The name of the Cloud Run service"
  type        = string
}

variable "cloud_sql_name" {
  description = "The name of the Cloud SQL instance"
  type        = string
}

variable "cloud_sql_tier" {
  description = "The tier for the Cloud Run service"
  type        = string
  default     = "db-g1-small"
}

variable "cloud_sql_version" {
  description = "The version for the Cloud SQL instance"
  type        = string
  default     = "MYSQL_8_0"
}