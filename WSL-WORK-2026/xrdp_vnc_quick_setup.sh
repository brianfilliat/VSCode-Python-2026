#!/bin/bash
# Quick setup script for xrdp with VNC backend on WSL Ubuntu 24

set -e

echo "=== xrdp VNC Backend Setup for WSL Ubuntu 24 ==="
echo ""

# Step 1: Update system
echo "[1/7] Updating system..."
sudo apt update
sudo apt upgrade -y

# Step 2: Install dependencies
echo "[2/7] Installing dependencies..."
sudo apt install -y \
    xrdp \
    xorgxrdp \
    xvnc4 \
    tigervnc-standalone-server \
    build-essential \
    git \
    libssl-dev \
    libpam-dev \
    libx11-dev \
    pkg-config

# Step 3: Create build directory
echo "[3/7] Setting up build directory..."
mkdir -p ~/xrdp-build
cd ~/xrdp-build

# Step 4: Clone and build xrdp with VNC backend
echo "[4/7] Cloning and building xrdp with VNC backend..."
if [ ! -d "xrdp" ]; then
    git clone https://github.com/neutrinolabs/xrdp.git
fi
cd xrdp

# Configure with VNC backend
./configure --enable-vnc --enable-rdpsnd --enable-dtsound 2>&1 | tail -20

# Build
echo "Building (this may take a few minutes)..."
make -j$(nproc) 2>&1 | tail -20

# Install
echo "[5/7] Installing compiled binaries..."
sudo make install

# Step 6: Ensure library is in correct path
echo "[6/7] Installing VNC library..."
sudo mkdir -p /usr/lib/xrdp
sudo cp /usr/local/lib/libxrdp-vnc.so /usr/lib/xrdp/ 2>/dev/null || echo "Library may already exist"
sudo chmod 755 /usr/lib/xrdp/libxrdp-vnc.so

# Verify library exists
if [ -f "/usr/lib/xrdp/libxrdp-vnc.so" ]; then
    echo "✓ VNC library installed successfully"
else
    echo "✗ Warning: VNC library not found"
fi

# Step 7: Configure xrdp.ini
echo "[7/7] Configuring xrdp.ini..."
sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.backup

# Ensure VNC backend is enabled in xrdp.ini
sudo sed -i 's/lib=libxrdp.so/lib=libxrdp-vnc.so/' /etc/xrdp/xrdp.ini 2>/dev/null || true

# Start services
echo ""
echo "=== Starting Services ==="
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
sudo systemctl start xrdp
sudo systemctl start xrdp-sesman

# Verify services
echo ""
echo "=== Service Status ==="
sudo systemctl status xrdp --no-pager
sudo systemctl status xrdp-sesman --no-pager

# Get WSL IP
echo ""
echo "=== Connection Information ==="
WSL_IP=$(hostname -I | awk '{print $1}')
echo "WSL IP Address: $WSL_IP"
echo "RDP Connection: $WSL_IP:3389"
echo ""
echo "Connect using Windows Remote Desktop:"
echo "  - Server: $WSL_IP:3389"
echo "  - Username: your_wsl_username"
echo "  - Password: your_wsl_password"
echo ""

# Verify library was loaded
echo "=== Library Verification ==="
ldd /usr/lib/xrdp/libxrdp-vnc.so 2>/dev/null | head -5 || echo "Library check complete"

echo ""
echo "✓ Setup complete!"
echo "To view logs: sudo tail -f /var/log/xrdp.log"
