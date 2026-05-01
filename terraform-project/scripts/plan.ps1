[CmdletBinding()]
param(
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment = "dev",

    [string]$OutFile = "tfplan"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentPath = Join-Path $projectRoot "environments\$Environment"
$varFile = Join-Path $environmentPath "terraform.tfvars"

Set-Location $environmentPath

terraform plan -var-file="$varFile" -out="$OutFile"
