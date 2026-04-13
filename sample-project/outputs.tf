output "vm_name" {
  description = "Requested VM instance name."
  value       = var.instance_name
}

output "vm_id" {
  description = "Compute instance ID."
  value       = module.vm.id
}

output "vm_private_ip" {
  value = module.vm.internal_ip
}

output "vm_ssh_login" {
  value = module.vm.login_command
}

output "cloud_run_uri" {
  value = module.cloud_run.service_uri
}

output "cloud_sql_name" {
  value = module.db.name
}

output "cloud_sql_ip" {
  value = module.db.ip
}

output "cloud_sql_password" {
  value     = module.db.user_passwords
  sensitive = true
}