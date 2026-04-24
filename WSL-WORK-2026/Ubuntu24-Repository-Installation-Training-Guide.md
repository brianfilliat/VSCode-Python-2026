# Ubuntu 24 Repository Installation Training Guide

## Purpose

This guide standardizes third-party apt repository setup on Ubuntu 24.04 for these toolchains:

- Docker
- Visual Studio Code
- Microsoft Linux packages
- GitHub CLI
- NodeSource Node.js
- HashiCorp Terraform

It is written for Ubuntu 24.04 running either on bare metal, a VM, or WSL. The commands use current upstream repository methods instead of Ubuntu community mirror packages when the vendor provides an official repository.

## Scope

This document covers:

- prerequisite packages
- repository key and source configuration
- package installation
- validation commands
- common rollback and troubleshooting steps

This document does not cover:

- Docker Desktop for Windows
- VS Code Remote - WSL extension setup on Windows
- language-specific package managers such as `npm`, `pip`, or `cargo`

## Recommended Execution Model

Run repository setup as `root` or with `sudo`.

For WSL Ubuntu 24.04, root execution is usually simplest:

```bash
wsl.exe -d Ubuntu-24.04 -u root
```

If you are already inside Ubuntu as a standard user, prefix commands with `sudo`.

## Known-Good XRDP Path For This Workspace

This workspace also has a validated remote desktop path for `Ubuntu-24.04` on WSL:

- `xrdp` listens on `3390`
- backend path is `xrdp -> libvnc.so -> Xtigervnc :1`
- preferred Windows connection target is `127.0.0.1:3390`

Known-good connection steps:

```powershell
mstsc.exe /v:127.0.0.1:3390
```

At the xrdp login screen:

- session: `VNC - use VNC password`
- username: Ubuntu username
- password: the VNC password created by `vncpasswd`, not the Ubuntu account password

If `127.0.0.1:3390` does not connect, get the current WSL IP and use `<WSL_IP>:3390`:

```powershell
wsl.exe -d Ubuntu-24.04 -- hostname -I
mstsc.exe /v:<WSL_IP>:3390
```

If xrdp shows `Error connecting to user session`, first verify that the xrdp login password is the VNC password stored in `~/.vnc/passwd`.

## Baseline Preparation

Refresh package metadata and install the base tools used by the repository setup steps.

```bash
apt-get update
apt-get install -y ca-certificates curl gpg wget lsb-release apt-transport-https software-properties-common
install -m 0755 -d /etc/apt/keyrings
```

Confirm the OS codename and architecture before continuing.

```bash
. /etc/os-release
echo "$PRETTY_NAME"
echo "$VERSION_CODENAME"
dpkg --print-architecture
```

Expected Ubuntu 24.04 values:

- codename: `noble`
- architecture: usually `amd64`

## Repository Order

Apply repositories in this order to keep troubleshooting simple:

1. Docker
2. VS Code
3. Microsoft packages
4. GitHub CLI
5. NodeSource
6. HashiCorp

Run `apt-get update` after each repository is added so source-level problems are isolated to one change.

## Docker

Remove conflicting Ubuntu packages first if they exist.

```bash
apt-get remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc || true
```

Add Docker's official key and Deb822 source file.

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
cat >/etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt-get update
```

Install Docker Engine and the supported CLI plugins.

```bash
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Validate Docker.

```bash
docker --version
systemctl is-active docker
docker compose version
docker buildx version
docker run hello-world
```

Optional non-root access:

```bash
usermod -aG docker <your-username>
```

Note: group membership changes require a new login shell.

## Visual Studio Code

Use the official Microsoft VS Code repository instead of the Ubuntu `code` package if you want vendor updates.

Install the Microsoft signing key and Deb822 source.

```bash
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/usr/share/keyrings/microsoft.gpg
chmod a+r /usr/share/keyrings/microsoft.gpg
cat >/etc/apt/sources.list.d/vscode.sources <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
apt-get update
apt-get install -y code
```

Validate VS Code.

```bash
code --version
which code
```

WSL note: if your main workflow is Windows plus Remote - WSL, installing Windows VS Code is often the cleaner UX. This Linux package is still valid when you need a GUI application inside Ubuntu.

## Microsoft Linux Packages

This repository is separate from the VS Code repository. Use it for packages hosted on `packages.microsoft.com`, such as PowerShell and selected .NET packages.

Install the Ubuntu 24.04 repository configuration package.

```bash
cd /tmp
curl -sSL -O https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm -f packages-microsoft-prod.deb
apt-get update
```

Inspect available Microsoft packages.

```bash
apt-cache search microsoft | head
apt-cache search powershell
apt-cache search dotnet-sdk
```

Example installs:

```bash
apt-get install -y powershell
```

Validate the repository and package.

```bash
pwsh --version
grep -R "packages.microsoft.com" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null || true
```

## GitHub CLI

Use the official GitHub CLI apt repository. The upstream maintainers explicitly recommend the official Debian package feed instead of older community builds.

Add the keyring and source list.

```bash
mkdir -p -m 755 /etc/apt/keyrings
out=$(mktemp)
wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg
cat "$out" >/etc/apt/keyrings/githubcli-archive-keyring.gpg
rm -f "$out"
chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >/etc/apt/sources.list.d/github-cli.list
apt-get update
apt-get install -y gh
```

Validate GitHub CLI.

```bash
gh --version
gh auth status || true
```

## NodeSource Node.js

NodeSource currently supports Ubuntu 24.04 and still publishes setup scripts for active Node.js lines. For a stable default, use the LTS channel.

LTS install:

