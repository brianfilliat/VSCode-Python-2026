# Ceph Reef Deployment — RHEL 9 WSL2 — 2026

**Status:** In Progress  
**Ceph Version:** 18.2.8 Reef (stable)  
**Host:** ASUSVIVO2026 (WSL2, RHEL 9)  
**Kernel:** Linux 6.6.87.2-microsoft-standard-WSL2  
**Architecture:** x86-64  
**Date:** May 14, 2026  

---

## Cluster Info (from RHEL 9 bootstrap — reference)

| Item | Value |
|------|-------|
| Dashboard URL | https://ASUSVIVO2026.localdomain:8443/ |
| Dashboard IP | https://172.21.204.100:8443/ |
| User | admin |
| Password | u20legmoz2 |
| FSID | 4f287b4e-4d74-11f1-aa0d-00155d49dc91 |
| Mon IP | 172.21.204.100 |
| Network | 172.21.192.0/20 |

---

## Step 0 — Fix WSL2 DNS (Do This First)

WSL2 auto-generates `/etc/resolv.conf` with an internal nameserver (`10.255.255.254`) that
cannot resolve Red Hat CDN (`cdn.redhat.com`). This breaks all `dnf` operations.

```bash
# Stop WSL from regenerating resolv.conf
sudo tee -a /etc/wsl.conf << 'EOF'
[network]
generateResolvConf = false
EOF

# Remove the auto-generated file
sudo chattr -i /etc/resolv.conf 2>/dev/null
sudo rm -f /etc/resolv.conf




# Create new one
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'
# Set working DNS
# Lock it
sudo chattr +i /etc/resolv.conf
# Check if file is immutable
lsattr /etc/resolv.conf



# Verify
cat /etc/resolv.conf
curl -I https://cdn.redhat.com


sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'
```

Restart WSL from Windows PowerShell after editing `wsl.conf`:

```powershell
wsl --shutdown
wsl -d RHEL
```

---

## Step 1 — Register RHEL 9 with Red Hat

RHEL 9 uses **Simple Content Access (SCA)** — no pool attachment needed after registration.

```bash
sudo subscription-manager register --username rhafilliated
```

> Note: `subscription-manager attach --auto` is deprecated. Registration alone is sufficient with SCA.

Enable base repos:

```bash
sudo subscription-manager repos \
  --enable=rhel-9-for-x86_64-baseos-rpms \
  --enable=rhel-9-for-x86_64-appstream-rpms
```

Verify subscription status:

```bash
sudo subscription-manager status
sudo subscription-manager repos --list | grep -i ceph
```

---

## Step 2 — Import GPG Keys and Fix CA Certificates

```bash
# Import Red Hat GPG key
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

# Verify key imported
rpm -qa gpg-pubkey

# Update CA certificates
sudo dnf install -y ca-certificates
sudo update-ca-trust extract

# Clean dnf cache and rebuild
sudo dnf clean all
sudo dnf makecache
```

---

## Step 3 — Install Required Packages

```bash
sudo dnf install -y python3 podman iputils bind-utils ca-certificates
sudo update-ca-trust
sudo update-ca-trust extract
```

Verify network after install:

```bash
ping -c 3 8.8.8.8
curl -I http://google.com
curl -I https://cdn.redhat.com
```

---

## Step 4 — Fix /run/udev for WSL2

Podman requires `/run/udev` which does not exist in WSL2. Without it, all containers fail to start.

```bash
sudo mkdir -p /run/udev
```

Make it persistent across WSL restarts by adding to `wsl.conf`:

```bash
sudo tee /etc/wsl.conf << 'EOF'
[boot]
systemd=true
command = mkdir -p /run/udev

[network]
generateResolvConf = false
EOF
```

Restart WSL:

```powershell
wsl --shutdown
wsl -d RHEL
```

---

## Step 5 — Install cephadm via Ceph el9 Repo

> **Do NOT use the GitHub raw URL** (`quincy/src/cephadm/cephadm`) — it is no longer a
> standalone script and will fail with `ModuleNotFoundError: No module named 'cephadmlib'`.

Manually create the repo file:

