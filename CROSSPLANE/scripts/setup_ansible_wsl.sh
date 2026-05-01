#!/usr/bin/env bash
# Setup Ansible in WSL (Ubuntu)
# Usage: sudo bash setup_ansible_wsl.sh [--install-ceph]

set -euo pipefail

INSTALL_CEPH=false
for arg in "$@"; do
  case "$arg" in
    --install-ceph) INSTALL_CEPH=true ;;
    -h|--help)
      echo "Usage: sudo bash setup_ansible_wsl.sh [--install-ceph]"
      exit 0 ;;
  esac
done

if [ "$EUID" -ne 0 ]; then
  echo "This script should be run with sudo (it will install system packages)." >&2
  exit 1
fi

echo "Updating apt and installing prerequisites..."
apt update -y
apt upgrade -y
apt install -y python3 python3-venv python3-pip build-essential ssh ca-certificates apt-transport-https curl gnupg

if [ "$INSTALL_CEPH" = true ]; then
  echo "Installing ceph-common (ceph CLI) from distro repos..."
  apt install -y ceph-common || true
fi

USER_HOME=$(eval echo "~$SUDO_USER")
VENV_DIR="$USER_HOME/.ansible-venv"
echo "Creating Python venv at $VENV_DIR for user $SUDO_USER"
sudo -u "$SUDO_USER" python3 -m venv "$VENV_DIR"
sudo -u "$SUDO_USER" bash -lc "source $VENV_DIR/bin/activate && python -m pip install --upgrade pip setuptools wheel && pip install ansible"

echo "Installing common Ansible collections (community.general)..."
sudo -u "$SUDO_USER" bash -lc "source $VENV_DIR/bin/activate && ansible-galaxy collection install community.general --force || true"

echo "Verifying ansible installation..."
if sudo -u "$SUDO_USER" bash -lc "source $VENV_DIR/bin/activate && ansible --version >/dev/null 2>&1"; then
  VER_LINE=$(sudo -u "$SUDO_USER" bash -lc "source $VENV_DIR/bin/activate && ansible --version | head -n1")
  echo "Ansible verification: OK — $VER_LINE"
else
  echo "Ansible verification: FAILED — 'ansible --version' returned an error." >&2
  echo "You can try to activate the venv and run 'pip install ansible' as the unprivileged user:" >&2
  echo "  sudo -u $SUDO_USER bash -lc 'source $VENV_DIR/bin/activate && pip install --upgrade pip && pip install ansible'" >&2
fi

echo
echo "Ansible installation complete. To use it, run:" 
echo "  source $VENV_DIR/bin/activate"
echo "  ansible --version"
echo
echo "If you installed ceph-common, ensure you have network/cluster access to Ceph hosts."

exit 0
