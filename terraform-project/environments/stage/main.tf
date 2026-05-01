module "project_files" {
  source = "../../modules/local-project"

  project_name   = var.project_name
  environment    = var.environment
  owner          = var.owner
  cost_center    = var.cost_center
  sample_message = var.sample_message
  tags           = var.tags
}
