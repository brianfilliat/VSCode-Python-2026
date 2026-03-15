#!/bin/bash
# Postfix Local SMTP Setup Script for Ubuntu 20.04

# 1. Install Postfix and mailutils
sudo DEBIAN_FRONTEND=noninteractive apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix mailutils

# 2. Configure Postfix with domain localhost.com
sudo postconf -e "myhostname = localhost.com"
sudo postconf -e "mydestination = localhost.com, localhost"
sudo systemctl restart postfix

# 3. Ensure the local user 'hackerearth' exists
if ! id "hackerearth" &>/dev/null; then
	sudo useradd -m hackerearth
fi

# 4. Send a test mail to the local user 'hackerearth'
echo "Hello HackerEarth!" | mail -s "Test Mail" hackerearth@localhost.com
