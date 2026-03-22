# Ubuntu 24 WSL xRDP VNC Backend Setup (Validated)

This file mirrors the production flow used in this workspace:
- direct `Xtigervnc :1` managed by `xtigervnc-direct.service`
- GNOME launched by `/usr/local/bin/start-vnc-gnome.sh`
- xrdp configured with `libvnc.so` to `127.0.0.1:5901`

## Install
```bash
sudo apt update
sudo apt install -y xrdp xorgxrdp tigervnc-standalone-server ubuntu-desktop-minimal gnome-session dbus-x11 x11-xkb-utils
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
mstsc.exe /v:<WSL_IP>:3390
```
Session in xrdp login: `VNC`

## Known issue note
If GNOME shows an unlock/password prompt that does not accept input, this is usually a GNOME reauthentication channel issue in this remote path, not an `xkbcomp` compilation failure.
