variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary/DR AWS region for global DB replica"
  type        = string
  default     = "us-west-2"
}

variable "azs" {
  description = "List of AZs to use (length will create that many subnets)"
  type        = list(string)
  default     = ["us-east-1a","us-east-1b","us-east-1c"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "prefix" { type = string; default = "demo" }

variable "admin_cidr" { type = string; default = "10.0.0.0/8" }

variable "cluster_name" { type = string; default = "demo-eks" }
variable "cluster_version" { type = string; default = "1.26" }
variable "eks_node_count" { type = number; default = 2 }
variable "eks_node_instance_types" { type = list(string); default = ["t3.medium"] }

variable "db_cluster_identifier" { type = string; default = "demo-db" }
variable "db_engine" { type = string; default = "aurora-postgresql" }
variable "db_engine_version" { type = string; default = "13.14" }
variable "db_master_username" { type = string; default = "dbadmin" }
variable "db_master_password" { type = string; sensitive = true }
variable "db_instance_class" { type = string; default = "db.r6g.large" }
variable "db_instance_count" { type = number; default = 2 }
variable "db_backup_retention" { type = number; default = 7 }
variable "global_cluster_identifier" { type = string; default = "demo-global-db" }
