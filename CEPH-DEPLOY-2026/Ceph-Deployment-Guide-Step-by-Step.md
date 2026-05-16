# Ceph Deployment Guide: Step-by-Step with `cephadm`

This guide provides a straightforward path to deploying a basic Ceph cluster using `cephadm`, the modern and recommended orchestration tool for Ceph.

---

## 📋 1. Prerequisites
Before you begin, ensure all nodes in your cluster meet the following requirements:
*   **OS:** A modern Linux distribution (e.g., Ubuntu 20.04+, CentOS 8+, Debian 10+).
*   **Python:** Python 3 must be installed.
*   **Container Engine:** Podman (recommended) or Docker.
*   **Time Sync:** Chrony or NTP must be active for cluster consistency.
*   **LVM2:** Required for OSD provisioning.
*   **Network:** Static IP addresses and SSH access between nodes.

---

## 🚀 2. Install `cephadm`
On your first host (the bootstrap node), install the `cephadm` utility:

```bash
# Download the cephadm script
curl --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm

# Make it executable
chmod +x cephadm

# (Optional) Install cephadm to your path
sudo ./cephadm add-repo --release reef
sudo ./cephadm install
sudo dnf install -y cephadm
```

---

## 🏗️ 3. Bootstrap the Cluster
Run the bootstrap command on your first node. This creates the initial Monitor and Manager daemons.

```bash    inet 172.21.204.100  netmask 255.255.240.0  broadcast 172.21.207.255
sudo cephadm bootstrap --mon-ip 172.21.204.100
```
*   **Output:** This will provide you with the **Dashboard URL**, **Username**, and **Password**. Keep these safe!
*   **Result:** You now have a "cluster of one."

---

## 🐚 4. Enable the Ceph CLI
To run `ceph` commands directly from your shell:

```bash
sudo cephadm shell
# OR install the ceph-common package
sudo ./cephadm add-repo --release quincy
sudo ./cephadm install ceph-common

# Verify health
ceph health
```

---

## ➕ 5. Add More Hosts
To make the cluster resilient, add more nodes. First, copy the SSH public key to the new nodes:

```bash
ssh-copy-id -f -i /etc/ceph/ceph.pub root@<NEW_HOST_IP>
```

Then, add the host to the cluster:
```bash
ceph orch host add <NEW_HOSTNAME> <NEW_HOST_IP>
```

---

## 💾 6. Add Storage (OSDs)
Ceph can automatically discover and use available raw drives.

```bash
# See available devices
ceph orch device ls

# Tell Ceph to use all available raw devices (be careful!)
ceph orch apply osd --all-available-devices
```

---

## 🖥️ 7. Access the Dashboard
Open the URL provided during bootstrap in your browser. You can monitor cluster health, OSD status, and manage pools through this web interface.

---

## 🏁 Summary Checklist
1. [ ] Prerequisites met on all nodes.
2. [ ] `cephadm` installed on bootstrap node.
3. [ ] `cephadm bootstrap` completed.
4. [ ] SSH keys distributed to other nodes.
5. [ ] Additional hosts added via `ceph orch`.
6. [ ] OSDs deployed on available drives.
