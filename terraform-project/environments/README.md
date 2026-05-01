# Environments Layer

Each folder in this layer is a Terraform root module. Run Terraform commands from one environment at a time.

## Environments

- `dev`: fast feedback and training experiments
- `stage`: pre-production validation pattern
- `prod`: production-style values and approval discussion

## Files in Each Environment

- `providers.tf`: Terraform and provider requirements
- `main.tf`: module calls
- `variables.tf`: typed input contracts
- `terraform.tfvars`: environment-specific values
- `outputs.tf`: values shown after apply

## Rule of Thumb

Environments decide what values to use. Modules decide what resources to create.
