*Updated: May 18, 2026 | ASUSVIVO2026 | RHEL 9 WSL2 | Ceph 18.2.8 Reef*


# Ceph Reef Deployment Guide — RHEL 9 WSL2 — 2026

**Status:** Complete ✅  
**Ceph Version:** 18.2.8 Reef (stable)  
**Host:** ASUSVIVO2026 | RHEL 9 WSL2 on Windows  
**Kernel:** Linux 6.6.114.1-microsoft-standard-WSL2  
**Architecture:** x86-64  
**Updated:** May 18, 2026  

---

## Cluster Info

| Item | Value |
|------|-------|
| Dashboard URL | https://ASUSVIVO2026.localdomain:8443/ |
| Dashboard IP | https://172.21.204.100:8443/ |
| User | admin |
| Password | fi3zv3cszf |
| FSID | 7f94d918-5133-11f1-9fb7-00155dc730bd |
| Mon IP | 172.21.204.100 |
| Network | 172.21.192.0/20 |
| Hostname | ASUSVIVO2026 |

---

## Architecture Overview

Ceph is a software-defined storage platform providing object, block, and file storage from a single distributed cluster built on **RADOS** (Reliable Autonomic Distributed Object Store).

| Daemon | Role |
|--------|------|
| MON (Monitor) | Maintains cluster state maps. Min 3 for production, 1 for WSL2 testing. |
| MGR (Manager) | Runtime metrics, Dashboard, REST API |
| OSD (Object Storage Device) | Stores data, handles replication and recovery |
| MDS (Metadata Server) | CephFS metadata (not needed for RBD/object) |

`cephadm` is the official deployment tool (Octopus+). It deploys Ceph daemons as containers via Podman, managed by systemd.

---

## Part 1 — WSL2 Environment Setup

### Step 0 — Configure wsl.conf (Do First)

WSL2 auto-generates `/etc/resolv.conf` with an internal nameserver that cannot resolve Red Hat CDN. Podman also requires `/run/udev` which WSL2 doesn't create. Fix both at boot:

```bash
sudo tee /etc/wsl.conf << 'EOF'
[boot]
systemd=true
command = mkdir -p /run/udev

[network]
generateResolvConf = false
EOF
```

Restart WSL from Windows PowerShell:

```powershell
wsl --shutdown
wsl -d RHEL9
```

### Step 1 — Fix DNS

```bash
# Remove auto-generated file
sudo chattr -i /etc/resolv.conf 2>/dev/null
sudo rm -f /etc/resolv.conf

# Set static DNS
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'

# Lock it
sudo chattr +i /etc/resolv.conf

# Verify
cat /etc/resolv.conf
curl -I http://google.com
```

---

## Part 2 — RHEL 9 Subscription and Repos

### Step 2 — Register RHEL 9

RHEL 9 uses Simple Content Access (SCA) — no pool attachment needed.

```bash
sudo subscription-manager register --username rhafilliated
# Note: attach --auto is deprecated in RHEL 9 — registration alone is sufficient

sudo subscription-manager repos \
  --enable=rhel-9-for-x86_64-baseos-rpms \
  --enable=rhel-9-for-x86_64-appstream-rpms
```

### Step 3 — Fix GPG Keys and CA Certificates

```bash
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
sudo dnf install -y ca-certificates
sudo update-ca-trust extract
sudo dnf clean all
sudo dnf makecache
```

---

## Part 3 — Install Prerequisites

### Step 4 — Install Base Packages

```bash
sudo dnf install -y python3 podman iputils bind-utils lvm2 ca-certificates
```

### Step 5 — Install EPEL and CRB

Required for Ceph dependencies (`libtcmalloc`, `libarrow`, `libparquet`, `liboath`):

```bash
# Install EPEL
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Enable CodeReady Builder
sudo /usr/bin/crb enable

# Install Ceph library dependencies
sudo dnf install -y gperftools-libs liboath arrow-libs parquet-libs
```

### Step 6 — Verify Podman Works

