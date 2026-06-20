# Ansible NetApp & RHEL 9 Automation Playbooks

This repository contains Ansible playbooks and roles for automating NetApp ONTAP storage provisioning and configuring RHEL 9 client hosts to mount NFS exports.

## Role Architecture

To separate storage configuration from client configuration, tasks have been modularized into two reusable Ansible roles:

1. **`netapp_provision`**: Connects to the NetApp ONTAP cluster using the REST API to provision SVMs, LIF interfaces, local admin users, export policies, and FlexVol volumes.
2. **`rhel_client`**: Connects to target RHEL 9 client systems via SSH to install `nfs-utils`, create local mount points, and mount the NetApp NFS export with recommended mount options.

---

## Playbook Mapping

Below is a map of each playbook file to the tasks it accomplishes:

### 1. Core Orchestration Playbooks

* **[site.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/site.yml)**: **Master Playbook**. Imports both `provision_storage.yml` and `mount_nfs.yml` to perform end-to-end storage provisioning and client mounting in sequence.
* **[provision_storage.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/provision_storage.yml)**: **Storage Provisioning**. Targets the `netapp_clusters` host group to orchestrate NetApp SVM setup, network interfaces (LIFs), local user creation, and FlexVol provisioning. It calls the `netapp_provision` role.
* **[mount_nfs.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/mount_nfs.yml)**: **Client NFS Mount**. Targets the `rhel_clients` host group to prepare the RHEL 9 environment (install `nfs-utils`), create the mount path, and mount the NFS share (updating `/etc/fstab`). It calls the `rhel_client` role.

### 2. Migration & Advanced Storage Playbooks

* **[rsync_migration.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/rsync_migration.yml)**: **Data Migration**. Automates transferring existing datasets from a legacy or WSL host directly into the newly mounted NetApp volumes on RHEL 9 client hosts via secure `rsync`.
* **[netapp_automation_example.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/netapp_automation_example.yml)**: **Advanced Storage Management**. Demonstrates enterprise operations on ONTAP, such as cluster info gathering, volume snapshots, autosizing configuration, Qtree provisioning, quota enforcement, and snapshot policies.

### 3. Standalone Helper Playbooks

* **[create_volume.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/create_volume.yml)**: A simplified, standalone playbook showing how to create a volume on ONTAP without using roles.
* **[playbook.yml](file:///d:/DOCU-2026/Python-vscode-2026/WSL-WORK-2026/playbook.yml)**: A basic facts gathering playbook that uses `na_ontap_cluster_info` to retrieve system details.

---

## How to Execute

### Prerequisites
- Install Python dependencies and collections on your control node:
  ```bash
  python3 -m pip install --user netapp-lib
  ansible-galaxy collection install netapp.ontap ansible.posix
  ```
- Configure inventory in `hosts.yml` and encrypt credentials in `vault.yml`.

### Run Playbooks
Run the master orchestration playbook to run the entire flow:
```bash
ansible-playbook -i hosts.yml site.yml --ask-vault-pass
```

Or execute playbooks individually to target specific tasks:
- **NetApp Provisioning only**:
  ```bash
  ansible-playbook -i hosts.yml provision_storage.yml --ask-vault-pass
  ```
- **RHEL Client mounting only**:
  ```bash
  ansible-playbook -i hosts.yml mount_nfs.yml
  ```
