module "iam_permissions" {
  source = "../gcp-tf-templates/modules/iam"

  project_id                = var.project_id
  terraform_service_account = var.terraform_service_account

  enable_vm_permissions       = true
  enable_cloudrun_permissions = true
  enable_cloudsql_permissions = true
  cloud_run_name              = var.cloud_run_name
}

module "vm" {
  source       = "../cloud-foundation-fabric/modules/compute-vm"
  project_id   = var.project_id
  zone         = var.zone
  name         = var.instance_name
  machine_type = var.machine_type

  network_interfaces = [{
    network    = var.network
    subnetwork = var.subnetwork
    nat        = var.assign_external_ip
  }]

  boot_disk = {
    source = {
      image = "${var.boot_disk_image_project}/${var.boot_disk_image_family}"
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

module "cloud_run" {
  source     = "../cloud-foundation-fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = var.cloud_run_name
  region     = var.region

  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }

  iam = {
    "roles/run.invoker" = ["allUsers"]
  }

  deletion_protection = false

  service_account_config = {
    create = false
    email  = "${var.cloud_run_name}@${var.project_id}.iam.gserviceaccount.com"
  }

  depends_on = [module.iam_permissions]
}

module "db" {
  source     = "../cloud-foundation-fabric/modules/cloudsql-instance"
  project_id = var.project_id

  network_config = {
    connectivity = {
      psa_config = {
        private_network = "projects/${var.project_id}/global/networks/${var.network}"
      }
    }
  }

  name                          = var.cloud_sql_name
  region                        = var.region
  database_version              = var.cloud_sql_version
  tier                          = var.cloud_sql_tier
  gcp_deletion_protection       = false
  terraform_deletion_protection = false

  databases = ["test_db"]

  users = {
    user1 = {
      password = null # Let Cloud SQL generate a random password 
    }
  }

  depends_on = [module.iam_permissions]
}