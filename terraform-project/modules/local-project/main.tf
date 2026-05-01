locals {
  project_context = {
    project_name = var.project_name
    environment  = var.environment
    owner        = var.owner
    cost_center  = var.cost_center
    tags         = var.tags
  }

  output_directory = abspath("${path.root}/../../outputs/${var.environment}")
}

resource "terraform_data" "project_context" {
  input = local.project_context
}

resource "local_file" "sample" {
  filename = "${local.output_directory}/sample-message.txt"
  content  = "${var.sample_message}\n"
}

resource "local_file" "metadata" {
  filename = "${local.output_directory}/project-metadata.json"
  content  = jsonencode(terraform_data.project_context.output)
}
