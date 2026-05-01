output "metadata_file_path" {
  description = "Path to the generated metadata file."
  value       = local_file.metadata.filename
}

output "sample_file_path" {
  description = "Path to the generated sample file."
  value       = local_file.sample.filename
}

output "project_context" {
  description = "Normalized project context."
  value       = terraform_data.project_context.output
}
