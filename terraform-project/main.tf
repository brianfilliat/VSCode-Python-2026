terraform {
  required_version = ">= 1.6.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
    Platform    = "wsl2-rhel9"
  }

  output_directory = "${path.module}/outputs"

  local_ceph_config_public = {
    dashboard_url = var.local_ceph_config.dashboard_url
    dashboard_ip  = var.local_ceph_config.dashboard_ip
    user          = var.local_ceph_config.user
    fsid          = var.local_ceph_config.fsid
    mon_ip        = var.local_ceph_config.mon_ip
    network       = var.local_ceph_config.network
  }
}

resource "random_pet" "server_name" {
  length    = 2
  separator = "-"
}

resource "random_password" "example_token" {
  length  = 20
  special = false
}

resource "local_file" "inventory" {
  filename = "${local.output_directory}/inventory.ini"

  content = templatefile("${path.module}/templates/inventory.tftpl", {
    hostname    = random_pet.server_name.id
    environment = var.environment
    owner       = var.owner
    mon_ip      = var.local_ceph_config.mon_ip
    network     = var.local_ceph_config.network
    fsid        = var.local_ceph_config.fsid
  })
}

resource "local_file" "ceph_dashboard_config" {
  filename = "${local.output_directory}/ceph-dashboard-config.json"
  content  = jsonencode(local.local_ceph_config_public)
}

resource "local_sensitive_file" "training_token" {
  filename        = "${local.output_directory}/training-token.txt"
  content         = random_password.example_token.result
  file_permission = "0600"
}

resource "local_sensitive_file" "ceph_dashboard_credentials" {
  filename        = "${local.output_directory}/ceph-dashboard-credentials.txt"
  content         = "user=${var.local_ceph_config.user}\npassword=${var.local_ceph_dashboard_password}\n"
  file_permission = "0600"
}

data "local_file" "inventory_preview" {
  filename   = local_file.inventory.filename
  depends_on = [local_file.inventory]
}
