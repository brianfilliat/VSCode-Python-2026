provider "aws" {
  region = var.aws_region
}

module "db" {
  source = "../../.."

  name_prefix      = "demo"
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids
  master_username  = var.master_username
  master_password  = var.master_password
  instance_count   = 1
  tags = {
    Environment = "dev"
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type      = string
  sensitive = true
}
