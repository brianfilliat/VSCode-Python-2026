# NetApp ONTAP Access from RHEL 9 and WSL

## Purpose

This guide explains how to access NetApp ONTAP from a RHEL 9 host and how to work with WSL for file transfer or scripting tasks. It also clarifies that the ONTAP CLI is not installed on RHEL 9 but accessed remotely over SSH.

---

## 1. Key Concepts

- NetApp ONTAP CLI runs on the storage controller itself.
- From RHEL 9, connect to ONTAP using SSH.
- If you need host-side utilities for storage management, install the NetApp Linux Host Utilities package.
- Use WSL for local file transfer, scripting, and convenience when working from Windows.

---

## 2. Access ONTAP CLI from RHEL 9

### Connect by SSH

```bash
ssh admin@<cluster_mgmt_ip>
```

Replace:

- `admin` with your NetApp management user
- `<cluster_mgmt_ip>` with your cluster management IP address

Once connected, you will be in the ONTAP shell.

### Example session

```bash
$ ssh admin@10.0.0.50
admin@10.0.0.50's password:

Cluster: my-netapp-cluster
> system node show
```

---

## 3. Optional: Install NetApp Linux Host Utilities on RHEL 9

If you need host utilities for LUN, volume, or SAN operations, install the NetApp Host Utilities RPM.

### Steps

1. Download the RPM from the NetApp Support site.
2. Transfer the file to your RHEL 9 host.
3. Install it:

```bash
sudo dnf install ./netapp_linux_unified_host_utilities-8-0.x86_64.rpm
```

4. Verify the install:

```bash
sanlun version
```

---

## 4. Optional: Install Linux Storage Utilities

For storage host management, consider installing standard Linux packages:

```bash
sudo dnf install nvme-cli device-mapper-multipath -y
```

Use `nvme-cli` for NVMe-oF and `device-mapper-multipath` for multipath storage.

---

## 5. Copy Files from WSL Home to a Server

To copy everything from `filliat@ASUSVIVO2026:/home/filliat` to another server, use `rsync` or `scp`.

### Recommended: rsync

```bash
rsync -avz -e ssh filliat@ASUSVIVO2026:/home/filliat/ user@target-server:/path/to/destination/
```

### Alternative: scp

```bash
scp -r filliat@ASUSVIVO2026:/home/filliat/* user@target-server:/path/to/destination/
```

### Verify copied files

```bash
ssh user@target-server "ls -la /path/to/destination"
```

---

## 6. Best Practices

- Use SSH keys instead of passwords whenever possible.
- Keep ONTAP admin credentials out of plain text files.
- Use Ansible Vault or environment variables to secure secrets.
- Document the management IP, username, and any special network settings clearly.

---

## 7. Recommended Next Steps

- If you want automation, install `ansible-core` and the `netapp.ontap` collection.
- If you need RHEL 9 host automation, create a playbook that installs `nfs-utils` and mounts NFS exports.
- For Kerberos-secured NFS, configure DNS and AD/KDC before applying Kerberos export policies.
