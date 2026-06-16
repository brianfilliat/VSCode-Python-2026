# Ceph OSD Replacement Playbook

Files
- `osd_replace.yml` — main playbook to replace a failed OSD with a replacement device.
- `inventory.example` — example inventory file showing `ceph_admin` and `ceph_osds` groups.

Usage (dry-run first)

1. Copy `inventory.example` to `inventory` and update hostnames and SSH user.
2. Preview actions (safe):

```bash
ansible-playbook -i inventory outputs/ansible/osd_replace.yml -e "osd_id=3 replacement_device=/dev/sdb replacement_host=osd-host-3.example.com"
```

3. To perform the replacement, set `dry_run=false` and `confirm_replace=true`:

```bash
ansible-playbook -i inventory outputs/ansible/osd_replace.yml \
  -e "osd_id=3 replacement_device=/dev/sdb replacement_host=osd-host-3.example.com" \
  -e "dry_run=false" -e "confirm_replace=true"
```

Prerequisites & Safety
- Run from an administrative host with Ceph CLI installed and access to the cluster (group `ceph_admin`).
- Ensure SSH access to the replacement host and that `ceph-volume` is installed if provisioning with LVM.
- Understand Ceph capacity and rebuild windows before removing an OSD.
- This playbook performs destructive actions when `dry_run=false`; set `confirm_replace=true` to acknowledge risk.

Customization
- Adjust `recovery_timeout` variable for longer rebuild windows.
- Replace `ceph-volume` invocation with your provisioning method if you use containers or orchestration.

Windows helper
 - A Windows PowerShell wrapper is available to run this playbook inside WSL:

```powershell
.\outputs\scripts\run_osd_replace_wsl.ps1 -OsdId 3 -ReplacementDevice /dev/sdb -ReplacementHost osd-host-3.example.com
```

Add `-Execute` to perform the live replacement (the script will pass `dry_run=false` and `confirm_replace=true` into the playbook):

```powershell
.\outputs\scripts\run_osd_replace_wsl.ps1 -OsdId 3 -ReplacementDevice /dev/sdb -ReplacementHost osd-host-3.example.com -Execute
```

The wrapper copies `outputs/ansible/inventory.example` into `inventory` and converts Windows paths to WSL paths. Ensure WSL has Ansible installed and accessible.

WSL setup script
- A helper script is provided to install Ansible inside WSL (Ubuntu):

```bash
sudo bash outputs/scripts/setup_ansible_wsl.sh
```

Add `--install-ceph` to also install the `ceph-common` package (ceph CLI) if you plan to run Ceph commands from WSL:

```bash
sudo bash outputs/scripts/setup_ansible_wsl.sh --install-ceph
```

The script creates a Python virtualenv at `~/.ansible-venv` for the invoking user and installs `ansible` there. After running it, activate with:

```bash
source ~/.ansible-venv/bin/activate
ansible --version
```
