variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "vpc_id" {
  type        = string
  description = "VPC id where DB will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for RDS subnet group"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional SG ids to attach (optional)"
  default     = []
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = ["10.0.0.0/8"]
}

variable "engine" {
  type    = string
  default = "aurora-postgresql"
}

variable "engine_version" {
  type    = string
  default = "13.6"
}

variable "database_name" {
  type    = string
  default = "appdb"
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type      = string
  sensitive = true
}

variable "create_secret" {
  type    = bool
  default = false
}

variable "secret_name" {
  type    = string
  default = null
}

variable "instance_class" {
  type    = string
  default = "db.r6g.large"
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_subnet_group_name" {
  type    = string
  default = null
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "apply_immediately" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "publicly_accessible" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
