# Training: Ansible-Based NetApp Automation on RHEL 9

## Purpose

This training guide shows how to use Ansible to automate NetApp ONTAP tasks from a RHEL 9 control host. It is written for users who want repeatable, secure automation and a clear path from WSL to RHEL.

---

## 1. Why Use Ansible for NetApp?

Ansible offers:

- agentless automation over SSH/HTTPS
- reusable playbooks for provisioning storage
- secure credentials with Ansible Vault
- easy inventory management for multiple clusters
- support for NetApp ONTAP modules and collections

---

## 2. Install Ansible on RHEL 9

### Basic install

```bash
sudo dnf install python3 python3-pip ansible-core -y
```

### Install required collections

```bash
python3 -m pip install --user netapp-lib
ansible-galaxy collection install netapp.ontap
ansible-galaxy collection install ansible.posix
```

If you only install `ansible.posix` and not `netapp.ontap`, Ansible will not recognize modules like `na_ontap_svm`.

Verify the collection is available to the control node:

```bash
ansible-galaxy collection list | grep netapp.ontap
```

If the collection is not listed, install it:

```bash
ansible-galaxy collection install netapp.ontap
```

> `netapp-lib` is useful for compatibility with older NetApp modules. The `netapp.ontap` collection uses REST APIs for ONTAP 9.6+.

---

## 3. Secure Credentials with Ansible Vault

### Create vault file

```bash
ansible-vault create vault.yml
```

Example contents:

```yaml
netapp_username: "admin"
netapp_password: "MySecurePassword123"
```

### Use the vault in a playbook

```yaml
vars_files:
  - vault.yml
```

Run the playbook with:

```bash
ansible-playbook -i hosts.yml provision_netapp.yml --ask-vault-pass
```

If you are using a different playbook filename such as `site.yml` or `provision_storage.yml`, pass that exact file instead.

If the module still fails to resolve, confirm you are running the playbook from the same environment where `netapp.ontap` is installed.

---

## 4. Example Inventory Layout

Create `hosts.yml` with one or more NetApp clusters.

```yaml
all:
  children:
    netapp_clusters:
      hosts:
        cluster_a:
          ansible_host: 10.10.10.50
          lif_ip: 10.10.10.60
          lif_netmask: 255.255.255.0
          lif_home_node: node-a-01
          lif_home_port: e0c
        cluster_b:
          ansible_host: 10.20.20.50
          lif_ip: 10.20.20.60
          lif_netmask: 255.255.255.0
          lif_home_node: node-b-01
          lif_home_port: e0c
      vars:
        https: true
        validate_certs: false
```

---

## 5. Sample Provisioning Playbook

Create `provision_netapp.yml`:

```yaml
---
- name: Provision NetApp Storage
  hosts: netapp_clusters
  gather_facts: false
  collections:
    - netapp.ontap
  vars_files:
    - vault.yml
  vars:
    svm_name: rhel9_app_svm
    root_aggr: aggr1
    local_svm_user: svm_admin
    local_svm_pass: ChangeMeSecurely99!
    vol_name: nfs_data_vol
    vol_size: 100
    vol_size_unit: gb
    export_policy_name: rhel9_hosts
    lif_name: nfs_data_lif
    allowed_client_subnet: 10.0.0.0/8

  tasks:
    - name: Create the SVM
      na_ontap_svm:
        state: present
        name: "{{ svm_name }}"
        root_volume_aggregate: "{{ root_aggr }}"
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"

    - name: Create network LIF for NFS traffic
      na_ontap_interface:
        state: present
        interface_name: "{{ lif_name }}"
        vserver: "{{ svm_name }}"
        home_node: "{{ lif_home_node }}"
        home_port: "{{ lif_home_port }}"
        address: "{{ lif_ip }}"
        netmask: "{{ lif_netmask }}"
        service_policy: default-data-files
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"

    - name: Create Local SVM user
      na_ontap_user:
        state: present
        name: "{{ local_svm_user }}"
        vserver: "{{ svm_name }}"
        applications:
          - ssh
          - http
        role: vsadmin
        user_password: "{{ local_svm_pass }}"
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"

    - name: Create NFS export policy rule
      na_ontap_export_policy_rule:
        state: present
        policy_name: "{{ export_policy_name }}"
        vserver: "{{ svm_name }}"
        client_match: "{{ allowed_client_subnet }}"
        ro_rule: sys
        rw_rule: sys
        super_user_security: sys
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"

    - name: Create FlexVol volume with export policy
      na_ontap_volume:
        state: present
        name: "{{ vol_name }}"
        vserver: "{{ svm_name }}"
        aggregate_name: "{{ root_aggr }}"
        size: "{{ vol_size }}"
        size_unit: "{{ vol_size_unit }}"
        policy: "{{ export_policy_name }}"
        junction_path: "/{{ vol_name }}"
        space_guarantee: none
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"
```

