<#
run_install_helm_in_wsl.ps1
Detects a RHEL WSL2 distro and runs the Helm install script inside it.
Run from Windows PowerShell as your normal user (will prompt for sudo inside WSL).
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest

function Convert-WindowsPathToWsl {
    param([string]$windowsPath)
    $windowsPath = $windowsPath.Trim()
    if ($windowsPath -match '^([A-Za-z]):\\(.*)') {
        $drive = $matches[1].ToLower()
        $rest = $matches[2] -replace '\\','/'
        return "/mnt/$drive/$rest"
    }
    throw "Unsupported path format: $windowsPath"
}

# Find WSL distros
try {
    $names = (wsl -l --quiet 2>&1) -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
} catch {
    Write-Error "Failed to list WSL distros: $_"
    exit 2
}

# Prefer a distro with 'rhel' in the name (case-insensitive)
$distro = $names | Where-Object { $_ -match '(?i)rhel' } | Select-Object -First 1
if (-not $distro) {
    # fallback: use the default distro (first in list) if nothing matches
    $distro = $names | Select-Object -First 1
    Write-Host "No distro with 'rhel' found; falling back to: $distro"
} else {
    Write-Host "Using detected RHEL distro: $distro"
}

# Resolve the install script path (located next to this PowerShell helper)
$scriptPath = Join-Path $PSScriptRoot 'install_helm_rhel9_wsl.sh'
if (-not (Test-Path $scriptPath)) {
    Write-Error "Installer script not found at $scriptPath"
    exit 3
}

# Convert to WSL path and run inside the chosen distro
$wslPath = Convert-WindowsPathToWsl $scriptPath
Write-Host "Running installer at WSL path: $wslPath in distro: $distro"

# Run interactively so sudo can prompt for password if needed
$cmd = "bash -ic 'chmod +x \"$wslPath\" && sudo \"$wslPath\"'"

# Start the command
$proc = Start-Process -FilePath wsl -ArgumentList '-d', $distro, '--', $cmd -NoNewWindow -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Write-Error "Installer returned exit code $($proc.ExitCode)"
    exit $proc.ExitCode
}

Write-Host "Installer finished with exit code 0"
exit 0
