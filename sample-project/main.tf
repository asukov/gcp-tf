locals {
  # 1. Read the YAML file and parse it into a Terraform map
  #config = yamldecode(file("${path.module}/config.yaml"))
  config_file_content = file("${path.module}/config.yaml")
  config = try(yamldecode(local.config_file_content), {})

}

# ==========================================
# IAM MODULE
# ==========================================
module "iam_permissions" {
  source = "../gcp-tf-templates/modules/iam"

  project_id                = var.project_id
  terraform_service_account = var.terraform_service_account

  # Evaluate to TRUE if the resource blocks exist and are not empty
  enable_vm_permissions       = length(try(local.config.vms, {})) > 0
  enable_cloudrun_permissions = length(try(local.config.cloud_runs, {})) > 0
  enable_cloudsql_permissions = length(try(local.config.databases, {})) > 0
  enable_cloudstorage_permissions = length(try(local.config.storage_buckets, {})) > 0
  
  # Pass the list of Cloud Run names for the Service Account creation
  cloud_run_names = try(keys(local.config.cloud_runs), [])
}

# ==========================================
# VM MODULE(S)
# ==========================================
module "vm" {
  source       = "../cloud-foundation-fabric/modules/compute-vm"
  
  # 2. Loop over the 'vms' dictionary in the YAML. 
  # If it doesn't exist, use an empty map {} so it safely skips.
  for_each     = try(local.config.vms, {})

  project_id   = var.project_id
  
  # 3. Access values using each.key (the name) and each.value (the properties)
  name         = each.key 
  zone         = each.value.zone
  machine_type = each.value.machine_type

  network_interfaces = [{
    network    = each.value.network
    subnetwork = each.value.subnetwork
    nat        = try(each.value.assign_external_ip, false)
  }]

  boot_disk = {
    source = {
      image = "${each.value.boot_disk_image_project}/${each.value.boot_disk_image_family}"
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive
    while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done
    sudo apt-get update
    sudo apt-get install -y mysql-client-core-8.0
  EOT

  depends_on = [module.iam_permissions]
}

# ==========================================
# CLOUD RUN MODULE(S)
# ==========================================
module "cloud_run" {
  source     = "../cloud-foundation-fabric/modules/cloud-run-v2"
  
  for_each   = try(local.config.cloud_runs, {})

  project_id = var.project_id
  name       = each.key
  region     = each.value.region

  containers = {
    hello = {
      image = each.value.image
    }
  }

  iam = {
    "roles/run.invoker" = ["allUsers"]
  }

  deletion_protection = false

  service_account_config = {
    create = false
    email  = "${each.key}@${var.project_id}.iam.gserviceaccount.com"
  }

  depends_on = [module.iam_permissions]
}

# ==========================================
# CLOUD SQL MODULE(S)
# ==========================================
module "db" {
  source     = "../cloud-foundation-fabric/modules/cloudsql-instance"
  
  for_each   = try(local.config.databases, {})

  project_id = var.project_id
  name       = each.key
  region     = each.value.region
  
  network_config = {
    connectivity = {
      psa_config = {
        private_network = "projects/${var.project_id}/global/networks/${each.value.network}"
      }
    }
  }

  database_version              = each.value.database_version
  tier                          = each.value.tier
  gcp_deletion_protection       = false
  terraform_deletion_protection = false

  databases = ["test_db"]

  users = {
    user1 = { password = null } # Let the module generate a random password
  }

  depends_on = [module.iam_permissions]
}


module "gcs_bucket" {
  source     = "../cloud-foundation-fabric/modules/gcs"
  
  for_each   = try(local.config.storage_buckets, {})

  project_id = var.project_id
  name       = each.key
  location   = each.value.location
  storage_class               = try(each.value.storage_class, "STANDARD")
  versioning                  = try(each.value.versioning, true)
  uniform_bucket_level_access = try(each.value.uniform_bucket_level_access, true)
  force_destroy               = try (each.value.force_destroy, false)
  public_access_prevention    = try(each.value.public_access, false) ? "inherited" : "enforced"
  iam                         = try(each.value.public_access, false) ? {
                                  "roles/storage.objectViewer" = ["allUsers"]
                                } : {}

  depends_on = [module.iam_permissions]
}