```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x -o /tmp/nodesource_setup.sh
bash /tmp/nodesource_setup.sh
apt-get install -y nodejs
rm -f /tmp/nodesource_setup.sh
```

If you need a specific channel, replace `setup_lts.x` with one of these:

- `setup_22.x`
- `setup_24.x` is not the documented script name; use `setup_current.x` for current
- `setup_current.x`

Validate Node.js.

```bash
node -v
npm -v
apt-cache policy nodejs
```

Optional build tools for native modules:

```bash
apt-get install -y build-essential
```

## HashiCorp Terraform

Add the HashiCorp keyring and repository, then install Terraform.

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
chmod a+r /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" >/etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install -y terraform
```

Validate Terraform.

```bash
terraform version
apt-cache policy terraform
```

## Quick Verification Block

After all repositories and packages are installed, this single block gives a fast health check.

```bash
set -e
docker --version
docker compose version
code --version
pwsh --version
gh --version
node -v
npm -v
terraform version
```

## Repository Audit Commands

Use these commands to confirm what was added.

```bash
ls -1 /etc/apt/sources.list.d
grep -R "download.docker.com\|packages.microsoft.com\|cli.github.com\|deb.nodesource.com\|apt.releases.hashicorp.com" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null || true
apt-cache policy docker-ce code gh nodejs terraform | sed -n '1,120p'
```

## Rollback

Remove packages:

```bash
apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin code powershell gh nodejs terraform
apt-get autoremove -y
```

Remove repository definitions:

```bash
rm -f /etc/apt/sources.list.d/docker.sources
rm -f /etc/apt/sources.list.d/vscode.sources
rm -f /etc/apt/sources.list.d/github-cli.list
rm -f /etc/apt/sources.list.d/hashicorp.list
rm -f /etc/apt/sources.list.d/nodesource.list
rm -f /etc/apt/sources.list.d/microsoft-prod.list
rm -f /etc/apt/sources.list.d/prod.list
rm -f /etc/apt/trusted.gpg.d/microsoft.gpg
rm -f /usr/share/keyrings/microsoft.gpg
rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
rm -f /etc/apt/keyrings/docker.asc
rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg
apt-get update
```

Note: Microsoft's config package may create repository files with names that vary by product channel. Verify actual filenames before deleting.

## Troubleshooting

If `apt-get update` fails:

1. Read the first failing repository line. Do not change multiple repos at once.
2. Confirm the key file exists and is world-readable.
3. Confirm the source file syntax is valid.
4. Confirm the Ubuntu codename is `noble`.
5. Run `apt-cache policy` on the failing package to confirm candidate visibility.

Useful diagnostics:

```bash
ls -l /etc/apt/keyrings /usr/share/keyrings
cat /etc/apt/sources.list.d/docker.sources
cat /etc/apt/sources.list.d/vscode.sources
cat /etc/apt/sources.list.d/github-cli.list
cat /etc/apt/sources.list.d/hashicorp.list
apt-get update
```

If Docker installs but commands fail:

```bash
systemctl status docker --no-pager
journalctl -u docker --no-pager -n 100
```

If `code` launches poorly in WSL GUI:

1. Verify WSLg or your X/desktop path is functional.
2. Prefer Windows VS Code plus Remote - WSL when you do not need a Linux-local GUI build.

If NodeSource installs an unexpected version:

1. Recheck whether you used `setup_lts.x` or `setup_current.x`.
2. Run `apt-cache policy nodejs` to confirm the candidate source.

## GNOME on Wayland (Ubuntu 24.04)

Use this section if you need a full GNOME session running on Wayland.

### Native Ubuntu (bare metal or VM)

Install GNOME and GDM if needed:

```bash
apt-get update
apt-get install -y ubuntu-desktop gdm3 gnome-shell gnome-session
```

Enable GDM and make sure Wayland is not disabled in GDM config:

```bash
systemctl enable gdm3
grep -n "^WaylandEnable" /etc/gdm3/custom.conf || true
sed -i 's/^WaylandEnable=false/#WaylandEnable=false/' /etc/gdm3/custom.conf
```

Reboot, then choose your session at the login screen:

1. Click the gear icon.
2. Select `Ubuntu` or `GNOME` (not `GNOME on Xorg`).
3. Sign in.

Validate that the session is Wayland:

```bash
echo "$XDG_SESSION_TYPE"
loginctl show-session "$(loginctl | awk '/tty|seat|pts/ {print $1; exit}')" -p Type
```

Expected value: `wayland`.

### WSL Ubuntu 24.04 note

For WSL, a full GNOME Wayland login manager session is generally not the recommended path:

- WSLg already provides Wayland support for individual Linux GUI apps.
- xrdp + VNC workflows typically run Xorg/Xvnc sessions, not native GNOME Wayland compositor sessions.

If your target is remote desktop inside WSL, keep using your current xrdp/VNC desktop path. If your target is local Linux desktop behavior, use a native Ubuntu install or VM with virtual GPU acceleration.

For the complete WSLg Wayland launch guide, environment variable reference, Firefox Wayland/X11 fix, and troubleshooting steps, see [Wayland-Session-WSL.md](Wayland-Session-WSL.md).

## Training Notes

Use this sequence during hands-on training:

1. Run baseline preparation.
2. Add one repository.
3. Run `apt-get update`.
4. Install one package.
5. Run the package validation command.
6. Record the source file and keyring path.
7. Repeat for the next repository.

That sequence keeps failures attributable to a single change.

## Optional Appendix: Google Chrome

If you also want the Google Chrome repository on Ubuntu 24.04, use a separate source file and verify its signing key independently. Keep Chrome isolated from the developer-tool repositories above so browser issues do not block core CLI tooling.
