# PowerShell Troubleshooting Guide
## Common Issues and Solutions

---

## 🔴 Error: "The term 'XXX' is not recognized..."

### Symptom
```
The term 'Get-VpnConnection' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

### Causes
1. Command doesn't exist in your PowerShell version
2. Module not loaded
3. Cmdlet name misspelled
4. Running wrong shell (CMD instead of PowerShell)

### Solutions
```powershell
# Check if command exists
Get-Command Get-VpnConnection

# List available commands matching pattern
Get-Command *VPN*

# Import module if needed
Import-Module VpnClient

# Check PowerShell version
$PSVersionTable.PSVersion

# List all loaded modules
Get-Module
```

---

## 🔴 Error: "Cannot process argument because the value is null"

### Symptom
```
Cannot process argument because the value of argument "property" is null.
```

### Causes
1. Variable is null
2. Command returned nothing
3. Missing null check before property access

### Solutions
```powershell
# ❌ WRONG - No null check
$vpn = Get-VpnConnection -Name "test" -ErrorAction SilentlyContinue
$status = $vpn.ConnectionStatus  # CRASH if null

# ✅ CORRECT - Check for null first
$vpn = Get-VpnConnection -Name "test" -ErrorAction SilentlyContinue
if ($null -eq $vpn) {
    Write-Host "VPN not found"
} else {
    $status = $vpn.ConnectionStatus
}

# ✅ ALTERNATIVE - Use null-conditional operator (PowerShell 7+)
$status = $vpn?.ConnectionStatus
```

---

## 🔴 Error: "Execution of scripts is disabled on this system"

### Symptom
```
File cannot be loaded because running scripts is disabled on this system.
```

### Cause
PowerShell execution policy is set to Restricted

### Solutions
```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user (RECOMMENDED)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Set policy for system (requires admin)
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine

# Bypass for single session
PowerShell.exe -ExecutionPolicy Bypass -File script.ps1
```

### Execution Policy Levels
- **Restricted**: No scripts allowed
- **AllSigned**: Only signed scripts
- **RemoteSigned**: Local scripts OK, downloaded must be signed (RECOMMENDED)
- **Unrestricted**: All scripts allowed (warning shown)
- **Bypass**: Nothing blocked, no warnings

---

## 🔴 Error: "Access is denied" / "Permission denied"

### Symptom
```
Access to the path 'C:\ProgramData\...' is denied.
```

### Causes
1. Not running as Administrator
2. File is read-only
3. File is locked by another process
4. Insufficient NTFS permissions

### Solutions
```powershell
# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Not running as administrator"
}

# Run PowerShell as admin
Start-Process powershell -Verb RunAs

# Check file attributes
Get-ItemProperty "C:\path\to\file.txt" | Select-Object Attributes

# Remove read-only flag
Set-ItemProperty "C:\path\to\file.txt" -Name IsReadOnly -Value $false

# Check what process has file locked
Get-Process | Where-Object {$_.Modules.FileName -like "*yourfile*"}
```

---

## 🔴 Variables Not Expanding in Strings

### Symptom
```powershell
$name = "John"
Write-Host 'Hello $name'  # Output: Hello $name (not "Hello John")
```

### Cause
Using single quotes instead of double quotes

### Solution
```powershell
# Single quotes - LITERAL (no expansion)
$name = "John"
Write-Host 'Hello $name'        # Output: Hello $name

# Double quotes - EXPANSION (variables evaluated)
$name = "John"
Write-Host "Hello $name"        # Output: Hello John

# Escape $ in double quotes if needed
Write-Host "Price is `$100"     # Output: Price is $100

# For complex expressions
$greeting = "Hello $(Get-Date -Format 'HH:mm')"
```

---

## 🔴 Error: "A positional parameter cannot be found..."

### Symptom
```
A positional parameter cannot be found that accepts argument 'XXX'.
```

### Causes
1. Wrong parameter order
2. Missing parameter name
3. Extra arguments provided

### Solutions
```powershell
# ❌ WRONG - Positional arguments in wrong order
Get-VpnConnection "atlanta.hideservers.net" -AllUserConnection

# ✅ CORRECT - Named parameters
Get-VpnConnection -Name "atlanta.hideservers.net" -AllUserConnection

# Check command syntax
Get-Help Get-VpnConnection -Full
Get-Help Get-VpnConnection -Examples
```

---

## 🔴 Script Hangs / Runs Forever

### Symptoms
- Script doesn't respond
- Can't close terminal
- CPU at 100%
- No output

### Causes & Solutions

#### 1. Infinite Loop Without Sleep
```powershell
# ❌ BAD - Consumes 100% CPU
while ($true) {
    # Work
}