---

## 6. Add DNS and Kerberos (Optional)

If you want Kerberos-secured NFS and DNS name resolution, add these tasks before volume creation:

```yaml
    - name: Configure SVM DNS
      na_ontap_dns:
        state: present
        vserver: "{{ svm_name }}"
        domains: "example.com"
        name_servers:
          - 10.10.10.10
          - 10.10.10.11
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"

    - name: Create Kerberos export policy rule
      na_ontap_export_policy_rule:
        state: present
        policy_name: "{{ export_policy_name }}"
        vserver: "{{ svm_name }}"
        client_match: "{{ allowed_client_subnet }}"
        ro_rule: krb5
        rw_rule: krb5
        super_user_security: krb5
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"
```

> Note: Kerberos automation requires a working AD/KDC environment and correct DNS reverse lookups.

---

## 7. Run the Playbooks

To provision NetApp storage only:
```bash
ansible-playbook -i hosts.yml provision_storage.yml --ask-vault-pass
```

To configure Linux clients and mount the NFS share only:
```bash
ansible-playbook -i hosts.yml mount_nfs.yml
```

To run the entire end-to-end flow:
```bash
ansible-playbook -i hosts.yml site.yml --ask-vault-pass
```

If you manage multiple clusters, Ansible will apply the same tasks to each host defined in `netapp_clusters`.

---

## 8. Validation

Use these checks after the playbook runs:

```bash
ansible-playbook -i hosts.yml site.yml --ask-vault-pass --check
```

Or verify directly on the cluster:

```bash
ssh admin@<cluster_mgmt_ip>
> vserver show
> volume show -vserver rhel9_app_svm
> export-policy rule show -vserver rhel9_app_svm
```

---

## 9. Notes for WSL Users

- You can author Ansible playbooks in WSL and push them to the RHEL 9 control host.
- Use `scp` or `rsync` to move files from WSL to RHEL 9 if needed.
- Keep your Ansible control node and target hosts separated cleanly in inventory for clarity.

---

## 10. Role-Based Architecture and Modular Playbooks

The recommended improvements have been implemented. The automation has been refactored into a scalable, role-based architecture:

- **Ansible Roles**:
  - **`netapp_provision`**: Connects to the NetApp ONTAP cluster to provision the SVM, LIF, local SVM user, export policy, and FlexVol volume.
  - **`rhel_client`**: Connects to target RHEL 9 clients to install `nfs-utils`, create local mount points, and configure the NFS mounts.
- **Playbooks**:
  - **`provision_storage.yml`**: Provisions NetApp ONTAP clusters via the `netapp_provision` role.
  - **`mount_nfs.yml`**: Configures client systems and mounts NFS exports via the `rhel_client` role.
  - **`site.yml`**: Master orchestration playbook that imports the above two playbooks.
- **Documentation**:
  - **`README.md`**: Maps all playbooks and roles to their respective automation tasks.

