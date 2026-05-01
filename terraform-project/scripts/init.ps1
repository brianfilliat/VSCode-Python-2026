[CmdletBinding()]
param(
    [ValidateSet("dev", "stage", "prod")]
    [string]$Environment = "dev"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentPath = Join-Path $projectRoot "environments\$Environment"

Set-Location $environmentPath

terraform init
