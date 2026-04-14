# ==========================================
# VM OUTPUTS
# ==========================================
output "vms" {
  description = "Details of all deployed Virtual Machines."
  value = {
    for name, instance in module.vm : name => {
      id            = instance.id
      private_ip    = instance.internal_ip
      ssh_login     = instance.login_command
    }
  }
}

# ==========================================
# CLOUD RUN OUTPUTS
# ==========================================
output "cloud_runs" {
  description = "URIs of all deployed Cloud Run services."
  value = {
    for name, service in module.cloud_run : name => {
      uri = service.service_uri
    }
  }
}

# ==========================================
# CLOUD SQL OUTPUTS
# ==========================================
output "databases" {
  description = "Connection details for all Cloud SQL instances."
  value = {
    for name, db in module.db : name => {
      instance_name = db.name
      ip_address    = db.ip
    }
  }
}

output "database_passwords" {
  description = "Generated passwords for all Cloud SQL databases."
  value = {
    for name, db in module.db : name => db.user_passwords
  }
  sensitive = true # Keeps all passwords hidden in the console
}