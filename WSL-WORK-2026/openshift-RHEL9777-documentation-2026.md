# RHEL9777 — OpenShift Sandbox VM Documentation
**Date:** June 15, 2026  
**Environment:** Red Hat Developer Sandbox (OpenShift 4.21.18)  
**VM:** rhel9777 — RHEL 9.8 (Plow) running via KubeVirt  
**Namespace:** rhafilliated-dev  
**Author:** filliat

---

## Overview

This document covers the full setup, configuration, and connection workflow for accessing a KubeVirt-managed RHEL9 virtual machine running inside a Red Hat Developer Sandbox OpenShift cluster from a RHEL9 WSL2 environment on Windows.

---

## Environment Summary

| Component | Details |
|-----------|---------|
| Local OS | Windows + RHEL9 WSL2 |
| WSL2 Hostname | ASUSVIVO2026 |
| WSL2 User | filliat |
| OpenShift Server | https://api.rm1.0a51.p1.openshiftapps.com:6443 |
| OpenShift Version | 4.21.18 |
| Kubernetes Version | v1.34.8 |
| Namespace | rhafilliated-dev |
| VM Name | rhel9777 |
| VM OS | Red Hat Enterprise Linux 9.8 (Plow) |
| VM Kernel | 5.14.0-687.5.1.el9_8.x86_64 |
| VM IP (cluster-internal) | 10.128.5.44 / 10.0.2.2 |
| VM User | rhel |

---

## Step 1 — Install oc CLI on RHEL9 WSL2

### Problem: ARM64 binary downloaded by mistake

Initial download used `arm64` URL — caused `Exec format error` on x86_64 WSL2.

```bash
# Check architecture first
uname -m
# x86_64
```

### Correct Download (amd64)

```bash
cd ~
curl -LO https://downloads-openshift-console.apps.rm1.0a51.p1.openshiftapps.com/amd64/linux/oc.rhel9.tar
tar -xvf oc.rhel9.tar
sudo mv oc.rhel9 /usr/local/bin/oc
sudo chmod +x /usr/local/bin/oc
oc version
```

### Output
```
Client Version: 4.21.0-202605260453.p2.gfdf8dab.assembly.stream.el9-fdf8dab
Kustomize Version: v5.7.1
Server Version: 4.21.18
Kubernetes Version: v1.34.8
```

> Note: The tar extracts as `oc.rhel9` not `oc` — rename on install.

---

## Step 2 — Login to OpenShift Sandbox

```bash
oc login --token=<your-token> --server=https://api.rm1.0a51.p1.openshiftapps.com:6443
```

Get token from: https://console.redhat.com/openshift/sandbox → username → **Copy login command** → **Display Token**

### Output
```
Logged into "https://api.rm1.0a51.p1.openshiftapps.com:6443" as "rhafilliated"

Projects available:
  openshift-virtualization-os-images
  rhafilliated-dev
  sandbox-shared-models

Using project "".
```

---

## Step 3 — Explore the Namespace

```bash
oc project rhafilliated-dev
oc get all
```

### Resources Found

| Resource | Name | Status |
|----------|------|--------|
| Pod | virt-launcher-rhel9777 | Running |
| Pod | nginx-sample | Running (after scale-up) |
| Service | headless | ClusterIP — port 5434 |
| Service | nginx-sample | ClusterIP — 8080/8443 |
| Deployment | nginx-sample | Scaled to 0 (scaled up manually) |
| VM | rhel9777 | Running |
| VMI | rhel9777 | Running — 10.128.5.64 |
| DataVolume | rhel9777-volume | Succeeded — 30Gi gp3 |
| Route | nginx-sample | nginx-sample-rhafilliated-dev.apps.rm1.0a51.p1.openshiftapps.com |

### Scale nginx back up
```bash
oc scale deployment nginx-sample --replicas=1
oc get pods -w
```

---

## Step 4 — Install virtctl

Server KubeVirt version is `v1.7.3` — must match exactly.

```bash
# Remove old version (v0.59.0 — causes format errors)
sudo rm /usr/local/bin/virtctl

# Download matching version
curl -LO https://github.com/kubevirt/kubevirt/releases/download/v1.7.3/virtctl-v1.7.3-linux-amd64
sudo mv virtctl-v1.7.3-linux-amd64 /usr/local/bin/virtctl
sudo chmod +x /usr/local/bin/virtctl
virtctl version
```

> Always match virtctl version to the cluster's KubeVirt server version to avoid compatibility warnings and command failures.

---

## Step 5 — SSH into rhel9777 VM

### VM SSH Key Details

| Field | Value |
|-------|-------|
| Key Type | ed25519 |
| Key Comment | dynamic-key-1781526890 |
| Auth Method | Public key (password auth disabled on VM) |
| Passphrase | (set on private key) |
| Secret Name | asctokey (in rhafilliated-dev namespace) |

### Retrieve public key from OpenShift secret
```bash
oc get secret asctokey -o jsonpath='{.data.key}' | base64 -d
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcxpWwxSaJY4cNjsdin0J8yi6uW9WSTy/44Ef70VsG8 dynamic-key-1781526890
```

