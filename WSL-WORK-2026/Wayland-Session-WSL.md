# Wayland Session in WSL (Ubuntu 24.04)

## Overview

WSLg (Windows Subsystem for Linux GUI) ships a built-in Wayland compositor (`weston`) that is active for every `wsl.exe`-launched shell. It provides a real `wayland-0` socket that Wayland-native apps can use.

This is **not** available inside xrdp/VNC/SSH sessions. Those sessions run an Xorg or Xvnc display (`:1`, `:2`, etc.) with no Wayland compositor.

---

## Environment Variables — What They Mean

| Variable | Correct value for Wayland | Symptom when wrong |
|---|---|---|
| `WAYLAND_DISPLAY` | `wayland-0` (real socket must exist) | `Failed to open Wayland display` |
| `DISPLAY` | `:0` (WSLg X11 mirror) | Apps fall back to X11 only |
| `XDG_SESSION_TYPE` | `wayland` | Apps skip Wayland codepath |
| `XDG_RUNTIME_DIR` | `/run/user/1000` | Socket not found |

Check all at once inside a WSL shell:

```bash
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "DISPLAY=$DISPLAY"
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
ls -la "$XDG_RUNTIME_DIR/wayland-0" 2>/dev/null || echo "socket missing"
```

---

## Method 1 — Launch a Single App from PowerShell (simplest)

Open a PowerShell or Windows Terminal window on Windows and run:

```powershell
wsl -d Ubuntu-24.04 -- firefox
```

WSLg sets `WAYLAND_DISPLAY=wayland-0` and `DISPLAY=:0` automatically. The app window appears on the Windows desktop through the WSLg compositor.

Other examples:

```powershell
wsl -d Ubuntu-24.04 -- nautilus
wsl -d Ubuntu-24.04 -- gedit
wsl -d Ubuntu-24.04 -- vlc
```

---

## Method 2 — Interactive WSL Shell, Then Launch Apps

Open a standard WSL shell (not SSH, not RDP) from PowerShell or Windows Terminal:

```powershell
wsl -d Ubuntu-24.04
```

