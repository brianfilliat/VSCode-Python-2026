# Terraform Training Project

This project is a layered Terraform training repo. It starts with a safe local-provider sample, then shows the same structure teams use for real cloud infrastructure:

- `environments/` contains deployable root modules for `dev`, `stage`, and `prod`.
- `modules/` contains reusable building blocks called by environments.
- `providers/` documents provider and backend ownership.
- `policies/` contains policy-as-code examples for guardrails.
- `scripts/` contains repeatable PowerShell workflows.
- `docs/` contains training notes, best practices, and architecture guidance.

The environment examples use the HashiCorp `local` provider so students can run Terraform without creating cloud resources or spending money.

## Project Structure

```text
terraform-project/
  environments/
    dev/
    stage/
    prod/
  modules/
    local-project/
  policies/
    opa/
    sentinel/
  providers/
  scripts/
  docs/
  outputs/
```

## Quick Start

Run a complete training workflow from the project root:

```powershell
.\scripts\init.ps1 -Environment dev
.\scripts\validate.ps1 -Environment dev
.\scripts\plan.ps1 -Environment dev
.\scripts\apply.ps1 -Environment dev
```

To clean up generated local files:

```powershell
.\scripts\destroy.ps1 -Environment dev
```

## Manual Workflow

```powershell
cd .\environments\dev
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Training Path

1. Read [docs/architecture.md](docs/architecture.md) to understand the layers.
2. Run `dev` with the scripts.
3. Compare `dev`, `stage`, and `prod` variable files.
4. Open [modules/local-project](modules/local-project) and trace inputs to outputs.
5. Review [docs/best-practices.md](docs/best-practices.md).
6. Review [policies/README.md](policies/README.md) to understand policy guardrails.

## Existing Root Sample

The root-level `main.tf` and `basic-sample.tf` are kept as a beginner-friendly single-folder example. The layered environment folders are the recommended structure for team training and future projects.
