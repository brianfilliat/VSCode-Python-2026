# Terraform Training Guide

## Lesson 1: Understand the Layers

Open the folders in this order:

1. `environments/dev`
2. `modules/local-project`
3. `scripts`
4. `policies`

The environment passes values into the module. The module creates resources. Scripts run the workflow. Policies define guardrails.

## Lesson 2: Run Dev

```powershell
.\scripts\init.ps1 -Environment dev
.\scripts\validate.ps1 -Environment dev
.\scripts\plan.ps1 -Environment dev
.\scripts\apply.ps1 -Environment dev
```

After apply, inspect:

```powershell
Get-ChildItem .\outputs\dev
Get-Content .\outputs\dev\project-metadata.json
```

## Lesson 3: Compare Environments

Compare these files:

- `environments/dev/terraform.tfvars`
- `environments/stage/terraform.tfvars`
- `environments/prod/terraform.tfvars`

The Terraform code stays mostly the same. The environment values change.

## Lesson 4: Change a Variable

Edit `environments/dev/terraform.tfvars` and change `sample_message`.

Run:

```powershell
.\scripts\plan.ps1 -Environment dev
```

Terraform should show that the generated sample file will change.

## Lesson 5: Clean Up

```powershell
.\scripts\destroy.ps1 -Environment dev
```

## Review Questions

- What is the difference between an environment root module and a reusable module?
- Why should state be separated by environment?
- Why do we review `terraform plan` before `apply`?
- What kind of mistakes can policy-as-code catch?