> **Important:** This must be a shell opened by `wsl.exe` on Windows. If you opened the shell via `ssh filliat@localhost` or any other SSH path, WSLg environment variables are **not injected** — see [Troubleshoot: SSH session has empty WAYLAND_DISPLAY](#troubleshoot-ssh-session-has-empty-wayland_display-and-display0).

Verify the Wayland socket is available:

```bash
echo $WAYLAND_DISPLAY   # expect: wayland-0
echo $DISPLAY           # expect: :0
ls /run/user/1000/wayland-0
```

Launch apps:

```bash
firefox &
gnome-text-editor &
```

---

## Method 3 — Force Wayland Variables When Missing

If you are in a shell where the variables are unset (e.g. a login shell that did not inherit them), set them manually:

```bash
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DISPLAY=:0
firefox &
```

This only works if the WSLg socket actually exists at `/run/user/$(id -u)/wayland-0`. If the socket is missing, WSLg is not running — see the troubleshooting section.

---

## Persistent Wayland Export in ~/.bashrc

Add these lines to `~/.bashrc` so every interactive shell gets correct Wayland variables:

```bash
# WSLg Wayland support
if [ -S "/run/user/$(id -u)/wayland-0" ]; then
    export WAYLAND_DISPLAY=wayland-0
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    export DISPLAY=:0
    export XDG_SESSION_TYPE=wayland
fi
```

Apply immediately:

```bash
source ~/.bashrc
```

---

## Firefox Specific — Force Wayland or Force X11

### Force Firefox to use Wayland (when compositor is available)

```bash
export MOZ_ENABLE_WAYLAND=1
firefox &
```

### Force Firefox to use X11 (xrdp/VNC/SSH sessions — no compositor)

```bash
unset WAYLAND_DISPLAY
unset MOZ_ENABLE_WAYLAND
export GDK_BACKEND=x11
export DISPLAY=:1    # match your actual xrdp/VNC display
firefox &
```

Add to `~/.bashrc` to make it permanent for xrdp sessions:

```bash
# Inside xrdp VNC sessions — disable Wayland fallback for GTK apps
if [ "$XDG_SESSION_TYPE" = "x11" ] || [ -n "$XRDP_SESSION" ]; then
    unset WAYLAND_DISPLAY
    unset MOZ_ENABLE_WAYLAND
    export GDK_BACKEND=x11
fi
```

---

## Session Type Comparison

| Session type | `WAYLAND_DISPLAY` | `DISPLAY` | Wayland apps work? |
|---|---|---|---|
| `wsl.exe` shell (WSLg) | `wayland-0` (real socket) | `:0` | **Yes** |
| PowerShell `wsl -d Ubuntu-24.04 -- <app>` | `wayland-0` (real socket) | `:0` | **Yes** |
| xrdp → VNC → GNOME | empty or stale | `:1` | **No** — Xvnc, no compositor |
| SSH into WSL (`ssh filliat@localhost`) | **empty** | `:0` (unreachable) | **No** — WSLg not injected |
| Native Ubuntu desktop (GDM) | `wayland-0` (real) | `:0` | **Yes** |

Key symptom of SSH session: `WAYLAND_DISPLAY` is empty, `DISPLAY=:0` is set, but `firefox` or other GUI apps print `Error: cannot open display: :0`.

---

## Verify WSLg Compositor Is Running

From PowerShell:

```powershell
wsl -d Ubuntu-24.04 -- bash -lc "ls /mnt/wslg/"
```

Expected output (confirmed on Ubuntu-24.04 / WSLg):

```
PulseAudioRDPSink    distro          run          versions.txt
PulseAudioRDPSource  doc             runtime-dir  weston.log
PulseServer          pulseaudio.log  stderr.log   wlog.log
```

Key entries and what they confirm:

| Entry | Meaning |
|---|---|
| `runtime-dir/` | Contains `wayland-0` socket — Wayland compositor is live |
| `weston.log` | Weston compositor ran/is running |
| `PulseServer`, `PulseAudioRDP*` | Audio forwarding is active |
| `stderr.log`, `wlog.log` | WSLg startup logs (check here if compositor fails) |

From inside WSL:

```bash
ls /mnt/wslg/runtime-dir/
ls /run/user/$(id -u)/wayland-0   # socket must be present
ps aux | grep weston
```

---

## Troubleshoot: SSH Session Has Empty WAYLAND_DISPLAY and `cannot open display: :0`

**Symptom:**
```
$ echo $WAYLAND_DISPLAY   # (blank — nothing printed)
$ echo $DISPLAY
:0
$ firefox &
Error: cannot open display: :0
```

**Cause:** The shell was opened via SSH (`ssh filliat@localhost` or similar). WSLg only injects `WAYLAND_DISPLAY`, `DISPLAY`, and `XDG_RUNTIME_DIR` into shells started by `wsl.exe`. SSH sessions inherit none of these.

**Fix A — Launch directly from PowerShell (recommended):**

Close the SSH shell. Open PowerShell on Windows and run:

```powershell
wsl -d Ubuntu-24.04 -- firefox
```

Or open an interactive WSL shell the correct way:

```powershell
wsl -d Ubuntu-24.04
# now inside WSL:
echo $WAYLAND_DISPLAY    # wayland-0
firefox &
```

**Fix B — Forward the display inside SSH (if you must use SSH):**

Check whether the WSLg socket exists from inside the SSH session:

```bash
ls /run/user/$(id -u)/wayland-0   # socket must exist
ls /mnt/wslg/.X11-unix/X0         # X11 mirror socket
```

If both exist, manually export the variables in the SSH session:

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=wayland-0
export DISPLAY=:0
firefox &
```

If the sockets are missing, WSLg is not running at all — restart WSL from PowerShell:

```powershell
wsl --shutdown
Start-Sleep -Seconds 3
wsl -d Ubuntu-24.04
```

**Fix C — Use X11 via xrdp/VNC instead (for complex remote workflows):**

If you need a full remote desktop with GUI apps, use the xrdp/VNC path (see [WSL-Ubuntu24-GNOME-xRDP-Training-Guide.md](WSL-Ubuntu24-GNOME-xRDP-Training-Guide.md)) and force apps to X11:

```bash
unset WAYLAND_DISPLAY
export GDK_BACKEND=x11
export DISPLAY=:1
firefox &
```

---

## Troubleshoot: Socket Missing

If `wayland-0` socket is absent:

```bash
# Check that user runtime directory exists
ls /run/user/$(id -u)/

# Restart user session services
systemctl --user start xdg-user-dirs-update 2>/dev/null || true

# From PowerShell — restart WSL entirely to re-trigger WSLg
# (run on Windows, not inside WSL)
```

From PowerShell on Windows:

```powershell
wsl --shutdown
Start-Sleep -Seconds 3
wsl -d Ubuntu-24.04 -- bash -lc "ls /run/user/1000/wayland-0 && echo OK"
```

---

## GNOME Apps on Wayland via WSLg

Individual GNOME apps run fine under WSLg without a full GNOME session:

```bash
# Install a GNOME app
sudo apt-get install -y gnome-text-editor

# Launch with Wayland support (from a wsl.exe shell or PowerShell wsl -d)
gnome-text-editor &
```

A full GDM/GNOME session is not needed — WSLg provides the compositor.

---

## References

- Microsoft WSLg documentation: `https://github.com/microsoft/wslg`
- Firefox Wayland support: `MOZ_ENABLE_WAYLAND=1`
- Ubuntu 24.04 GNOME Wayland: GDM `custom.conf` must have `WaylandEnable` not set to `false`
