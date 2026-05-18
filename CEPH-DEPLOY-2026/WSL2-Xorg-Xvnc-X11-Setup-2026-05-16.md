# # In WSL terminal
pkill -f Xvnc
pkill -f xfce4-session
rm -f /tmp/.X10-lock
rm -f /run/xrdp/xrdp_display_10
sudo systemctl restart xrdp xrdp-sesman



## WSL2 — Xorg / Xvnc / X11 Remote Desktop Setup Guide
**Date:** May 16, 2026  
**Host:** ASUSVIVO2026 | RHEL 9 WSL2  
**Kernel:** Linux 6.6.114.1-microsoft-standard-WSL2  
**Goal:** Connect Windows mstsc (RDP) to XFCE desktop running in WSL2  
**Status:** ✅ Working — Xvnc + XFCE4 via xrdp on port 3389

---

## Architecture

```
Windows mstsc (RDP client)
        ↓ port 3389
    xrdp daemon (RHEL9 WSL2)
        ↓
    xrdp-sesman (session manager)
        ↓
    Xvnc :10 (X server — works in WSL2)
        ↓
    xfce4-session (desktop)
```

> **Xorg does NOT work in WSL2** — WSL2 has no `/dev/dri/card0` GPU device.  
> **Xvnc works** — it is a software X server with no GPU dependency.

---

## Why Xorg Fails in WSL2

**Error in `/root/.xorgxrdp.10.log`:**
```
(EE) open /dev/dri/card0: No such file or directory
(EE) No devices detected.
(EE) no screens found
(EE) Fatal server error: no screens found
```

WSL2 kernel does not expose `/dev/dri` — no DRM/KMS support. Xorg requires a GPU device
to initialize. This is a hard WSL2 limitation.

**Do not use Xorg session in xrdp on WSL2.**

---

## Prerequisites

### Install EPEL and Desktop

```bash
# Install EPEL repo
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo /usr/bin/crb enable

# Install xrdp
sudo dnf install -y xrdp

# Install XFCE desktop
sudo dnf groupinstall -y "Xfce"

# Install Xvnc (TigerVNC server)
sudo dnf install -y tigervnc-server

# Install X11 init
sudo dnf install -y xorg-x11-xinit xorg-x11-server-Xorg
```

---

## Configuration

### 1. Disable Xorg, Keep Xvnc in xrdp.ini

```bash
# Comment out the Xorg session block
sudo sed -i 's/^\[Xorg\]/#[Xorg]/' /etc/xrdp/xrdp.ini
sudo sed -i 's/^name=Xorg/#name=Xorg/' /etc/xrdp/xrdp.ini
sudo sed -i 's/^lib=libxup.so/#lib=libxup.so/' /etc/xrdp/xrdp.ini
```

Verify Xvnc block is active in `/etc/xrdp/xrdp.ini`:
```ini
[Xvnc]
name=Xvnc
lib=libvnc.so
username=ask
password=ask
port=-1
```

### 2. Fix ~/.xsession — Force X11 Backend

**Critical:** xfce4-session defaults to Wayland in RHEL 9, which causes a segfault in Xvnc.
Must force X11 backend explicitly.

```bash
# For user filliat
printf '#!/bin/bash\nexport GDK_BACKEND=x11\nexport QT_QPA_PLATFORM=xcb\nexport XDG_SESSION_TYPE=x11\nexport XDG_CURRENT_DESKTOP=XFCE\nexport DESKTOP_SESSION=xfce\nunset WAYLAND_DISPLAY\nexec xfce4-session\n' > /home/filliat/.xsession
chmod +x /home/filliat/.xsession

# For root
printf '#!/bin/bash\nexport GDK_BACKEND=x11\nexport QT_QPA_PLATFORM=xcb\nexport XDG_SESSION_TYPE=x11\nexport XDG_CURRENT_DESKTOP=XFCE\nexport DESKTOP_SESSION=xfce\nunset WAYLAND_DISPLAY\nexec xfce4-session\n' > /root/.xsession
chmod +x /root/.xsession
```

