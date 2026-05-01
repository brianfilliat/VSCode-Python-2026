[CmdletBinding()]
param(
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment = "dev",

    [switch]$AutoApprove
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentPath = Join-Path $projectRoot "environments\$Environment"
$varFile = Join-Path $environmentPath "terraform.tfvars"

Set-Location $environmentPath

if ($AutoApprove) {
    terraform destroy -var-file="$varFile" -auto-approve
}
else {
    terraform destroy -var-file="$varFile"
}
