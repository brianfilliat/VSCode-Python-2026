# PowerShell Quick Reference Guide
## VPN Script Debugging - Key Lessons

---

## Critical Bugs Fixed

### 1. Password Variable Expansion ⚠️ CRITICAL
```powershell
# ❌ WRONG - Variable expansion (password becomes empty string)
$vpnpassword = "$Time9fly9denver"

# ✅ CORRECT - Literal string (preserves $ character)
$vpnpassword = 'Time9fly9denver'
```
**Rule:** Single quotes `'` = literal, Double quotes `"` = variable expansion

---

### 2. Security: Never Use Invoke-Expression 🔒
```powershell
# ❌ DANGEROUS - Code injection risk
$expression = "$cmd ""$vpnname"" $user $pass"
Invoke-Expression -Command $expression

# ✅ SAFE - Call operator
& $rasdialPath $vpnname $user $pass

# ✅ SAFE - Start-Process
Start-Process -FilePath $rasdialPath -ArgumentList $vpnname, $user, $pass
```

---

### 3. Error Handling
```powershell
# ❌ NO ERROR HANDLING
$vpn = Get-VpnConnection -Name "vpn"

# ✅ SILENT (for background scripts)
$vpn = Get-VpnConnection -Name "vpn" -ErrorAction SilentlyContinue

# ✅ WITH CATCH BLOCK
try {
    $vpn = Get-VpnConnection -Name "vpn" -ErrorAction Stop
} catch {
    # Handle error
}
```

---

### 4. Null Checking
```powershell
# ❌ CRASH if $vpn is null
if ($vpn.Status -eq "Connected") { }

# ✅ CHECK FIRST
if ($null -eq $vpn) {
    # Handle null
} elseif ($vpn.Status -eq "Connected") {
    # Handle connection
}
```

---

## ErrorAction Quick Reference

| Value | Behavior | Use Case |
|-------|----------|----------|
| `Stop` | Throws terminating error | With try-catch |
| `Continue` | Shows error, continues (default) | Interactive scripts |
| `SilentlyContinue` | Suppresses error, continues | Background/silent scripts |
| `Ignore` | Completely ignores error | When error is expected |

---

## String Quoting Cheat Sheet

```powershell
# Single Quotes - LITERAL (no expansion)
'$variable'           # Result: $variable
'C:\Path\$file.txt'   # Result: C:\Path\$file.txt
'Price: $100'         # Result: Price: $100

# Double Quotes - EXPANSION (variables evaluated)
"$variable"           # Result: (value of $variable)
"Path: $env:TEMP"     # Result: Path: C:\Users\...\Temp
"Price: $price"       # Result: Price: 19.99

# Escape Characters in Double Quotes
"Price: `$100"        # Result: Price: $100 (backtick escapes $)
```

---

## Admin Privilege Check

```powershell
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    # Admin-only operations
}
```

---

## Path Construction

```powershell
# Simple (Windows only)
$path = "$env:WINDIR\System32\rasdial.exe"

# Best Practice (cross-platform)
$path = Join-Path $env:WINDIR "System32\rasdial.exe"
```

---

## Silent Script Execution

```powershell
# Suppress all output
& command 2>&1 | Out-Null

# Redirect to files
Start-Process -FilePath "app.exe" `
              -NoNewWindow `
              -Wait `
              -RedirectStandardOutput "$env:TEMP\out.txt" `
              -RedirectStandardError "$env:TEMP\err.txt"
```

---

## VPN Connection Management

### Create VPN Connection
```powershell
Add-VpnConnection -Name "vpn.server.com" `
                  -ServerAddress "vpn.server.com" `
                  -TunnelType L2tp `
                  -EncryptionLevel Required `
                  -AuthenticationMethod MSChapv2 `
                  -L2tpPsk 'PreSharedKey' `
                  -AllUserConnection `
                  -RememberCredential
```

### Check VPN Status
```powershell
Get-VpnConnection -Name "vpn.server.com"
```

### Connect with Rasdial
```powershell
rasdial "vpn.server.com" username password
```

### Disconnect
```powershell
rasdial "vpn.server.com" /disconnect
```

---

## Common Patterns

### Infinite Loop with Sleep
```powershell
while ($true) {
    # Do work
    Start-Sleep -Seconds 30
}
```

### Loop with Exit Condition
```powershell
$running = $true
while ($running) {
    # Work
    if (Test-Path "$env:TEMP\stop.txt") {
        $running = $false
    }
    Start-Sleep -Seconds 30
}
```

---

## Debugging Commands

### Find Running PowerShell Scripts
```powershell
Get-Process powershell | Select-Object Id, CommandLine
```

### Kill Process
```powershell
Stop-Process -Id <ProcessID>
Stop-Process -Name "powershell" -Force
```

### Check Execution Policy
```powershell
Get-ExecutionPolicy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### View Event Logs
```powershell
Get-EventLog -LogName Application -Newest 10
Get-WinEvent -LogName System -MaxEvents 10
```

---

## File Locations

### Current Script Location
```powershell
$scriptPath = $PSCommandPath
$scriptDir = Split-Path $PSCommandPath
```

### Common Paths
```powershell
$env:USERPROFILE                    # C:\Users\Username
$env:APPDATA                        # C:\Users\Username\AppData\Roaming
$env:LOCALAPPDATA                   # C:\Users\Username\AppData\Local
$env:PROGRAMDATA                    # C:\ProgramData
$env:TEMP                           # C:\Users\Username\AppData\Local\Temp
$env:WINDIR                         # C:\Windows
```

### Startup Folder
```powershell
# All Users (requires admin to modify)
C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\

# Current User
$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\
```

---

## Testing Checklist

- [ ] Script runs without errors
- [ ] No windows/popups appear
- [ ] Handles null values
- [ ] Error messages suppressed
- [ ] Works without admin (after setup)
- [ ] Survives system reboot
- [ ] Credentials work correctly
- [ ] Reconnects after disconnect

---

## Common Mistakes to Avoid

1. ❌ Using `"$password"` instead of `'$password'`
2. ❌ Using `Invoke-Expression` for command execution
3. ❌ Not checking for null before accessing properties
4. ❌ Not suppressing errors in background scripts
5. ❌ Forgetting `-ErrorAction SilentlyContinue`
6. ❌ Not testing as non-admin user
7. ❌ Hardcoding paths instead of using environment variables
8. ❌ Not redirecting output in background processes

---

## One-Liners

```powershell
# Check if VPN connected
(Get-VpnConnection -Name "vpn.server.com").ConnectionStatus

# Connect VPN
rasdial "vpn.server.com" username password

# Disconnect VPN
rasdial "vpn.server.com" /disconnect

# Test if running as admin
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Kill all PowerShell processes
Get-Process powershell | Stop-Process -Force

# Find process by command line
Get-Process | Where-Object {$_.CommandLine -like "*autovpn*"}
```

---

## Resources

- [About Quoting Rules](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_quoting_rules)
- [About Operators](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_operators)
- [Error Handling](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_try_catch_finally)
- [Script Security](https://docs.microsoft.com/powershell/scripting/learn/security-features)

---

**Last Updated:** February 7, 2026
