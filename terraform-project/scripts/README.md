# Scripts Layer

These PowerShell scripts provide repeatable Terraform workflows for training.

## Commands

```powershell
.\scripts\init.ps1 -Environment dev
.\scripts\validate.ps1 -Environment dev
.\scripts\plan.ps1 -Environment dev
.\scripts\apply.ps1 -Environment dev
.\scripts\destroy.ps1 -Environment dev
```

Valid environments are `dev`, `stage`, and `prod`.

## Why Scripts Help

- Everyone runs the same command pattern.
- Variable files are selected consistently.
- Training examples stay focused on Terraform behavior instead of typing paths.
- CI/CD can reuse the same workflow ideas.