**Full `.xsession` content:**
```bash
#!/bin/bash
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export DESKTOP_SESSION=xfce
unset WAYLAND_DISPLAY
exec xfce4-session
```

### 3. Set DESKTOP_SESSION for xrdp

```bash
echo '[ -n "$XRDP_SESSION" ] && export DESKTOP_SESSION=xfce' | sudo tee /etc/profile.d/xrdp-desktop.sh
sudo chmod +x /etc/profile.d/xrdp-desktop.sh
```

### 4. Enable and Start xrdp

```bash
sudo systemctl enable xrdp xrdp-sesman
sudo systemctl start xrdp xrdp-sesman
sudo systemctl status xrdp
ss -tlnp | grep 3389
```

---

## WSL2 wsl.conf — Required Settings

`/etc/wsl.conf` must have systemd enabled and `/run/udev` created at boot:

```ini
[boot]
systemd=true
command = mkdir -p /run/udev

[network]
generateResolvConf = false
```

Apply by restarting WSL from PowerShell:
```powershell
wsl --shutdown
wsl -d RHEL9
```

---

## Connect from Windows

```
mstsc → 172.21.204.100:3389
```

In the xrdp login screen:
- **Module/Session:** `Xvnc` (select from dropdown — NOT Xorg)
- **Username:** `filliat` or `root`
- **Password:** your Linux password

---

## Known Issues & Fixes

### Issue 1 — Xorg: No screens found

**Error:**
```
(EE) open /dev/dri/card0: No such file or directory
(EE) no screens found
```
**Fix:** Disable Xorg in xrdp.ini. Use Xvnc only. See Configuration Step 1.

---

### Issue 2 — xfce4-session SIGSEGV (Wayland/X11 cast error)

**Error in `.xsession-errors`:**
```
(xfce4-session): GLib-GObject-WARNING: invalid cast from 'GdkWaylandDisplay' to 'GdkX11Display'
Window manager exited with signal SIGSEGV
```

**Cause:** RHEL 9 XFCE defaults to Wayland display backend. Xvnc is X11 only.

**Fix:** Set `GDK_BACKEND=x11` and `unset WAYLAND_DISPLAY` in `~/.xsession`. See Configuration Step 2.

---

### Issue 3 — Window manager exits immediately (SIGTERM)

**Error in sesman log:**
```
Window manager (pid XXXX) exited with signal SIGTERM
Window manager exited quickly (0 secs)
```

**Cause:** `~/.xsession` file was empty or missing — heredoc syntax fails in PowerShell.

**Fix:** Use `printf` instead of heredoc to write `.xsession`:
```bash
printf '#!/bin/bash\nexec xfce4-session\n' > ~/.xsession
chmod +x ~/.xsession
```

---

### Issue 4 — Xorg config file not found

**Error:**
```
(EE) Unable to locate/open config file: "xrdp/xorg.conf"
```

**Cause:** xrdp-sesman looks for `/etc/xrdp/xrdp/xorg.conf` which doesn't exist in WSL2.

**Fix:** Not needed — switch to Xvnc which doesn't require xorg.conf.

---

### Issue 5 — ICE/Unix socket errors

**Error in `.xsession-errors`:**
```
_IceTransmkdir: ERROR: euid != 0, directory /tmp/.ICE-unix will not be created
```

**Cause:** Harmless warning in WSL2 — ICE socket directory permissions.

**Fix:** Not required — session still works. Can suppress with:
```bash
sudo mkdir -p /tmp/.ICE-unix
sudo chmod 1777 /tmp/.ICE-unix
```

---

### Issue 6 — DPMS extension missing

**Error:**
```
Xlib: extension "DPMS" missing on display ":10.0"
```

**Cause:** Xvnc does not implement the DPMS (power management) extension.

**Fix:** Harmless — no action needed. Does not affect desktop functionality.

---

