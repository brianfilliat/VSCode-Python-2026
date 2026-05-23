output "project_name" {
  description = "Project label used for this Terraform training stack."
  value       = var.project_name
}

output "generated_hostname" {
  description = "Example generated hostname for training."
  value       = random_pet.server_name.id
}

output "inventory_file" {
  description = "Path to the generated inventory file."
  value       = local_file.inventory.filename
}

output "ceph_dashboard_config_file" {
  description = "Path to the generated Ceph dashboard config file."
  value       = local_file.ceph_dashboard_config.filename
}

output "ceph_dashboard_credentials_file" {
  description = "Path to the generated sensitive Ceph dashboard credentials file."
  value       = local_sensitive_file.ceph_dashboard_credentials.filename
  sensitive   = true
}

output "ceph_dashboard_url" {
  description = "Local Ceph dashboard URL."
  value       = var.local_ceph_config.dashboard_url
}

output "ceph_dashboard_ip_url" {
  description = "Local Ceph dashboard IP URL."
  value       = var.local_ceph_config.dashboard_ip
}

output "ceph_cluster_fsid" {
  description = "Local Ceph cluster FSID."
  value       = var.local_ceph_config.fsid
}

output "ceph_mon_ip" {
  description = "Local Ceph monitor IP."
  value       = var.local_ceph_config.mon_ip
}

output "ceph_network" {
  description = "Local Ceph network CIDR."
  value       = var.local_ceph_config.network
}

output "inventory_preview" {
  description = "Rendered inventory content."
  value       = data.local_file.inventory_preview.content
}

output "training_token_file" {
  description = "Path to the sensitive token file."
  value       = local_sensitive_file.training_token.filename
  sensitive   = true
}