WSL2 kernel lacks nftables support — use `--network=host` to bypass netavark:

```bash
sudo mkdir -p /run/udev
podman run --rm --network=host hello-world
```

Expected: `Hello Podman World` output.

---

## Part 4 — Install cephadm

> **Do NOT use the GitHub raw URL** — it requires `cephadmlib` and will fail with `ModuleNotFoundError`.

### Step 7 — Add Ceph Reef Repo and Install

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

sudo dnf clean all
sudo dnf install -y cephadm ceph-common
```

---

## Part 5 — Bootstrap the Cluster

### Step 8 — Bootstrap

```bash
# Get WSL IP
hostname -I

# Bootstrap single-node cluster
sudo cephadm bootstrap \
  --mon-ip 172.21.204.100 \
  --skip-monitoring-stack \
  --single-host-defaults
```

Bootstrap takes 3-5 minutes. On success it prints the Dashboard URL and generated credentials.

---

## Part 6 — Post-Bootstrap Operations

### Access Ceph CLI

All Ceph commands must be run inside `cephadm shell` — the admin keyring is mounted there:

```bash
# Enter interactive shell
sudo cephadm shell

# Or run single commands
sudo cephadm shell -- ceph status
sudo cephadm shell -- ceph health
```

### Verify Cluster Health

```bash
sudo cephadm shell -- ceph status
sudo cephadm shell -- ceph health detail
```

### Create a Pool

```bash
sudo cephadm shell -- ceph osd pool create test-pool01 64
sudo cephadm shell -- ceph osd pool application enable test-pool01 rbd
```

### Create RBD Image

```bash
sudo cephadm shell -- rbd create test-image01 \
  --size 100G \
  --pool test-pool01 \
  --image-feature layering
```

### Create a Ceph Auth User

```bash
sudo cephadm shell -- ceph auth get-or-create client.test_client \
  mon 'profile rbd' \
  osd 'profile rbd pool=test-pool01' \
  -o /etc/ceph/ceph.client.test_client.keyring
```

### Add OSDs (Storage)

```bash
# List available block devices
sudo cephadm shell -- ceph orch device ls

# Add OSD (replace /dev/sdX with actual device)
sudo cephadm shell -- ceph orch daemon add osd ASUSVIVO2026:/dev/sdX
```

### Set Hostname for Cluster

```bash
sudo cephadm shell -- ceph orch apply mon --placement="ASUSVIVO2026"
```

### Enable Telemetry (Optional)

```bash
sudo cephadm shell -- ceph telemetry on
```

---

## Part 7 — Remote Desktop (xrdp + XFCE4)

### Install Desktop and xrdp

```bash
# Install XFCE desktop
sudo dnf groupinstall -y "Xfce"
sudo dnf install -y xorg-x11-xinit xorg-x11-server-Xorg

# Install xrdp (from EPEL)
sudo dnf install -y xrdp

# Enable and start
sudo systemctl enable xrdp xrdp-sesman
sudo systemctl start xrdp xrdp-sesman
```

### Fix xsession — Force X11 (Required for WSL2)

xfce4-session defaults to Wayland which crashes in Xvnc. Force X11:

```bash
printf '#!/bin/bash\nexport GDK_BACKEND=x11\nexport QT_QPA_PLATFORM=xcb\nexport XDG_SESSION_TYPE=x11\nexport XDG_CURRENT_DESKTOP=XFCE\nexport DESKTOP_SESSION=xfce\nunset WAYLAND_DISPLAY\nexec xfce4-session\n' > ~/.xsession
chmod +x ~/.xsession
```

### Disable Xorg in xrdp (Xorg fails in WSL2 — no /dev/dri)

```bash
sudo sed -i 's/^\[Xorg\]/#[Xorg]/' /etc/xrdp/xrdp.ini
sudo systemctl restart xrdp xrdp-sesman
```

### Connect via mstsc

```
mstsc → 172.21.204.100:3389
Session: Xvnc (NOT Xorg)
Username: filliat
```

---

## Part 8 — Install Browsers

### Firefox

```bash
sudo dnf install -y firefox
cp /usr/share/applications/firefox.desktop ~/Desktop/
chmod +x ~/Desktop/firefox.desktop
```

### Google Chrome

```bash
sudo tee /etc/yum.repos.d/google-chrome.repo << 'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