```bash
sudo tee /etc/yum.repos.d/ceph-reef.repo << 'EOF'
[ceph-reef-noarch]
name=Ceph Reef noarch
baseurl=https://download.ceph.com/rpm-reef/el9/noarch/
enabled=1
gpgcheck=0

[ceph-reef-x86_64]
name=Ceph Reef x86_64
baseurl=https://download.ceph.com/rpm-reef/el9/x86_64/
enabled=1
gpgcheck=0
EOF

curl --silent --remote-name --location https://download.ceph.com/rpm-reef/el9/noarch/cephadm
sudo dnf clean all
# Install EPEL
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install EPEL
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Enable CRB (CodeReady Builder) - provides libarrow, libparquet
sudo /usr/bin/crb enable

# Install missing libs individually
sudo dnf install -y gperftools-libs   # provides libtcmalloc.so.4
sudo dnf install -y liboath           # provides liboath.so.0
sudo dnf install -y arrow-libs        # provides libarrow.so.900
sudo dnf install -y parquet-libs      # provides libparquet.so.900


# Install missing libs individually
sudo dnf install -y gperftools-libs   # provides libtcmalloc.so.4
sudo dnf install -y liboath           # provides liboath.so.0
sudo dnf install -y arrow-libs        # provides libarrow.so.900
sudo dnf install -y parquet-libs      # provides libparquet.so.900


sudo dnf install -y cephadm
sudo dnf install ceph-common
```

---

## Step 6 — Verify Podman Works

```bash
podman run --rm --network=host hello-world
```

Expected output includes `Hello Podman World` — if you see nftables errors see Issue 4 below.

---

## Step 7 — Bootstrap Ceph Cluster

```bash
# Get your WSL IP
hostname -I

# Bootstrap (use your actual IP)
sudo cephadm bootstrap \
  --mon-ip 172.21.204.100 \
  --skip-monitoring-stack \
  --single-host-defaults
```

Bootstrap takes 3-5 minutes. Expected completion output:

```
Bootstrap complete.
Ceph Dashboard is now available at:
  URL: https://ASUSVIVO2026.localdomain:8443/
  User: admin
  Password: <generated>
```

---

## Post-Bootstrap

### Verify Cluster Health

```bash
sudo cephadm shell -- ceph status
sudo cephadm shell -- ceph health
```

### Access Ceph CLI

```bash
# Single cluster shortcut
sudo cephadm shell

# Multi-cluster explicit
sudo /sbin/cephadm shell \
  --fsid 4f287b4e-4d74-11f1-aa0d-00155d49dc91 \
  -c /etc/ceph/ceph.conf \
  -k /etc/ceph/ceph.client.admin.keyring
```

### Add OSDs (Storage)

```bash
# List available disks
sudo cephadm shell -- ceph orch device ls

# Add OSD
sudo cephadm shell -- ceph orch daemon add osd ASUSVIVO2026:/dev/sdX
```

### Enable Telemetry (Optional)

```bash
sudo cephadm shell -- ceph telemetry on
```

---

## Known Issues & Fixes

### Issue 1 — WSL2 DNS Broken (cdn.redhat.com not resolving)

**Error:**
```
Curl error (6): Couldn't resolve host name for https://cdn.redhat.com/...
Could not resolve host: cdn.redhat.com
```

**Cause:** WSL2 auto-generates `/etc/resolv.conf` with `nameserver 10.255.255.254` which
cannot resolve external Red Hat CDN hostnames.

**Fix:** See Step 0 above — lock `/etc/resolv.conf` and disable WSL auto-generation.

---

### Issue 2 — cephadm ModuleNotFoundError

**Error:**
```
ModuleNotFoundError: No module named 'cephadmlib'
```

**Cause:** The GitHub raw `cephadm` script is no longer standalone — it requires `cephadmlib`
as a companion package.

**Fix:** Install `cephadm` via the RPM repo at `download.ceph.com` (see Step 5).

---

### Issue 3 — cephadm add-repo 404 Not Found

**Error:**
```
unable to fetch repo metadata: <HTTPError 404: 'Not Found'>
```

**Cause:** `cephadm add-repo` auto-detects the OS version and looks for an `el9` or `el10`
repo path that may not exist yet.

**Fix:** Skip `cephadm add-repo` entirely. Manually create `/etc/yum.repos.d/ceph-reef.repo`
pointing to `el9` (see Step 5).

