locals {
  project_metadata = {
    project_name   = var.project_name
    environment    = var.environment
    sample_message = var.sample_message
  }
}

variable "project_name" {
  description = "Name used to identify this Terraform sample project."
  type        = string
  default     = "terraform-project"
}

variable "environment" {
  description = "Environment name for the sample resources."
  type        = string
  default     = "dev"
}

variable "sample_message" {
  description = "Message written to the sample output file."
  type        = string
  default     = "Hello from Terraform basic sample!"
}

resource "terraform_data" "project_settings" {
  input = local.project_metadata
}

resource "local_file" "basic_sample" {
  filename = "${path.module}/basic-sample-output.txt"
  content  = var.sample_message
}

resource "local_file" "project_metadata" {
  filename = "${path.module}/project-metadata.json"
  content  = jsonencode(terraform_data.project_settings.output)
}

output "sample_file_path" {
  description = "Path to the file created by this sample configuration."
  value       = local_file.basic_sample.filename
}

output "metadata_file_path" {
  description = "Path to the generated project metadata file."
  value       = local_file.project_metadata.filename
}

output "project_settings" {
  description = "Project settings captured by the terraform_data resource."
  value       = terraform_data.project_settings.output
}
