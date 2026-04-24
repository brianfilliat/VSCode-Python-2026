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
  ubuntu-desktop-minimal gnome-session dbus-x11 x11-xkb-utils \
  mesa-utils gedit
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
mstsc.exe /v:127.0.0.1:3390
```
At xrdp login:
- Session: `VNC`
- Username: Ubuntu username
- Password: VNC password created by `vncpasswd` and stored in `~/.vnc/passwd`

If `127.0.0.1:3390` does not work on your host, connect to the WSL IP shown by `hostname -I` on port `3390`.

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

If `xrdp.log` shows `loaded module 'libvnc.so' ok` followed by `Error connecting to user session`, first verify that the xrdp login password is the VNC password from `vncpasswd`, not the Linux account password.

### E) libEGL / DRI3 warning when launching GNOME apps
Symptom:
```
libEGL warning: DRI3 error: Could not get DRI3 device
libEGL warning: Ensure your X server supports DRI3 to get accelerated rendering
```
Cause: The `Xtigervnc :1` display has no DRI3/GPU path. Any app that probes for hardware EGL (gnome-control-center, gnome-tweaks, etc.) will print this warning. The app continues to run via CPU-side Mesa (llvmpipe).
Fix: See **DRI3 / libEGL Warning Resolution** section below — force software rendering globally for this session.

### F) gnome-control-center: ModemManager timeout
Symptom:
```
cc-wwan-panel: WARNING: Error connecting to ModemManager:
  Error calling StartServiceByName for org.freedesktop.ModemManager1:
  Failed to activate service 'org.freedesktop.ModemManager1': timed out (service_start_timeout=25000ms)
```
Cause: WSL has no cellular modem hardware. The WWAN (mobile broadband) panel in gnome-control-center always times out. Harmless — the panel remains empty.
Fix: None required. If the 25-second startup delay is disruptive, install the package so the service exists (even if it has nothing to manage):
```bash
sudo apt install -y modemmanager
sudo systemctl enable --now ModemManager
```

### G) gnome-control-center: No gedit installed
Symptom:
```
cc-ubuntu-panel: WARNING: No gedit is installed here. Colors won't be updated.
```
Cause: `ubuntu-desktop-minimal` omits gedit. The Ubuntu appearance panel uses gedit to sync editor color schemes. The rest of gnome-control-center is unaffected.
Fix:
```bash
sudo apt install -y gedit
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

---

## Wayland vs This Session (X11/VNC)

This entire SOP runs on an **X11/Xvnc path**. The display is `Xtigervnc :1` and all session variables are forced to X11:

```bash
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11
export DISPLAY=:1
```

There is **no Wayland compositor** in this path. `WAYLAND_DISPLAY` is not set and should not be set here.

### Problem: apps that try Wayland will fail

GTK4 apps (Firefox, GNOME Files, etc.) may auto-detect a stale `WAYLAND_DISPLAY` environment variable and crash or print:

```
Error: Failed to open Wayland display, fallback to X11. WAYLAND_DISPLAY='wayland-0' DISPLAY=':1'
```

Fix — force X11 for any app that shows this error inside this xrdp session:

```bash
unset WAYLAND_DISPLAY
unset MOZ_ENABLE_WAYLAND
export GDK_BACKEND=x11
```

Add to `~/.bashrc` so it applies automatically every time inside the xrdp/VNC desktop:

```bash
# xrdp/VNC path is X11 only — suppress Wayland fallback errors
if [ -n "$XRDP_SESSION" ] || [ "$DISPLAY" = ":1" ]; then
    unset WAYLAND_DISPLAY
    unset MOZ_ENABLE_WAYLAND
    export GDK_BACKEND=x11
fi
```

### To run apps in a real Wayland session (WSLg)

Do not use the xrdp window for this. Open PowerShell on Windows and launch directly:

