<#
.SYNOPSIS
    Run the Ceph OSD replacement Ansible playbook inside WSL from Windows.

.DESCRIPTION
    This wrapper copies the example inventory to `inventory` in the repo and invokes
    the Ansible playbook inside WSL. It assumes you have WSL with Ansible installed
    (or have an Ansible-enabled WSL distro). The script defaults to a dry-run; pass
    -Execute to perform the live replacement (requires setting `confirm_replace=true`).

.PARAMETER OsdId
    The numeric OSD id to replace (e.g. 3).

.PARAMETER ReplacementDevice
    The block device path to use for the replacement OSD on the replacement host (e.g. /dev/sdb).

.PARAMETER ReplacementHost
    The hostname where the replacement device will be provisioned.

.PARAMETER Execute
    Switch to perform the live replacement. When omitted the script runs a dry-run.

.EXAMPLE
    .\run_osd_replace_wsl.ps1 -OsdId 3 -ReplacementDevice /dev/sdb -ReplacementHost osd-host-3.example.com

.EXAMPLE (execute)
    .\run_osd_replace_wsl.ps1 -OsdId 3 -ReplacementDevice /dev/sdb -ReplacementHost osd-host-3.example.com -Execute
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OsdId,

    [Parameter(Mandatory=$true)]
    [string]$ReplacementDevice,

    [Parameter(Mandatory=$true)]
    [string]$ReplacementHost,

    [switch]$Execute
)

function Fail($msg) {
    Write-Error $msg
    exit 1
}

# Ensure WSL is available
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Fail "WSL not found. Install WSL and ensure it's in PATH."
}

$repoRoot = (Get-Location).Path
$inventoryExample = Join-Path $repoRoot 'outputs\ansible\inventory.example'
$inventoryTarget = Join-Path $repoRoot 'inventory'
$playbookWin = Join-Path $repoRoot 'outputs\ansible\osd_replace.yml'

if (-not (Test-Path $inventoryExample)) {
    Fail "Example inventory not found at $inventoryExample"
}

Copy-Item -Path $inventoryExample -Destination $inventoryTarget -Force
Write-Host "Copied inventory to $inventoryTarget"

# Convert Windows paths to WSL paths using wsl wslpath -a -u
function To-WslPath($winPath) {
    $out = & wsl wslpath -a -u "$winPath" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $out) {
        Fail "Failed to convert path to WSL path: $winPath"
    }
    return $out.Trim()
}

$wslInventory = To-WslPath $inventoryTarget
$wslPlaybook = To-WslPath $playbookWin

# Check ansible-playbook is available in WSL
$whichAnsible = & wsl which ansible-playbook 2>$null
if ($LASTEXITCODE -ne 0 -or -not $whichAnsible) {
    Write-Warning "ansible-playbook not found inside WSL. Ensure Ansible is installed in your WSL distro."
}

# Build extra-vars string
$extra = "osd_id=$OsdId replacement_device=$ReplacementDevice replacement_host=$ReplacementHost"
if ($Execute) {
    $extra += " dry_run=false confirm_replace=true"
    Write-Host "Execution mode: LIVE (dry_run=false, confirm_replace=true)"
} else {
    Write-Host "Execution mode: DRY-RUN (no changes will be made)"
}

# Construct and run the command in WSL
$bashCmd = "ansible-playbook -i '$wslInventory' '$wslPlaybook' -e '$extra'"
Write-Host "Running in WSL: $bashCmd"

# Execute
& wsl bash -lc $bashCmd
$rc = $LASTEXITCODE
if ($rc -ne 0) {
    Fail "Ansible playbook returned exit code $rc"
}

Write-Host "Playbook completed with exit code $rc"
