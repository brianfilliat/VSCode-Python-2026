# Terraform Command Reference

## Daily Commands

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
terraform destroy -var-file="terraform.tfvars"
```

## State Commands

```powershell
terraform state list
terraform state show <address>
terraform output
terraform output -json
```

## Troubleshooting Commands

```powershell
terraform providers
terraform version
terraform console
$env:TF_LOG = "DEBUG"
terraform plan
Remove-Item Env:\TF_LOG
```

## Script Shortcuts

```powershell
.\scripts\init.ps1 -Environment dev
.\scripts\validate.ps1 -Environment dev
.\scripts\plan.ps1 -Environment dev
.\scripts\apply.ps1 -Environment dev
.\scripts\destroy.ps1 -Environment dev
```
