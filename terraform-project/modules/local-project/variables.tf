variable "project_name" {
  description = "Name used to identify the project."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "owner" {
  description = "Team or person responsible for this deployment."
  type        = string
}

variable "cost_center" {
  description = "Cost center or chargeback code."
  type        = string
}

variable "sample_message" {
  description = "Training message written to the local sample file."
  type        = string
}

variable "tags" {
  description = "Common metadata tags."
  type        = map(string)
  default     = {}
}