# ✅ GOOD - Adds delay
while ($true) {
    # Work
    Start-Sleep -Seconds 1
}
```

#### 2. Waiting for Input
```powershell
# ❌ Hangs waiting for user input
$input = Read-Host "Enter value"

# ✅ Timeout or default value
$timeout = 10
$input = Read-Host "Enter value (timeout in $timeout seconds)"
# Better: Don't prompt in background scripts
```

#### 3. Process Not Completing
```powershell
# ❌ Process hangs
Start-Process app.exe -Wait

# ✅ Add timeout
$process = Start-Process app.exe -PassThru
if (-not $process.WaitForExit(30000)) {  # 30 second timeout
    $process.Kill()
}
```

---

## 🔴 Error Windows Keep Appearing

### Cause
Errors not suppressed in background script

### Solutions
```powershell
# Suppress cmdlet errors
Get-VpnConnection -Name "test" -ErrorAction SilentlyContinue

# Redirect external program output
& program.exe 2>&1 | Out-Null

# Redirect to files for debugging
& program.exe > "$env:TEMP\out.txt" 2> "$env:TEMP\err.txt"

# Use Start-Process with redirection
Start-Process -FilePath "app.exe" `
              -NoNewWindow `
              -Wait `
              -RedirectStandardOutput "$env:TEMP\out.txt" `
              -RedirectStandardError "$env:TEMP\err.txt"

# Hide PowerShell window (for .ps1 run as scheduled task)
# Use PowerShell with -WindowStyle Hidden parameter
PowerShell.exe -WindowStyle Hidden -File script.ps1
```

---

## 🔴 Password Not Working

### Common Issues

#### 1. Variable Expansion
```powershell
# ❌ WRONG - $ treated as variable prefix
$password = "$ecureP@ss"  # Becomes empty if $ecureP doesn't exist

# ✅ CORRECT - Literal string
$password = '$ecureP@ss'  # Or escape: "`$ecureP@ss"
```

#### 2. Special Characters
```powershell
# Issues with these characters in passwords: $ ` " ' 

# Best practice: Use single quotes
$password = 'P@$$w0rd!#'

# If must use double quotes, escape special chars
$password = "P@`$`$w0rd!#"
```

#### 3. SecureString Required
```powershell
# Some cmdlets require SecureString
$password = 'MyPassword'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("username", $securePassword)
```

---

## 🔴 VPN Won't Connect

### Troubleshooting Steps

#### 1. Check VPN Exists
```powershell
Get-VpnConnection -Name "atlanta.hideservers.net"
```

#### 2. Test Manual Connection
```powershell
rasdial "atlanta.hideservers.net" username password
```

#### 3. Check VPN Configuration
```powershell
Get-VpnConnection -Name "atlanta.hideservers.net" | Format-List *
```

#### 4. View Connection Errors
```powershell
# Check System event log
Get-EventLog -LogName System -Source RasClient -Newest 10

# Or in PowerShell 7+
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='RasClient'} -MaxEvents 10
```

#### 5. Common VPN Error Codes
- **Error 691**: Wrong username/password
- **Error 789**: L2TP connection attempt failed (firewall/NAT issue)
- **Error 806**: Connection between computer and VPN server could not be established
- **Error 809**: Network connection interrupted (common with L2TP behind NAT)

#### 6. L2TP Behind NAT Fix
```powershell
# Required registry setting for L2TP/IPsec behind NAT
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent" `
                 -Name "AssumeUDPEncapsulationContextOnSendRule" `
                 -Value 2 `
                 -PropertyType DWORD `
                 -Force

# Restart IPsec service
Restart-Service PolicyAgent
```

---

## 🔴 Script Works Manually But Not on Startup

### Causes & Solutions

#### 1. Execution Policy
```powershell
# Set for all users (requires admin)
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
```

#### 2. Path Issues
```powershell
# ❌ Relative paths won't work from Startup folder
.\config.txt

# ✅ Use absolute paths or PSScriptRoot
$scriptDir = Split-Path -Parent $PSCommandPath
$configPath = Join-Path $scriptDir "config.txt"

# ✅ Use environment variables
$configPath = "$env:PROGRAMDATA\MyApp\config.txt"
```

#### 3. User Context
Startup folder scripts run as different user:
- `C:\ProgramData\Microsoft\...\Startup\` - Runs as SYSTEM
- `C:\Users\Username\AppData\...\Startup\` - Runs as that user

```powershell
# Check who's running the script
Write-Host "Running as: $env:USERNAME"
Write-Host "User Domain: $env:USERDOMAIN"
```

#### 4. Dependencies Not Loaded
```powershell
# Add explicit module loading
Import-Module VpnClient -ErrorAction SilentlyContinue

