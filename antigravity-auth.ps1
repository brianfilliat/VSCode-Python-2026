<#
.SYNOPSIS
Rotate Gemini/Antigravity auth state and remove old session data.
.DESCRIPTION
This script safely backs up the existing Gemini auth state, clears old Antigravity CLI session files, and sets HOME to USERPROFILE for Windows.
It is intended for use when switching Google accounts or rotating daily.
.PARAMETER Backup
Create a timestamped backup of the current .gemini auth state before deletion.
.PARAMETER Force
Skip the confirmation prompt.
.PARAMETER PersistHome
Persist HOME for future PowerShell sessions.
#>
[CmdletBinding()]
param(
    [switch]$Backup = $true,
    [switch]$Force,
    [switch]$PersistHome = $true
)

$ErrorActionPreference = 'Stop'

$geminiDir = Join-Path $env:USERPROFILE '.gemini'
if (-not (Test-Path -LiteralPath $geminiDir)) {
    Write-Error "Gemini directory not found at $geminiDir"
    exit 1
}

Write-Host "This will remove old Antigravity/Gemini auth state from:"
Write-Host "  $geminiDir"

if ($PersistHome) {
    $env:HOME = $env:USERPROFILE
    Write-Host "Setting HOME=$env:HOME for this session."
    try {
        setx HOME "$env:USERPROFILE" | Out-Null
        Write-Host "Persisted HOME for future PowerShell sessions."
    }
    catch {
        Write-Warning "Unable to persist HOME with setx. You can set it manually if needed."
    }
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
if ($Backup) {
    $backupTarget = Join-Path $env:USERPROFILE ".gemini-backup-$timestamp"
    Write-Host "Backing up current Gemini auth state to: $backupTarget"
    Copy-Item -LiteralPath $geminiDir -Destination $backupTarget -Recurse -Force
}

$targets = @(
    (Join-Path $geminiDir 'antigravity-cli\brain')
    (Join-Path $geminiDir 'antigravity')
    (Join-Path $geminiDir 'antigravity-ide')
    (Join-Path $geminiDir 'google_accounts.json')
    (Join-Path $geminiDir 'state.json')
)

foreach ($target in $targets) {
    if (Test-Path -LiteralPath $target) {
        try {
            Write-Host "Removing: $target"
            Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "Could not completely remove '$target'. Some files might be locked by an active process."
        }
    }
}

Write-Host ''
Write-Host 'Old Antigravity/Gemini auth state has been cleared.'
Write-Host 'Next steps:'
Write-Host '  1) Close and reopen PowerShell.'
Write-Host '  2) Sign in with the account you want to use.'
Write-Host '     Example accounts: edwardharris007@gmail.com, mikefilliat@gmail.com, brianfilliat@gmail.com'
Write-Host '  3) Run the Antigravity login flow:'
Write-Host '     & "C:\Users\Mikef\AppData\Local\agy\bin\agy.exe" --prompt-interactive --print-timeout 5m0s'
Write-Host '  4) Verify with:'
Write-Host '     & "C:\Users\Mikef\AppData\Local\agy\bin\agy.exe" --print "hello"'
Write-Host ''
 

Write-Host 'If you want a daily rotation, schedule this script with Windows Task Scheduler or run it manually each day.'

# -----------------------------------------------------------------------------
# Interactive authentication helper (documentation + simple UI)
# -----------------------------------------------------------------------------
# Documentation:
# - When the Antigravity CLI or other tool requires authentication, open the
#   URL below in your browser, sign in, and copy the authorization code.
# - Paste the code when prompted by this helper. The code will be saved to
#   `.gemini\antigravity\auth_code.txt` and can be used by downstream tools.
#
# Example URL (open in browser):
#  https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com&code_challenge=RyH8U8DQcl_4Rm2eoMQkNkXtj7f-WaU3vceOI2a5H74&code_challenge_method=S256&prompt=consent&redirect_uri=https%3A%2F%2Fantigravity.google%2Foauth-callback&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.profile+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcclog+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fexperimentsandconfigs+openid&state=B7BVHGeE4iA4Bu7sY3p6BA
#
# UI behavior:
# - Prompts to paste the authorization code.
# - Saves the code to `.gemini\antigravity\auth_code.txt`.
# - Displays a small window with a button labelled 'AUTHENTICATEd'. Clicking
#   the button closes the window and logs a confirmation message.
#
Write-Host ''
Write-Host 'Authentication required. Please visit the URL to log in:'
Write-Host '  https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com&code_challenge=RyH8U8DQcl_4Rm2eoMQkNkXtj7f-WaU3vceOI2a5H74&code_challenge_method=S256&prompt=consent&redirect_uri=https%3A%2F%2Fantigravity.google%2Foauth-callback&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.profile+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcclog+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fexperimentsandconfigs+openid&state=B7BVHGeE4iA4Bu7sY3p6BA'

$authCode = Read-Host 'PASTE the authorization code here and press Enter'
if ($authCode -and $authCode.Trim().Length -gt 0) {
    $authDir = Join-Path $geminiDir 'antigravity'
    if (-not (Test-Path -LiteralPath $authDir)) {
        New-Item -ItemType Directory -Path $authDir -Force | Out-Null
    }
    $tokenFile = Join-Path $authDir 'auth_code.txt'
    try {
        $authCode.Trim() | Out-File -FilePath $tokenFile -Encoding utf8 -Force
        Write-Host "Saved authorization code to: $tokenFile"
    }
    catch {
        Write-Warning "Failed to save authorization code: $_"
    }

    # Show a simple Windows Forms button labeled 'AUTHENTICATEd'
    try {
        Add-Type -AssemblyName System.Windows.Forms, System.Drawing
        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'Antigravity Authentication'
        $form.Size = New-Object System.Drawing.Size(360,140)
        $form.StartPosition = 'CenterScreen'

        $button = New-Object System.Windows.Forms.Button
        $button.Size = New-Object System.Drawing.Size(320,40)
        $button.Location = New-Object System.Drawing.Point(10,30)
        $button.Text = 'AUTHENTICATEd'
        $button.Font = New-Object System.Drawing.Font('Segoe UI',10)
        $button.Add_Click({ Write-Host 'AUTHENTICATION confirmed via UI button.'; $form.Close() })

        $form.Controls.Add($button)
        $form.Topmost = $true
        $null = $form.ShowDialog()
    }
    catch {
        Write-Warning "Unable to display UI: $_"
    }

    Write-Host 'Starting Antigravity CLI...'
    & "C:\Users\Mikef\AppData\Local\agy\bin\agy.exe" --prompt-interactive --print-timeout 5m0s
}
else {
    Write-Warning 'No authorization code pasted. Authentication not completed.'
}

