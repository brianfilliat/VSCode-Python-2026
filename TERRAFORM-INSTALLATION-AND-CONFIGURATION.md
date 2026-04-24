# Terraform Installation and Configuration Guide

## Overview
This guide documents how to install Terraform on Windows, verify the installation, and configure a basic Terraform workflow.

## Prerequisites
- Windows 10/11 or Windows Server with PowerShell available.
- `winget` installed and configured.
- Administrative or user permissions to update the PATH environment variable.

## 1. Verify whether Terraform is already installed
Open PowerShell and run:

```powershell
terraform version
```

If Terraform is not installed, you will see an error similar to:

```text
The term 'terraform' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

## 2. Install Terraform using winget
Use the Windows Package Manager to install the official HashiCorp release.

```powershell
winget install -e --id Hashicorp.Terraform --accept-package-agreements --accept-source-agreements
```

If the package is not immediately found, first search for the available Terraform package:

```powershell
winget search terraform
```

Look for `Hashicorp.Terraform` and install the matching package.

## 3. Confirm the installation
After installation, verify Terraform is available:

```powershell
terraform version
```

A successful install should print a Terraform version like:

```text
Terraform v1.14.9
on windows_amd64
```

## 4. Fix PATH issues if Terraform is not found
If `terraform version` still fails after installation, the executable may be installed in a WinGet package folder that is not currently on the PATH.

### Locate the Terraform executable
Search for `terraform.exe` in WinGet package storage:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter terraform.exe -Recurse -ErrorAction SilentlyContinue | Select-Object FullName
```

A typical path might look like:

```text
C:\Users\<username>\AppData\Local\Microsoft\WinGet\Packages\Hashicorp.Terraform_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform.exe
```

### Add the executable folder to user PATH
Add the package folder to your user PATH so PowerShell can find `terraform.exe`.

```powershell
$packagePath = 'C:\Users\<username>\AppData\Local\Microsoft\WinGet\Packages'
$userPath = [Environment]::GetEnvironmentVariable('PATH','User')
if (-not ($userPath -split ';' | Where-Object { $_ -eq $packagePath })) {
  [Environment]::SetEnvironmentVariable('PATH', "$userPath;$packagePath", 'User')
}
```

Then restart PowerShell and run:

```powershell
terraform version
```

## 5. Optional manual install location
If PATH issues persist, copy `terraform.exe` into a folder already on PATH, such as `C:\Users\<username>\AppData\Local\Programs`.

```powershell
Copy-Item -Path "C:\Users\<username>\AppData\Local\Microsoft\WinGet\Packages\...\terraform.exe" -Destination "C:\Users\<username>\AppData\Local\Programs\terraform.exe" -Force
```

Then verify it again:

```powershell
where.exe terraform
terraform version
```

## 6. Configure a Terraform workspace
1. Create a project directory:

```powershell
mkdir terraform-project
cd terraform-project
```

2. Add a simple `main.tf` file:

```hcl
terraform {
  required_version = ">= 1.0"
}

provider "local" {}
```

3. Initialize the Terraform working directory:

```powershell
terraform init
```

4. Create a plan and apply it:

```powershell
terraform plan
terraform apply
```

## 7. Recommended VS Code setup
For a better Terraform editing experience, install the official Terraform extension in Visual Studio Code:
- `HashiCorp Terraform`

This adds syntax highlighting, validation, formatting, and IntelliSense for `.tf` files.

## 8. Troubleshooting
- If `terraform` is not recognized, restart your shell or Windows terminal after updating PATH.
- Use `where.exe terraform` to confirm the resolved executable path.
- If multiple versions appear in PATH, remove or reorder old installations so the desired version is used.

## 9. Notes
- Terraform uses declarative configuration files, typically with `.tf` extension.
- Always run `terraform init` in a new project directory before using `terraform plan` or `terraform apply`.
- Keep your Terraform binary up to date by reinstalling or upgrading via `winget`.
