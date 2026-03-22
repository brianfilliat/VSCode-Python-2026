# WSL Ubuntu 24 + GNOME + xRDP (VNC Backend) - Complete Start-to-Finish SOP

## Purpose
This document is the definitive, repeatable deployment guide for Ubuntu 24.04 in WSL using xRDP with GNOME through a direct TigerVNC backend.

## Architecture
- Client: Windows Remote Desktop (`mstsc`)
- RDP service: `xrdp` on TCP 3390
- Backend module: `libvnc.so`
- Display server: `Xtigervnc :1` on TCP 5901
- Desktop session: `gnome-session --session=ubuntu`
- Process supervisor: `systemd` service `xtigervnc-direct.service`

## Preconditions
- Windows has WSL2 enabled
- Distro exists: `Ubuntu-24.04`
- User account exists in Ubuntu (example: `filliat`)

## Step 1 - Verify WSL + Ubuntu
```powershell
wsl --list --verbose
wsl -d Ubuntu-24.04 -- uname -a
wsl -d Ubuntu-24.04 -- systemctl is-system-running
```

## Step 2 - Install OS Dependencies
```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
  xrdp xorgxrdp tigervnc-standalone-server \
  ubuntu-desktop-minimal gnome-session dbus-x11 x11-xkb-utils
```

## Step 3 - Prepare User Session
```bash
echo 'gnome-session --session=ubuntu' > ~/.xsession
chmod +x ~/.xsession
[ -f ~/.xinitrc ] && mv ~/.xinitrc ~/.xinitrc.bak
vncpasswd
```

## Step 4 - Install the VNC + GNOME Startup Wrapper
Create `/usr/local/bin/start-vnc-gnome.sh` with the exact content from [XRDP-QUICK-REFERENCE.md](XRDP-QUICK-REFERENCE.md).

## Step 5 - Install Persistent Service
Create `/etc/systemd/system/xtigervnc-direct.service` with the exact content from [XRDP-QUICK-REFERENCE.md](XRDP-QUICK-REFERENCE.md).

## Step 6 - Configure xrdp
Use the minimal VNC-only `xrdp.ini` from [xrdp.ini.sample](xrdp.ini.sample), then apply:
```bash
sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak
sudo cp /path/to/xrdp.ini.sample /etc/xrdp/xrdp.ini
```

## Step 7 - Enable and Start Services
```bash
sudo systemctl daemon-reload
sudo systemctl enable xtigervnc-direct.service
sudo systemctl enable xrdp xrdp-sesman
sudo systemctl restart xtigervnc-direct.service
sudo systemctl restart xrdp-sesman
sudo systemctl restart xrdp
```

## Step 8 - Disable Remote Lock/Unlock Reauth Loop
This resolves the known GNOME unlock prompt issue (`No session available`) in this environment.
```bash
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
gsettings set org.gnome.desktop.session idle-delay 0
```

## Step 9 - Validation Gate (Must Pass)
```bash
systemctl is-active xtigervnc-direct.service
systemctl is-active xrdp
systemctl is-active xrdp-sesman
ss -ltnp | grep -E '3390|5901'
pgrep -af 'start-vnc-gnome|Xtigervnc|gnome-session|gnome-shell'
```
Expected:
- all service checks return `active`
- `xrdp` listening on 3390
- `Xtigervnc` listening on 5901
- GNOME session and shell running

## Step 10 - Connect From Windows
```powershell
wsl -d Ubuntu-24.04 -- hostname -I
mstsc.exe /v:<WSL_IP>:3390
```
At xrdp login:
- Session: `VNC`
- Username: Ubuntu username
- Password: Ubuntu account password

## Known Errors and Definitive Fixes

### A) Black screen after login
Cause: VNC running but GNOME session not started.
Fix:
```bash
sudo systemctl restart xtigervnc-direct.service xrdp-sesman xrdp
pgrep -af 'gnome-session|gnome-shell'
```

### B) Password field on GNOME lock screen does not accept input
Cause: GNOME reauthentication channel fails in this WSL/VNC path.
Symptom in logs: `Failed to open reauthentication channel ... No session available`.
Fix: apply Step 8 and reconnect.

### C) `vncserver` wrapper fails with `_XSERVTransSocketCreateListener`
Cause: WSL socket behavior with wrapper path.
Fix: do not use `vncserver` wrapper; use `xtigervnc-direct.service` only.

### D) xrdp connects but no desktop updates
Fix:
```bash
sudo journalctl -u xtigervnc-direct.service -n 80 --no-pager
sudo tail -n 80 /var/log/xrdp.log
sudo tail -n 80 /var/log/xrdp-sesman.log
```

## Full Recovery (Clean Runtime Reset)
```powershell
wsl --shutdown
```
```bash
sudo systemctl daemon-reload
sudo systemctl restart xtigervnc-direct.service
sudo systemctl restart xrdp-sesman
sudo systemctl restart xrdp
```

## Optional SSH
```bash
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
systemctl is-active ssh
```

## End State
A stable, repeatable Ubuntu 24 WSL remote desktop workflow with GNOME over xrdp (VNC backend), persistent service startup, and lock-screen/input failure mitigation.
