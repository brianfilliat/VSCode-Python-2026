# Terraform Project

Basic Terraform project configured with the HashiCorp `local` provider.

## Files

- `main.tf` configures Terraform and the local provider.
- `basic-sample.tf` defines variables, local values, Terraform resources, and outputs for the sample project.
- `basic-sample-output.txt` is created by `local_file.basic_sample`.
- `project-metadata.json` is created by `local_file.project_metadata` after `terraform apply`.
- `modules/` is for reusable Terraform modules.
- `providers/` is for provider-specific notes or future provider configuration.
- `scripts/` contains helper scripts for common Terraform commands.

## Common Commands

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

You can also run the helper scripts:

```powershell
.\scripts\init.ps1
.\scripts\validate.ps1
.\scripts\apply.ps1
```
