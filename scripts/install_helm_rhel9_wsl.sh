#!/usr/bin/env bash
set -euo pipefail

# install_helm_rhel9_wsl.sh
# Installs Helm 3 on RHEL 9 running inside WSL2.
# Run inside the RHEL9 WSL distribution as a user with sudo.

# Ensure DNF and curl are available
if ! command -v dnf >/dev/null 2>&1; then
  echo "dnf not found. Are you running RHEL/CentOS/Fedora?"
  exit 1
fi

echo "Updating package metadata and installing prerequisites..."
sudo dnf -y makecache
sudo dnf -y install curl tar gzip

# Use the official Helm install script
HELM_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"

echo "Downloading and running Helm install script from ${HELM_INSTALL_SCRIPT_URL}"
curl -fsSL "${HELM_INSTALL_SCRIPT_URL}" -o /tmp/get_helm.sh
sudo chmod 700 /tmp/get_helm.sh
sudo /tmp/get_helm.sh

# Verify installation
if command -v helm >/dev/null 2>&1; then
  echo "Helm installed successfully:"
  helm version --short
else
  echo "Helm installation failed or helm not on PATH."
  exit 2
fi

# Cleanup
rm -f /tmp/get_helm.sh

echo "Done. Use 'helm version' to re-check."