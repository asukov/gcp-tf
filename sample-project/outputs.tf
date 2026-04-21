output "infrastructure" {
  description = "Summary of all deployed infrastructure, grouped by type."
  
  # We build one large map, but only include keys that have data
  value = {
    # 1. Add VMs only if they exist
    vms = length(module.vm) > 0 ? {
      for name, instance in module.vm : name => {
        id         = instance.id
        private_ip = instance.internal_ip
        ssh_login  = instance.login_command
      }
    } : null

    # 2. Add Cloud Runs only if they exist
    cloud_runs = length(module.cloud_run) > 0 ? {
      for name, service in module.cloud_run : name => {
        uri = service.service_uri
      }
    } : null

    # 3. Add Databases only if they exist
    databases = length(module.db) > 0 ? {
      for name, db in module.db : name => {
        instance_name = db.name
        ip_address    = db.ip
      }
    } : null

    # 4. Add Buckets only if they exist
    buckets = length(module.gcs_bucket) > 0 ? {
      for name, bucket in module.gcs_bucket : name => {
        url = bucket.url
      }
    } : null
  }
}

# Keep passwords separate for security (and mark as sensitive)
output "database_passwords" {
  description = "Generated passwords for all Cloud SQL databases."
  # If no databases exist, this returns null
  value = length(module.db) > 0 ? {
    for name, db in module.db : name => db.user_passwords
  } : null
  sensitive = true
}