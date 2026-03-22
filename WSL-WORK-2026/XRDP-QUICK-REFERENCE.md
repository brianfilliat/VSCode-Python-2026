# XRDP + GNOME on WSL Ubuntu 24 (VNC Backend) - Quick Reference

## Scope
- Host: Windows + WSL2
- Guest: Ubuntu-24.04
- Remote protocol: RDP via xrdp on port 3390
- Desktop: GNOME
- Backend path: xrdp -> libvnc.so -> Xtigervnc :1 (127.0.0.1:5901)

## One-Time Setup

### 1) Confirm WSL distro and systemd
```powershell
wsl --list --verbose
wsl -d Ubuntu-24.04 -- systemctl is-system-running
```

### 2) Install packages
```bash
sudo apt update
sudo apt install -y \
  xrdp xorgxrdp tigervnc-standalone-server \
  ubuntu-desktop-minimal gnome-session dbus-x11 x11-xkb-utils
```

### 3) Prepare user desktop session
```bash
echo 'gnome-session --session=ubuntu' > ~/.xsession
chmod +x ~/.xsession
[ -f ~/.xinitrc ] && mv ~/.xinitrc ~/.xinitrc.bak
vncpasswd
```

### 4) Create GNOME startup wrapper for VNC display :1
```bash
sudo tee /usr/local/bin/start-vnc-gnome.sh > /dev/null << 'EOF'
#!/bin/bash
set -euo pipefail

export USER=filliat
export HOME=/home/filliat
export LOGNAME=filliat
export DISPLAY=:1
export XAUTHORITY=/home/filliat/.Xauthority
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_SESSION_DESKTOP=ubuntu
export DESKTOP_SESSION=ubuntu
export GNOME_SHELL_SESSION_MODE=ubuntu
export GDK_BACKEND=x11
export XDG_RUNTIME_DIR=/run/user/1000

cleanup() {
  if [[ -n "${gnome_pid:-}" ]] && kill -0 "$gnome_pid" 2>/dev/null; then
    kill "$gnome_pid" 2>/dev/null || true
    wait "$gnome_pid" 2>/dev/null || true
  fi
  if [[ -n "${vnc_pid:-}" ]] && kill -0 "$vnc_pid" 2>/dev/null; then
    kill "$vnc_pid" 2>/dev/null || true
    wait "$vnc_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

/usr/bin/install -d -m 700 "$HOME/.vnc"
rm -f /tmp/.X1-lock

/usr/bin/Xtigervnc :1 -rfbport 5901 -nolisten unix -SecurityTypes VncAuth \
  -rfbauth "$HOME/.vnc/passwd" -geometry 1280x800 -depth 24 &
vnc_pid=$!

ready=0
for _ in $(seq 1 20); do
  if /usr/bin/xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done

if [[ "$ready" -ne 1 ]]; then
  echo "Xtigervnc did not become ready on $DISPLAY" >&2
  exit 1
fi

/usr/bin/dbus-run-session -- /usr/bin/gnome-session --session=ubuntu &
gnome_pid=$!

wait -n "$vnc_pid" "$gnome_pid"
exit $?
EOF
sudo chmod 755 /usr/local/bin/start-vnc-gnome.sh
```

### 5) Create persistent service
```bash
sudo tee /etc/systemd/system/xtigervnc-direct.service > /dev/null << 'EOF'
[Unit]
Description=Direct TigerVNC server with GNOME desktop for xrdp VNC backend
After=network.target systemd-user-sessions.service
Wants=network.target
ConditionPathExists=/home/filliat/.vnc/passwd

[Service]
Type=simple
User=filliat
Group=filliat
WorkingDirectory=/home/filliat
Environment=HOME=/home/filliat
Environment=USER=filliat
Environment=LOGNAME=filliat
Environment=XDG_RUNTIME_DIR=/run/user/1000
ExecStartPre=/usr/bin/install -d -m 700 -o filliat -g filliat /home/filliat/.vnc
ExecStartPre=/usr/bin/install -d -m 700 -o filliat -g filliat /run/user/1000
ExecStart=/usr/local/bin/start-vnc-gnome.sh
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
```

### 6) Configure xrdp.ini for VNC backend only
```bash
sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak
sudo cp ~/path/to/xrdp.ini.sample /etc/xrdp/xrdp.ini
```

### 7) Enable and start services
```bash
sudo systemctl daemon-reload
sudo systemctl enable xtigervnc-direct.service
sudo systemctl enable xrdp xrdp-sesman
sudo systemctl restart xtigervnc-direct.service
sudo systemctl restart xrdp-sesman
sudo systemctl restart xrdp
```

### 8) Prevent GNOME unlock-auth failures in remote session
```bash
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
gsettings set org.gnome.desktop.session idle-delay 0
```

## Validate
```bash
systemctl is-active xtigervnc-direct.service
systemctl is-active xrdp
systemctl is-active xrdp-sesman
ss -ltnp | grep -E '3390|5901'
pgrep -af 'start-vnc-gnome|Xtigervnc|gnome-session|gnome-shell'
```

## Connect
1. Get WSL IP: `hostname -I`
2. From Windows: `mstsc.exe /v:<WSL_IP>:3390`
3. xrdp login:
   - Session: `VNC`
   - Username: Linux username
   - Password: Linux account password

## Troubleshooting (Fast)
- Black screen:
  - `sudo systemctl restart xtigervnc-direct.service xrdp-sesman xrdp`
  - verify GNOME processes with `pgrep -af gnome-shell`
- Password field on lock screen does not work:
  - check logs for `Failed to open reauthentication channel`
  - re-run the three `gsettings` commands above
- `vncserver` fails with `_XSERVTransSocketCreateListener`:
  - do not use `vncserver` wrapper in this workflow
  - use `xtigervnc-direct.service` only

## Security
- Do not hardcode Linux account credentials in `/etc/xrdp/xrdp.ini`
- Keep `username=ask` and `password=ask` in session entries
- Use SSH key auth for remote shell access when possible
