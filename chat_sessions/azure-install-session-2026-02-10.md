## Azure tools installation — session summary

- **Date:** 2026-02-10
- **Workspace:** VSCode-Python-2026
- **Purpose:** Record steps and commands used to install Azure CLI, Azure PowerShell module, Azure Storage Explorer, and Python SDK packages for training / reproducibility.

### Outcome

- Azure CLI installed (azure-cli 2.83.0)
- Az PowerShell module installed (Az 15.3.0)
- Azure Storage Explorer installed (1.41.0)
- Azure Python SDK packages installed into the repo virtualenv: `azure-identity`, `azure-mgmt-resource`, `azure-storage-blob`
- VS Code Azure extensions attempted via `code` CLI but encountered ICU errors; install via Extensions view if needed.

### Commands run (representative)

```powershell
# Install Azure CLI (winget)
winget install --id Microsoft.AzureCLI -e --accept-source-agreements --accept-package-agreements

# Install Az PowerShell module (current user)
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber

# Install Azure Storage Explorer (winget)
winget install --id Microsoft.Azure.StorageExplorer -e --accept-source-agreements --accept-package-agreements

# Install common Python SDK packages into project venv
& D:/DOCU-2026/Python-vscode-2026/.venv/Scripts/pip.exe install azure-identity azure-mgmt-resource azure-storage-blob

# Make az available in current session (temporary) and verify
$env:PATH += ';C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin'
az --version

# Persist az folder to User PATH (run once)
[Environment]::SetEnvironmentVariable('Path', ([Environment]::GetEnvironmentVariable('Path','User') + ';C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin'), 'User')

# Verify Az PowerShell module version
Get-InstalledModule -Name Az -AllVersions | Select-Object Name,Version

# Optional: login
az login
# or
Connect-AzAccount
```

### Notes & troubleshooting

- On first `az` run, `az` was present at `C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd` but not on the shell PATH. I added it to the User PATH and verified `az --version` in a new process.
- Attempting to install VS Code Azure extensions via `code --install-extension` produced ICU-related errors in this environment; installing from the VS Code Extensions view works around this issue.

### Verification snippets

- `az --version` output (excerpt):

```
azure-cli 2.83.0
core 2.83.0
```

- `Get-InstalledModule -Name Az` returned `Az 15.3.0`.

### Next steps (optional)

- Install VS Code Azure extensions from Extensions view or retry `code` CLI after ensuring VS Code is stable.
- Log in with `az login` or `Connect-AzAccount` and verify access to subscriptions.

### Sign-in & subscription (added during session)

- Signed in using device-code flow: `az login --use-device-code` (interactive browser/device code).
- Subscription discovered and set as default after sign-in:
	- **Name:** Azure subscription 1
	- **ID:** 01307d44-0fd6-4509-9863-03e308a2dbe9
	- **Tenant:** Default Directory
	- **State:** Enabled
	- **Default:** True

```text
Name                  CloudName    SubscriptionId                               TenantId                               State    IsDefault
Azure subscription 1  AzureCloud   01307d44-0fd6-4509-9863-03e308a2dbe9         3ace9875-8b74-4df3-ad62-7df0c2c6ba76    Enabled  True
```

- Notes: an initial `az account list` returned no subscriptions until interactive login completed; after authenticating the subscription became available and was selected as the default.

---

File created by automation on behalf of the user.
