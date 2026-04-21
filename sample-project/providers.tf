terraform {
  backend "gcs" {
    bucket = "tf_state_bucket_as88" 
    prefix = "terraform/fast_state"
  }
}

provider "google" {
  project                     = var.project_id
}

provider "google-beta" {
  project                     = var.project_id
}
