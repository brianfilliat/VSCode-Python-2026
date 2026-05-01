variable "project_name" {
  description = "Name used to identify the training project."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

variable "owner" {
  description = "Team or person responsible for the environment."
  type        = string
}

variable "cost_center" {
  description = "Cost center or chargeback code used for tagging."
  type        = string
}

variable "sample_message" {
  description = "Message written to the generated sample file."
  type        = string
}

variable "tags" {
  description = "Common metadata tags used by the module."
  type        = map(string)
  default     = {}
}
