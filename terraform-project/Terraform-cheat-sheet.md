# Terraform Cheat Sheet

Terraform commands and project patterns for this layered training repo.

## Project Layers

| Layer | Folder | Purpose |
| --- | --- | --- |
| Environments | `environments/dev`, `environments/stage`, `environments/prod` | Deployable root modules |
| Modules | `modules/local-project` | Reusable infrastructure logic |
| Providers | `providers` | Provider and backend notes |
| Policies | `policies` | Policy-as-code guardrails |
| Scripts | `scripts` | Repeatable command wrappers |
| Docs | `docs` | Training and best-practice documentation |

## Training Workflow

```powershell
.\scripts\init.ps1 -Environment dev
.\scripts\validate.ps1 -Environment dev
.\scripts\plan.ps1 -Environment dev
.\scripts\apply.ps1 -Environment dev
.\scripts\destroy.ps1 -Environment dev
```

If PowerShell blocks local scripts, run with a temporary bypass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\init.ps1 -Environment dev
```

## Setup and Authentication

| Command | Purpose |
| --- | --- |
| `terraform version` | Show installed Terraform version |
| `terraform -install-autocomplete` | Enable shell tab completion |
| `aws configure` | Configure AWS credentials interactively |
| `$env:AWS_ACCESS_KEY_ID="xxx"` | Set AWS access key in PowerShell |
| `$env:AWS_SECRET_ACCESS_KEY="xxx"` | Set AWS secret key in PowerShell |
| `$env:AWS_DEFAULT_REGION="us-east-1"` | Set AWS default region in PowerShell |

## Core Workflow

| Command | Purpose |
| --- | --- |
| `terraform init` | Initialize a working directory |
| `terraform init -upgrade` | Upgrade providers and modules within version constraints |
| `terraform init -reconfigure` | Reinitialize backend configuration |
| `terraform fmt -recursive` | Format Terraform files |
| `terraform fmt -check -recursive` | Check formatting without changing files |
| `terraform validate` | Validate syntax and internal consistency |
| `terraform plan` | Preview changes |
| `terraform plan -out=tfplan` | Save a plan for later apply |
| `terraform apply` | Apply planned infrastructure changes |
| `terraform apply tfplan` | Apply a saved plan |
| `terraform destroy` | Destroy managed infrastructure |

## Variables and Outputs

| Command | Purpose |
| --- | --- |
| `terraform plan -var-file="terraform.tfvars"` | Use an environment variable file |
| `terraform apply -var="environment=dev"` | Pass one variable at the command line |
| `$env:TF_VAR_environment="dev"` | Set a Terraform variable from PowerShell |
| `terraform output` | Show outputs |
| `terraform output -json` | Show outputs as JSON |
| `terraform output -raw sample_file_path` | Show one output without quotes |

## State Management

| Command | Purpose |
| --- | --- |
| `terraform state list` | List resources in state |
| `terraform state show <address>` | Show one resource in state |
| `terraform state mv <old> <new>` | Rename a resource address in state |
| `terraform state rm <address>` | Remove a resource from state only |
| `terraform state pull` | Download remote state |
| `terraform force-unlock <lock_id>` | Release a stuck state lock |

## Modules

| Command | Purpose |
| --- | --- |
| `terraform get` | Download referenced modules |
| `terraform providers` | Show provider requirements by module |
| `terraform plan -target=module.project_files` | Plan only a module, usually for troubleshooting |

## Importing and Targeting

| Command | Purpose |
| --- | --- |
| `terraform import <address> <id>` | Import existing infrastructure into state |
| `terraform plan -target=<address>` | Plan one resource or module |
| `terraform apply -target=<address>` | Apply one resource or module |
| `terraform destroy -target=<address>` | Destroy one resource or module |

Use `-target` carefully. It is helpful for recovery, but it can hide dependencies during normal delivery.

## Debugging

| Command | Purpose |
| --- | --- |
| `$env:TF_LOG="DEBUG"` | Enable debug logs in PowerShell |
| `$env:TF_LOG_PATH="./terraform.log"` | Write logs to a file |
| `terraform console` | Test expressions interactively |
| `terraform graph` | Output dependency graph in DOT format |
| `terraform providers lock` | Create or update provider lock data |
| `Remove-Item Env:\TF_LOG` | Clear debug logging |

## Best Practices

- Separate state by environment.
- Keep reusable logic in modules.
- Review every plan before apply.
- Do not commit real secrets or state files.
- Pin provider and module versions.
- Use policy checks for required tags, encryption, approved regions, and public exposure.