## Troubleshooting Commands

```bash
# In WSL terminal
pkill -f Xvnc
pkill -f xfce4-session
rm -f /tmp/.X10-lock
rm -f /run/xrdp/xrdp_display_10
sudo systemctl restart xrdp xrdp-sesman

# Check xrdp service status
sudo systemctl status xrdp xrdp-sesman

# Check port 3389 is listening
ss -tlnp | grep 3389

# Check sesman log (main troubleshooting source)
sudo tail -40 /var/log/xrdp-sesman.log

# Check xsession errors (desktop startup errors)
cat ~/.xsession-errors | tail -30

# Check Xorg log (if Xorg was attempted)
cat ~/.xorgxrdp.10.log | tail -30

# Check running xrdp/xfce processes
ps aux | grep -E 'xfce|xrdp|Xvnc' | grep -v grep

# Restart xrdp
sudo systemctl restart xrdp xrdp-sesman
wsl -d RHEL9 -e bash -c "sudo pkill -f Xvnc; sudo pkill -f xfce4-session; sudo systemctl restart xrdp xrdp-sesman; echo 'Done'"
wsl -d RHEL9 -e bash -c "sudo systemctl restart xrdp xrdp-sesman 2>&1; echo done"
172.21.204.100:3389

#
## Type 172.21.204.100:3389 — do not use mstsc /admin or mstsc /console.


```

---

## Verify Working Session

When working correctly, `ps aux` shows:

```
Xvnc :10 -auth .Xauthority -geometry 1920x1080 ...   ← X server running
xfce4-session                                          ← desktop session
xfce4-panel                                            ← taskbar
xfce4-power-manager                                    ← power manager
xrdp-chansrv                                           ← RDP channel server
```

And sesman log shows:
```
[INFO] X server :10 is working
[INFO] Starting window manager for display :10
[INFO] Session in progress on display :10. Waiting until the window manager exits...
```
(No "Session finished" line — session stays open)

---

## Key File Locations

| File | Purpose |
|------|---------|
| `/etc/xrdp/xrdp.ini` | xrdp session types (Xvnc/Xorg config) |
| `/etc/xrdp/sesman.ini` | Session manager config |
| `/usr/libexec/xrdp/startwm.sh` | Window manager startup script |
| `/usr/libexec/xrdp/startwm-bash.sh` | Bash wrapper for startwm.sh |
| `~/.xsession` | User desktop session script |
| `~/.xsession-errors` | Desktop startup error log |
| `/var/log/xrdp-sesman.log` | Session manager log (main debug source) |
| `/etc/profile.d/xrdp-desktop.sh` | Sets DESKTOP_SESSION for xrdp |
| `/etc/wsl.conf` | WSL2 boot and network config |

---

## WSL2 X11 Limitations Summary

| Feature | Xorg | Xvnc | Notes |
|---------|------|------|-------|
| Works in WSL2 | ❌ | ✅ | Xorg needs /dev/dri |
| GPU acceleration | N/A | ❌ | Software rendering only |
| DPMS power mgmt | N/A | ❌ | Not implemented in Xvnc |
| Wayland support | N/A | ❌ | Must force GDK_BACKEND=x11 |
| RDP via xrdp | ❌ | ✅ | Use Xvnc session type |
| Resolution | N/A | ✅ | Set in xrdp.ini geometry |

---

## References

- xrdp project: https://github.com/neutrinolabs/xrdp
- TigerVNC: https://tigervnc.org
- XFCE: https://xfce.org
- WSL2 systemd: https://learn.microsoft.com/en-us/windows/wsl/systemd

---

*Date: May 16, 2026 | Host: ASUSVIVO2026 | RHEL 9 WSL2 | xrdp + Xvnc + XFCE4*


# In WSL terminal
pkill -f Xvnc
pkill -f xfce4-session
rm -f /tmp/.X10-lock
rm -f /run/xrdp/xrdp_display_10
sudo systemctl restart xrdp xrdp-sesman
