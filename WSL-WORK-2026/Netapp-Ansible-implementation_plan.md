# Implementation Plan - Refactoring NetApp Ansible Automation

This plan outlines the steps to separate NetApp storage provisioning from RHEL client configuration using Ansible roles, add a dedicated client-mount playbook, create a master `README.md`, and update the training documentation.

## Proposed Changes

### 1. Ansible Roles

We will create two separate Ansible roles to decouple the NetApp configuration logic from the Linux client configuration logic.

#### [NEW] [defaults/main.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/roles/netapp_provision/defaults/main.yml)
Define default variables for NetApp provisioning:
```yaml
---
svm_name: "rhel9_app_svm"
root_aggr: "aggr1"
local_svm_user: "svm_admin"
local_svm_pass: "ChangeMeSecurely99!"
vol_name: "nfs_data_vol"
vol_size: 100
vol_size_unit: "gb"
export_policy_name: "rhel9_hosts"
allowed_client_subnet: "10.0.0.0/8"
lif_name: "nfs_data_lif"
```

#### [NEW] [tasks/main.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/roles/netapp_provision/tasks/main.yml)
Contains the ONTAP provisioning tasks extracted from `site.yml` and `provision_storage.yml`:
1. Create the SVM (`na_ontap_svm`)
2. Create network LIF for NFS traffic (`na_ontap_interface`)
3. Create Local User inside SVM (`na_ontap_user`)
4. Create NFS Export Policy Rule (`na_ontap_export_policy_rule`)
5. Create Volume with Export Policy (`na_ontap_volume`)

#### [NEW] [defaults/main.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/roles/rhel_client/defaults/main.yml)
Define default variables for the Linux clients:
```yaml
---
vol_name: "nfs_data_vol"
local_mount_path: "/mnt/netapp_nfs"
```

#### [NEW] [tasks/main.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/roles/rhel_client/tasks/main.yml)
Contains client-side mount configuration tasks:
1. Ensure `nfs-utils` is installed on RHEL 9 (`ansible.builtin.dnf`)
2. Ensure the local mount directory exists (`ansible.builtin.file`)
3. Mount NetApp volume and append to `/etc/fstab` (`ansible.posix.mount`)

---

### 2. Playbooks

#### [MODIFY] [provision_storage.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/provision_storage.yml)
Refactor to leverage the `netapp_provision` role:
```yaml
---
- name: Multi-Cluster NetApp Provisioning
  hosts: netapp_clusters
  gather_facts: false
  collections:
    - netapp.ontap
  vars_files:
    - vault.yml
  roles:
    - netapp_provision
```

#### [NEW] [mount_nfs.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/mount_nfs.yml)
Create a new playbook dedicated to configuring RHEL NFS clients:
```yaml
---
- name: Configure Linux Clients and Mount NFS Share
  hosts: rhel_clients
  become: true
  gather_facts: true
  roles:
    - rhel_client
```

#### [MODIFY] [site.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/site.yml)
Clean up `site.yml` to import the two distinct playbooks rather than writing inline tasks:
```yaml
---
- import_playbook: provision_storage.yml
- import_playbook: mount_nfs.yml
```

---

### 3. Documentation

#### [NEW] [README.md](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/README.md)
Add a master README that maps each playbook to the task it accomplishes, describes the inventory/role structure, and provides instructions on execution.

#### [MODIFY] [Training-NetApp-Ansible-RHEL9.md](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/Training-NetApp-Ansible-RHEL9.md)
- Update existing sections referencing running `provision_storage.yml` or `site.yml`.
- Document the new role-based structure and the `mount_nfs.yml` playbook.
- Mark the recommended improvements as completed/implemented.

---

## Verification Plan

### Automated Syntax Check
We will verify the syntax of the playbooks using Ansible syntax checks (simulated via standard syntax validations if ansible is not locally run, or proposed directly if needed).
- `ansible-playbook -i hosts.yml site.yml --syntax-check`
- `ansible-playbook -i hosts.yml provision_storage.yml --syntax-check`
- `ansible-playbook -i hosts.yml mount_nfs.yml --syntax-check`

### Manual Verification
- Review playbook structures and task declarations to ensure variables, collections, and privileges are correctly scoped.
