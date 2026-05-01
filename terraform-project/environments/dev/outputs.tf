output "metadata_file_path" {
  description = "Path to the generated metadata file."
  value       = module.project_files.metadata_file_path
}

output "sample_file_path" {
  description = "Path to the generated sample file."
  value       = module.project_files.sample_file_path
}

output "project_context" {
  description = "Normalized project context produced by the module."
  value       = module.project_files.project_context
}
