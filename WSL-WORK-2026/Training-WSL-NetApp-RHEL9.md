# WSL Training: File Transfer and NetApp ONTAP Access on RHEL 9

## Overview

This training document is designed to make your workflow clearer and more user-friendly. It covers:

- Updating WSL/WSL2 documentation in a practical way
- Copying files from `filliat@ASUSVIVO2026:/home/filliat` to a remote server
- Accessing NetApp ONTAP CLI from RHEL 9
- Optionally installing NetApp Linux Host Utilities on RHEL 9 for local storage host management

---

## 1. Training Documentation Best Practices

Use a consistent format for all documentation:

- Start with a clear purpose and environment summary
- Include commands with examples
- Show expected output or validation steps
- Use tables for configuration values
- Add notes for common pitfalls and troubleshooting

Example sections to include in every training document:

- Purpose
- Prerequisites
- Steps
- Validation
- Troubleshooting

---

## 2. Copy All Files from WSL Home to a Remote Server

If you want to copy everything from `filliat@ASUSVIVO2026:/home/filliat` to another server, use `rsync` or `scp` over SSH.

### Option A: Use `rsync` (recommended)

```bash
# Copy all files and directories recursively
rsync -avz -e ssh /home/filliat/ user@target-server:/path/to/destination/
```

Notes:

- `-a` preserves permissions, timestamps, and symbolic links
- `-v` enables verbose output
- `-z` compresses data during transfer
- Ensure the trailing slash on `/home/filliat/` copies the contents rather than the directory itself

### Option B: Use `scp`

```bash
scp -r /home/filliat/* user@target-server:/path/to/destination/
```

Notes:

- `-r` recursively copies directories
- Use `scp` when `rsync` is not available
- `scp` is simpler but less efficient than `rsync`

### If copying from a remote WSL host to another server

From your local machine or WSL shell, run:

```bash
scp -r filliat@ASUSVIVO2026:/home/filliat/* user@target-server:/path/to/destination/
```

Or use `rsync` remotely:

```bash
rsync -avz -e ssh filliat@ASUSVIVO2026:/home/filliat/ user@target-server:/path/to/destination/
```

### Validation

After transfer, verify the destination:

```bash
ssh user@target-server "ls -la /path/to/destination"
```

---

## 3. NetApp ONTAP CLI on RHEL 9

### Important: ONTAP CLI is not a RHEL package

There is no separate "ONTAP CLI" package to install on RHEL 9. The ONTAP CLI runs on the NetApp storage controller itself, and you connect to it remotely using SSH.

### Access the ONTAP CLI via SSH

```bash
ssh admin@<cluster_mgmt_ip>
```

Replace:

- `admin` with your NetApp cluster administrator username
- `<cluster_mgmt_ip>` with the management IP of your NetApp cluster

Once connected, you are in the ONTAP CLI shell and can run commands directly.

### Optional: Install NetApp Linux Host Utilities on RHEL 9

If you need local host-side storage utilities for managing LUNs or verifying host configuration, install the NetApp Linux Host Utilities RPM.

#### Steps:

1. Download the 64-bit RPM from the NetApp Support site.
2. Transfer it to your RHEL 9 host.
3. Install it:

```bash
pwd
ls -la ./netapp_linux_unified_host_utilities-8-0.x86_64.rpm
realpath ./netapp_linux_unified_host_utilities-8-0.x86_64.rpm || true
file ./netapp_linux_unified_host_utilities-8-0.x86_64.rpm || true

find ~ -maxdepth 3 -type f -name 'netapp_linux_unified_host_utilities*.rpm' 2>/dev/null
sudo find / -type f -name 'netapp_linux_unified_host_utilities*.rpm' 2>/dev/null

scp 'C:\path\to\netapp_linux_unified_host_utilities-8-0.x86_64.rpm' filliat@ASUSVIVO2026:/home/filliat/
Or from WSL/Windows where the file exists:
scp /mnt/c/Users/You/Downloads/netapp_linux_unified_host_utilities-8-0.x86_64.rpm filliat@ASUSVIVO2026:/home/filliat/

# Once the RPM is present, verify and install
# install using dnf (preferred)
sudo dnf install ./netapp_linux_unified_host_utilities-8-0.x86_64.rpm -y

# or localinstall
sudo dnf localinstall ./netapp_linux_unified_host_utilities-8-0.x86_64.rpm -ysudo dnf repoquery --requires ./netapp_linux_unified_host_utilities-8-0.x86_64.rpm
# then install missing packages with dnf
# Search available mirrors
curl -s "https://pkgs.org/search/?q=netapp_linux_unified_host_utilities" 

# Or try direct download from sourceforge/mirror
curl -LO "https://sourceforge.net/projects/netapp-linux-host-utilities/files/netapp_linux_unified_host_utilities-8-0.x86_64.rpm"



# If downloaded to Windows Downloads folder
cp /mnt/c/Users/Mikef/Downloads/netapp_linux_unified_host_utilities-8-0.x86_64.rpm ~/

# Install
sudo rpm -ivh netapp_linux_unified_host_utilities-8-0.x86_64.rpm

# Search EPEL or community repos
dnf search netapp
dnf repolist

# Check if available via subscription
subscription-manager repos --list | grep -i netapp


# Verify the file
ls -lh netapp_linux_unified_host_utilities-8-0.x86_64.rpm
rpm -qip netapp_linux_unified_host_utilities-8-0.x86_64.rpm

# Install
sudo rpm -ivh netapp_linux_unified_host_utilities-8-0.x86_64.rpm


rpm -ivh netapp_linux_unified_host_utilities-8-0.x86_64.rpm
sudo dnf install ./netapp_linux_unified_host_utilities-8-0.x86_64.rpm


```

4. Verify with:

```bash
sanlun version
```

### Optional: Install Linux storage utilities for NVMe-oF or multipath

```bash
sudo dnf install nvme-cli device-mapper-multipath -y
```

Use these if you are managing NVMe-oF or multipath storage with ONTAP.

---

## 4. Recommended Automation and Secure Access

### Use SSH keys instead of password auth

Generate or use existing SSH keys and add them to your remote targets:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "filliat@ASUSVIVO2026"
ssh-copy-id user@target-server
```

### Use Ansible for repeatable remote tasks

Ansible is a great choice for:

- copying large file sets
- configuring RHEL hosts
- mounting NFS exports
- managing NetApp clusters via REST or CLI automation

### Secure credential handling

Avoid hardcoding passwords. Use:

- environment variables
- Ansible Vault
- SSH agent forwarding

---

## 5. Training Notes for WSL and RHEL 9 Documentation

To keep documentation user-friendly, emphasize:

- plain-language step-by-step instructions
- clear commands with copy-paste blocks
- exact expected outputs or verification commands
- warnings for common issues
- links to the official Red Hat and NetApp docs when helpful

---

## 6. Suggested Next Steps

- Save this training file in `WSL-WORK-2026`
- Review the current docs in the same folder and add a summary section or improved command examples
- If you need, I can also create a second file with a complete `rsync` migration playbook or a third file with NetApp Ansible automation examples
