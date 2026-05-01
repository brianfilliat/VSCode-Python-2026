project_name   = "terraform-training"
environment    = "prod"
owner          = "platform-training"
cost_center    = "learn-001"
sample_message = "Hello from the prod Terraform environment."

tags = {
  managed_by  = "terraform"
  environment = "prod"
  lesson      = "release-control"
}
