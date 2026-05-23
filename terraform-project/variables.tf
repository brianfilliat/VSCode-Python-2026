variable "project_name" {
  description = "Name used to label the local training resources."
  type        = string
  default     = "wsl2-rhel9-terraform-training"
}

variable "environment" {
  description = "Training environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "stage"], var.environment)
    error_message = "Environment must be one of: dev, test, stage."
  }
}

variable "owner" {
  description = "Person or team responsible for this training stack."
  type        = string
  default     = "sre-training"
}

variable "local_ceph_config" {
  description = "Local Ceph dashboard and monitor configuration for WSL2/RHEL9 training."
  type = object({
    dashboard_url = string
    dashboard_ip  = string
    user          = string
    fsid          = string
    mon_ip        = string
    network       = string
  })

  default = {
    dashboard_url = "https://ASUSVIVO2026.localdomain:8443/"
    dashboard_ip  = "https://172.21.204.100:8443/"
    user          = "admin"
    fsid          = "4f287b4e-4d74-11f1-aa0d-00155d49dc91"
    mon_ip        = "172.21.204.100"
    network       = "172.21.192.0/20"
  }
}

variable "local_ceph_dashboard_password" {
  description = "Local Ceph dashboard password for WSL2/RHEL9 training."
  type        = string
  sensitive   = true
  default     = "u20legmoz2"
}