sudo dnf install -y google-chrome-stable
cp /usr/share/applications/google-chrome.desktop ~/Desktop/
chmod +x ~/Desktop/google-chrome.desktop
```

Chrome wrapper for WSL2 (required flags):

```bash
sudo tee /usr/local/bin/chrome << 'EOF'
#!/bin/bash
exec google-chrome-stable \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --no-first-run \
  "$@"
EOF
sudo chmod +x /usr/local/bin/chrome
```

Launch from terminal:

```bash
DISPLAY=:10 chrome &
```

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `cdn.redhat.com` not resolving | WSL auto-generates resolv.conf with internal IP | Lock resolv.conf, set `generateResolvConf=false` in wsl.conf |
| `statfs /run/udev: no such file` | WSL2 doesn't create /run/udev | `mkdir -p /run/udev` — add to wsl.conf boot command |
| `netavark: nftables error` | WSL2 kernel lacks nftables | Use `--network=host` and `--single-host-defaults` |
| `ModuleNotFoundError: cephadmlib` | GitHub raw cephadm is not standalone | Install via RPM repo at download.ceph.com |
| `cephadm add-repo 404` | No el9/el10 repo auto-detected | Manually create /etc/yum.repos.d/ceph-reef.repo |
| `SSL_ERROR_SYSCALL` on download.ceph.com | Missing CA certs | `dnf install -y ca-certificates && update-ca-trust extract` |
| `attach --auto` fails | Deprecated in RHEL 9 SCA | Registration alone is sufficient |
| `ceph auth permission denied` | Running ceph outside cephadm shell | Use `sudo cephadm shell -- ceph <command>` |
| Xorg fails in xrdp | No /dev/dri in WSL2 | Disable Xorg in xrdp.ini, use Xvnc only |
| xfce4-session SIGSEGV | Wayland/X11 GDK cast error | Set `GDK_BACKEND=x11` and `unset WAYLAND_DISPLAY` in ~/.xsession |
| mstsc error 0x708 | Stale Xvnc session lock | `pkill -f Xvnc && rm -f /tmp/.X10-lock && systemctl restart xrdp` |
| Chrome won't launch | Missing WSL2 flags | Use wrapper with `--no-sandbox --disable-gpu --disable-dev-shm-usage` |

---

## Key File Locations

| File | Purpose |
|------|---------|
| `/etc/ceph/ceph.conf` | Ceph cluster config |
| `/etc/ceph/ceph.client.admin.keyring` | Admin authentication keyring |
| `/etc/ceph/ceph.pub` | SSH public key |
| `/var/lib/ceph/<fsid>/` | Cluster data directory |
| `/etc/yum.repos.d/ceph-reef.repo` | Ceph package repo |
| `/etc/wsl.conf` | WSL2 boot and network config |
| `/etc/resolv.conf` | DNS config (locked with chattr +i) |
| `/etc/xrdp/xrdp.ini` | xrdp session type config |
| `~/.xsession` | User desktop session script |
| `~/.xsession-errors` | Desktop startup error log |
| `/var/log/xrdp-sesman.log` | xrdp session manager log |

---

## wsl.conf Reference

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
- cephadm Install: https://docs.ceph.com/en/reef/cephadm/install/
- Ceph RPM Downloads: https://download.ceph.com/rpm-reef/el9/
- Red Hat Developer: https://developers.redhat.com
- WSL2 systemd: https://learn.microsoft.com/en-us/windows/wsl/systemd
- xrdp project: https://github.com/neutrinolabs/xrdp

---

*Updated: May 18, 2026 | ASUSVIVO2026 | RHEL 9 WSL2 | Ceph 18.2.8 Reef*