---

### Issue 4 — Podman nftables Error (netavark)

**Error:**
```
Error: netavark: nftables error: "nft" did not return successfully while applying ruleset
internal:0:0-0: Error: No such file or directory; did you mean table 'nat' in family ip?
```

**Cause:** WSL2 kernel does not support nftables. Podman's default network backend `netavark`
requires nftables. `iptables-legacy` and CNI plugins are not available on RHEL 9/10.

**Fix:** Use `--network=host` to bypass netavark, and use `--single-host-defaults` for bootstrap:

```bash
# Test
podman run --rm --network=host hello-world

# Bootstrap
sudo cephadm bootstrap \
  --mon-ip 172.21.204.100 \
  --skip-monitoring-stack \
  --single-host-defaults
```

---

### Issue 5 — statfs /run/udev: No Such File or Directory

**Error:**
```
Error: statfs /run/udev: no such file or directory
```

**Cause:** Podman requires `/run/udev` which does not exist in WSL2.

**Fix:**
```bash
sudo mkdir -p /run/udev
```

Make persistent via `wsl.conf` (see Step 4).

---

### Issue 6 — SSL Error Connecting to download.ceph.com

**Error:**
```
curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to download.ceph.com:443
```

**Cause:** CA certificates outdated or missing on fresh RHEL WSL install.

**Fix:**
```bash
sudo dnf install -y ca-certificates
sudo update-ca-trust extract
```

---

### Issue 7 — subscription-manager attach --auto Fails

**Error:**
```
Usage: subscription-manager MODULE-NAME [MODULE-OPTIONS] [--help]
```

**Cause:** `attach --auto` is deprecated in RHEL 9+ with Simple Content Access (SCA).

**Fix:** Registration alone is sufficient. No pool attachment needed:

```bash
sudo subscription-manager register --username <user> --password <pass>
# That's it — SCA grants access automatically
```

---

### Issue 8 — ping / nslookup Not Found

**Cause:** Minimal RHEL WSL install does not include `iputils` or `bind-utils`.

**Fix:**
```bash
sudo dnf install -y iputils bind-utils
```

---

## WSL2 Limitations Summary

| Limitation | Impact | Workaround |
|------------|--------|------------|
| Auto-generated resolv.conf | CDN DNS fails | Lock resolv.conf, disable generateResolvConf |
| No nftables support | Podman netavark fails | Use `--network=host` + `--single-host-defaults` |
| No `/run/udev` | Podman container start fails | `mkdir -p /run/udev` in wsl.conf boot command |
| No `iptables-legacy` | Can't switch podman backend | Not needed with host networking |
| No CNI plugins | Can't use CNI backend | Not needed with host networking |
| `/run/udev` lost on restart | Podman fails after reboot | Add to wsl.conf `command = mkdir -p /run/udev` |

---

## Key File Locations

| File | Path |
|------|------|
| Ceph config | `/etc/ceph/ceph.conf` |
| Admin keyring | `/etc/ceph/ceph.client.admin.keyring` |
| SSH public key | `/etc/ceph/ceph.pub` |
| Cluster data | `/var/lib/ceph/<fsid>/` |
| Ceph repo | `/etc/yum.repos.d/ceph-reef.repo` |
| WSL config | `/etc/wsl.conf` |
| DNS config | `/etc/resolv.conf` |

---

## wsl.conf Reference (Complete)

```ini
[boot]
systemd=true
command = mkdir -p /run/udev

[network]
generateResolvConf = false
```

---

## References

- Ceph Reef Docs: https://docs.ceph.com/en/reef/
- cephadm Bootstrap: https://docs.ceph.com/en/reef/cephadm/install/
- Ceph RPM Downloads: https://download.ceph.com/rpm-reef/el9/
- Red Hat Developer (free RHEL): https://developers.redhat.com
- WSL systemd: https://learn.microsoft.com/en-us/windows/wsl/systemd
- Red Hat Subscription Manager: https://access.redhat.com/documentation/en-us/red_hat_subscription_management

---

*Date: May 14, 2026 | Host: ASUSVIVO2026 | RHEL 9 WSL2 | Ceph 18.2.8 Reef*