# Add PATH if needed
$env:PATH += ";C:\Program Files\MyApp\bin"
```

---

## 🔴 Performance Issues / Slow Script

### Solutions

#### 1. Avoid Repeated Calls
```powershell
# ❌ SLOW - Calls Get-Process 1000 times
foreach ($i in 1..1000) {
    $proc = Get-Process | Where-Object {$_.Id -eq $i}
}

# ✅ FAST - Call once, filter in memory
$allProcs = Get-Process
foreach ($i in 1..1000) {
    $proc = $allProcs | Where-Object {$_.Id -eq $i}
}
```

#### 2. Use -Filter Instead of Where-Object
```powershell
# ❌ SLOW - Retrieves all, then filters
Get-ChildItem C:\ -Recurse | Where-Object {$_.Extension -eq '.txt'}

# ✅ FAST - Filters during retrieval
Get-ChildItem C:\ -Recurse -Filter *.txt
```

#### 3. ForEach-Object vs foreach
```powershell
# SLOW - Pipeline overhead
1..1000 | ForEach-Object { $_ * 2 }

# FAST - Native loop
foreach ($i in 1..1000) { $i * 2 }
```

#### 4. Measure Performance
```powershell
Measure-Command {
    # Your code here
}
```

---

## 🔴 Debugging Techniques

### Enable Verbose Output
```powershell
$VerbosePreference = "Continue"
# Your script
$VerbosePreference = "SilentlyContinue"
```

### Enable Debug Output
```powershell
$DebugPreference = "Continue"
# Your script
$DebugPreference = "SilentlyContinue"
```

### Trace Script Execution
```powershell
Set-PSDebug -Trace 1  # Show each line before executing
# Your script
Set-PSDebug -Off
```

### Add Breakpoints (PowerShell ISE or VS Code)
```powershell
# In your script
Set-PSBreakpoint -Script .\script.ps1 -Line 10
```

### Log to File
```powershell
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -Append -FilePath "$env:TEMP\script.log"
}

Write-Log "Script started"
# Your code
Write-Log "Script completed"
```

### Check Last Error
```powershell
# View last error
$Error[0]

# View full error details
$Error[0] | Format-List * -Force

# View all recent errors
$Error | Select-Object -First 5

# Clear error history
$Error.Clear()
```

---

## 🔴 Common Syntax Errors

### Missing Closing Bracket
```powershell
# ❌ ERROR
if ($true) {
    Write-Host "Test"
# Missing }

# ✅ CORRECT
if ($true) {
    Write-Host "Test"
}
```

### Wrong Quote Matching
```powershell
# ❌ ERROR
Write-Host "Hello World'  # Mismatched quotes

# ✅ CORRECT
Write-Host "Hello World"
```

### Incorrect Variable Names
```powershell
# ❌ ERROR - Variables must start with $
myVariable = "value"

# ✅ CORRECT
$myVariable = "value"
```

### Missing Commas in Arrays
```powershell
# ❌ ERROR
$array = @("one" "two" "three")

# ✅ CORRECT
$array = @("one", "two", "three")
# Or let PowerShell infer:
$array = "one", "two", "three"
```

---

## 🛠️ Useful Diagnostic Commands

```powershell
# System Information
Get-ComputerInfo
$PSVersionTable

# Check PowerShell version
$PSVersionTable.PSVersion

# List all available commands
Get-Command

# Get help for command
Get-Help Get-VpnConnection -Full
Get-Help Get-VpnConnection -Examples

# List all variables
Get-Variable

# List all modules
Get-Module -ListAvailable

# Check process
Get-Process | Where-Object {$_.Name -like "*powershell*"}

# View environment variables
Get-ChildItem Env:
$env:PATH

# Test network connectivity
Test-NetConnection -ComputerName atlanta.hideservers.net -Port 1701

# Check running services
Get-Service | Where-Object {$_.Status -eq "Running"}

# View event logs
Get-EventLog -LogName Application -Newest 10
```

---

## 📞 When All Else Fails

1. **Read the error message carefully** - it usually tells you what's wrong
2. **Google the exact error message** - someone has likely solved it
3. **Check PowerShell version compatibility** - some cmdlets are version-specific
4. **Test in PowerShell ISE** - better error messages and debugging
5. **Break script into smaller parts** - test each part separately
6. **Add logging** - see exactly where script fails
7. **Check permissions** - many issues are permission-related
8. **Restart PowerShell** - clear any stuck states
9. **Review recent Windows updates** - updates can change behavior
10. **Ask for help** - provide error message, PS version, and code snippet

---

**Last Updated:** February 7, 2026  
**Purpose:** Quick troubleshooting reference for common PowerShell issues