### Save private key
```bash
mkdir -p ~/.ssh
cat > ~/.ssh/rhel9777_key << 'EOF'
-----BEGIN OPENSSH PRIVATE KEY-----
<private-key-content>
-----END OPENSSH PRIVATE KEY-----
EOF
chmod 600 ~/.ssh/rhel9777_key
```

### Add key to ssh-agent (required — key is passphrase-protected)
```bash
eval $(ssh-agent)
ssh-add /home/filliat/.ssh/rhel9777_key
# Enter passphrase when prompted
# Identity added: /home/filliat/.ssh/rhel9777_key (dynamic-key-1781526890)
```

### Connect via virtctl port-forward + SSH

The VM IP `10.128.5.44` is cluster-internal and not reachable from WSL2 directly. Use virtctl port-forward as a proxy.

```bash
# Start port-forward in background
virtctl port-forward vmi/rhel9777 22022:22 &
sleep 3

# SSH through the forwarded port
ssh -p 22022 rhel@127.0.0.1
```

### Successful Connection Output
```
Register this system with Red Hat Insights: rhc connect
Last login: Mon Jun 15 13:33:04 2026
[rhel@rhel9777 ~]$
```

---

## Step 6 — VM System Information

```bash
whoami       # rhel
hostname     # rhel9777
cat /etc/redhat-release  # Red Hat Enterprise Linux release 9.8 (Plow)
uname -a     # Linux rhel9777 5.14.0-687.5.1.el9_8.x86_64
```

### Memory
```
               total        used        free      shared  buff/cache   available
Mem:           3.5Gi       434Mi       3.1Gi        12Mi       201Mi       3.1Gi
Swap:             0B          0B          0B
```

### Disk
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda4        29G  1.9G   27G   7% /
/dev/vda3       960M  333M  628M  35% /boot
/dev/vda2       200M  7.7M  193M   4% /boot/efi
```

### Network
```
eth0: 10.0.2.2/24 (cluster network)
     MAC: 02:0d:82:d5:16:27
     MTU: 8901
```

---

## Troubleshooting Log

| Issue | Cause | Fix |
|-------|-------|-----|
| `Exec format error` on oc | Downloaded arm64 binary on x86_64 | Use amd64 URL |
| `tar extracts as oc.rhel9` | Filename in tar differs from `oc` | `mv oc.rhel9 /usr/local/bin/oc` |
| virtctl version mismatch | v0.59.0 vs server v1.7.3 | Download v1.7.3 from GitHub |
| `target must contain type and name` | Wrong virtctl ssh syntax | Use `rhel@vmi/rhel9777` format |
| `failed creating known_hosts` | `~/.ssh/` directory missing | `mkdir -p ~/.ssh` |
| `Permission denied (publickey)` | Key not loaded in ssh-agent | `eval $(ssh-agent) && ssh-add` |
| `bind: address already in use` | Port 22022 already forwarded | Previous background job still running — reuse it |
| `Broken pipe` on SSH | Port-forward exited before SSH connected | Run port-forward in background with `&`, then SSH |
| `listen tcp 127.0.0.1:22 permission denied` | Port 22 is privileged | Use high port `22022:22` instead |
| VM console forbidden | Sandbox RBAC restrictions | Use port-forward + SSH instead |
| `oc exec` forbidden on virt-launcher | SCC restrictions in sandbox | Use SSH via port-forward |

---

## Quick Reference — Daily Workflow

```bash
# 1. Login (token expires periodically)
oc login --token=<token> --server=https://api.rm1.0a51.p1.openshiftapps.com:6443

# 2. Set project
oc project rhafilliated-dev

# 3. Load SSH key
eval $(ssh-agent)
ssh-add /home/filliat/.ssh/rhel9777_key

# 4. Start port-forward and SSH
virtctl port-forward vmi/rhel9777 22022:22 &
sleep 3
ssh -p 22022 rhel@127.0.0.1
```

---

## VM Spec Summary (from oc describe vm rhel9777)

| Field | Value |
|-------|-------|
| Instance Type | u1.medium |
| Preference | rhel.9 |
| Architecture | amd64 |
| Machine Type | pc-q35-rhel9.6.0 |
| Storage | 30Gi gp3 (DataVolume from rhel9 DataSource) |
| Network | Masquerade / headless subdomain |
| SSH Auth | asctokey secret (ed25519) |
| Run Strategy | Manual |
| Status | Running / Ready |

---

## Resources

- Red Hat Developer Sandbox: https://developers.redhat.com/developer-sandbox
- OpenShift Console: https://console.redhat.com/openshift/sandbox
- virtctl releases: https://github.com/kubevirt/kubevirt/releases
- oc CLI downloads: https://downloads-openshift-console.apps.rm1.0a51.p1.openshiftapps.com
- oc CLI Reference: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html

---

*Last Updated: June 15, 2026 | Status: Active*
