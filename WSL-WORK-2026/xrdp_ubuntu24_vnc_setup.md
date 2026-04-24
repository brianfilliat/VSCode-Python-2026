# Ubuntu 24 WSL xRDP VNC Backend Setup (Validated)

This file mirrors the production flow used in this workspace:
- direct `Xtigervnc :1` managed by `xtigervnc-direct.service`
- GNOME launched by `/usr/local/bin/start-vnc-gnome.sh`
- xrdp configured with `libvnc.so` to `127.0.0.1:5901`

## Install
```bash
sudo apt update
sudo apt install -y xrdp xorgxrdp tigervnc-standalone-server ubuntu-desktop gnome-session dbus-x11 x11-xkb-utils mesa-utils gedit
```

## User prep
```bash
echo 'gnome-session --session=ubuntu' > ~/.xsession
chmod +x ~/.xsession
vncpasswd
```

## Deploy runtime files
- Use script content in `XRDP-QUICK-REFERENCE.md` for `/usr/local/bin/start-vnc-gnome.sh`
- Use service content in `XRDP-QUICK-REFERENCE.md` for `/etc/systemd/system/xtigervnc-direct.service`
- Use `xrdp.ini.sample` for `/etc/xrdp/xrdp.ini`

## Start services
```bash
sudo systemctl daemon-reload
sudo systemctl enable xtigervnc-direct.service xrdp xrdp-sesman
sudo systemctl restart xtigervnc-direct.service xrdp-sesman xrdp
```

## Input/auth stability fix
```bash
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
gsettings set org.gnome.desktop.session idle-delay 0
```

## Verify
```bash
systemctl is-active xtigervnc-direct.service
systemctl is-active xrdp
systemctl is-active xrdp-sesman
ss -ltnp | grep -E '3390|5901'
pgrep -af 'start-vnc-gnome|Xtigervnc|gnome-session|gnome-shell'
```

## Connect
```powershell
mstsc.exe /v:127.0.0.1:3390
```
Session in xrdp login: `VNC`

Use the VNC password created with `vncpasswd` for the xrdp login prompt. Do not use the Linux account password for this VNC-backed session.

## Known issue note
If GNOME shows an unlock/password prompt that does not accept input, this is usually a GNOME reauthentication channel issue in this remote path, not an `xkbcomp` compilation failure.

## Wayland in this session

This setup is **X11/Xvnc only**. There is no Wayland compositor on the `Xtigervnc :1` display.

If an app (Firefox, GNOME apps) prints `Failed to open Wayland display`, unset the variable and force X11:

```bash
unset WAYLAND_DISPLAY
unset MOZ_ENABLE_WAYLAND
export GDK_BACKEND=x11
<app> &
```

Persistent fix in `~/.bashrc`:

```bash
if [ -n "$XRDP_SESSION" ] || [ "$DISPLAY" = ":1" ]; then
    unset WAYLAND_DISPLAY
    unset MOZ_ENABLE_WAYLAND
    export GDK_BACKEND=x11
fi
```

For real Wayland (WSLg), launch from PowerShell instead:

```powershell
wsl -d Ubuntu-24.04 -- firefox
```

See [Wayland-Session-WSL.md](Wayland-Session-WSL.md) for the full WSLg Wayland guide.

## DRI3 / libEGL Warning

Symptom when launching GNOME apps (e.g. `gnome-control-center`) inside this xRDP session:

```
libEGL warning: DRI3 error: Could not get DRI3 device
libEGL warning: Ensure your X server supports DRI3 to get accelerated rendering
```

Cause: `Xtigervnc :1` has no DRI3/GPU path. This is expected. Apps continue via Mesa llvmpipe.

Verify:

```bash
sudo apt install -y mesa-utils
glxinfo -B | grep -E "OpenGL renderer|OpenGL vendor"
# Expected: Mesa / llvmpipe
```

Persistent fix — append to `~/.xsessionrc`:

```bash
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
export GSK_RENDERER=cairo
export QT_XCB_FORCE_SOFTWARE_OPENGL=1
```

Restart after editing:

```bash
sudo systemctl restart xtigervnc-direct.service xrdp-sesman xrdp
```

### Other gnome-control-center warnings (harmless in WSL)

- `Error connecting to ModemManager … timed out` — no modem in WSL; fix: `sudo apt install -y modemmanager`
- `No gedit is installed here` — not in `ubuntu-desktop-minimal`; fix: `sudo apt install -y gedit`
- `WEBKIT_DISABLE_COMPOSITING_MODE=1` env var is not related to DRI3 and not needed.