```powershell
wsl -d Ubuntu-24.04 -- firefox
wsl -d Ubuntu-24.04 -- nautilus
```

WSLg provides a real `wayland-0` socket and renders the window natively on the Windows desktop. See [Wayland-Session-WSL.md](Wayland-Session-WSL.md) for the full guide.

---

## DRI3 / libEGL Warning Resolution

### Root cause

`Xtigervnc :1` is a pure software X11 display. It has no DRI3 device node and no GPU-accelerated EGL path. Any app that probes for hardware EGL will print:

```
libEGL warning: DRI3 error: Could not get DRI3 device
libEGL warning: Ensure your X server supports DRI3 to get accelerated rendering
```

The app still runs but falls back to Mesa llvmpipe (CPU software renderer). These warnings are **expected and harmless** in this xRDP/VNC stack; no action is strictly required if the app loads.

### Verification

Confirm Mesa/llvmpipe is active (run inside the xRDP GNOME terminal as `filliat`):

```bash
glxinfo -B | grep -E "OpenGL renderer|OpenGL vendor"
```

Expected output:

```
OpenGL vendor string: Mesa
OpenGL renderer string: llvmpipe (LLVM 20.1.2, 256 bits)
```

If `glxinfo` is not installed:

```bash
sudo apt install -y mesa-utils
```

If running from root or SSH (no display access), supply the user context explicitly:

```bash
sudo -u filliat env DISPLAY=:1 XAUTHORITY=/home/filliat/.Xauthority \
  glxinfo -B | grep -E "OpenGL renderer|OpenGL vendor"
```

### Silence warnings and enforce software rendering

Add the following block to `~/.xsessionrc` (loaded by the X session before GNOME starts):

```bash
# xRDP/VNC path has no DRI3 — force Mesa software rendering for all GUI apps
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
export GSK_RENDERER=cairo
export QT_XCB_FORCE_SOFTWARE_OPENGL=1
```

Apply and restart:

```bash
cat >> ~/.xsessionrc << 'EOF'

# xRDP/VNC path has no DRI3 — force Mesa software rendering for all GUI apps
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
export GSK_RENDERER=cairo
export QT_XCB_FORCE_SOFTWARE_OPENGL=1
EOF

sudo systemctl restart xtigervnc-direct.service xrdp-sesman xrdp
```

### One-shot launch (without restarting services)

Test a specific app immediately with software rendering:

```bash
LIBGL_ALWAYS_SOFTWARE=1 MESA_LOADER_DRIVER_OVERRIDE=llvmpipe GSK_RENDERER=cairo \
  gnome-control-center
```

### Additional gnome-control-center warnings in WSL

Even after the DRI3 fix, `gnome-control-center` may log two more benign warnings:

| Warning | Cause | Fix |
|---|---|---|
| `Error connecting to ModemManager … timed out` | No cellular modem in WSL; WWAN panel times out after 25 s | `sudo apt install -y modemmanager` (optional) |
| `No gedit is installed here. Colors won't be updated.` | gedit absent from `ubuntu-desktop-minimal` | `sudo apt install -y gedit` |

Neither prevents gnome-control-center from functioning. The app opens and all panels except WWAN work normally.

**Note:** `WEBKIT_DISABLE_COMPOSITING_MODE=1` does not affect DRI3 warnings — it is a WebKit-only compositor hint and is not needed here.

### What is NOT possible in this stack

| Feature | xRDP/Xtigervnc `:1` | WSLg (wsl -- app) |
|---|---|---|
| DRI3 GPU acceleration | No | Yes (via WSLg dxgkrnl) |
| Hardware EGL | No | Yes |
| Wayland compositor | No | Yes (weston) |
| OpenGL renderer | llvmpipe (CPU) | D3D12/virgl (GPU) |

For GPU-accelerated rendering, run the app directly through WSLg from PowerShell:

```powershell
wsl -d Ubuntu-24.04 -- gnome-control-center
```
