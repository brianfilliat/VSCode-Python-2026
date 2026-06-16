# OpenStack on RHEL 9 — Installation and Configuration Guide

**Date**: 2026  
**System**: Red Hat Enterprise Linux 9 (RHEL 9)  
**Method**: Packstack (All-in-One) / Red Hat OpenStack Platform (RHOSP)

## Overview

This guide covers installing OpenStack on RHEL 9 using **Packstack** for single-node all-in-one deployments and **Red Hat OpenStack Platform (RHOSP)** for production environments.

> ⚠️ **RHEL 9 Subscription Required** — A valid Red Hat subscription is needed to access OpenStack packages. Use a developer subscription (free) at https://developers.redhat.com/

---

## Core OpenStack Services

| Service | Code Name | Description |
|---------|-----------|-------------|
| Compute | Nova | Manage virtual machines |
| Networking | Neutron | Virtual networks and IPs |
| Object Storage | Swift | Unstructured object storage |
| Block Storage | Cinder | Persistent block volumes |
| Image | Glance | VM images registry |
| Identity | Keystone | Authentication and authorization |
| Dashboard | Horizon | Web UI console |
| Orchestration | Heat | Infrastructure as code |

---

## Prerequisites

### 1. System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 4 cores (VT-x/AMD-v) | 8+ cores |
| RAM | 16 GB | 32 GB |
| Disk | 50 GB | 100 GB |
| OS | RHEL 9.x | RHEL 9.3+ |
| Network | 1 NIC | 2 NICs |

### 2. Verify RHEL 9 Subscription

```bash
# Register system with Red Hat
sudo subscription-manager register --username <rh-username> --password <rh-password>

# Attach subscription
sudo subscription-manager attach --auto

# Verify subscription
sudo subscription-manager status
```

### 3. Enable Required Repositories

```bash
# Enable RHEL 9 base repos
sudo subscription-manager repos \
  --enable=rhel-9-for-x86_64-baseos-rpms \
  --enable=rhel-9-for-x86_64-appstream-rpms

# Enable OpenStack repo (Antelope = OpenStack 2023.1)
sudo subscription-manager repos \
  --enable=openstack-17-tools-for-rhel-9-x86_64-rpms
  openstack-17-tools-for-rhel-9-x86_64-rpms

# Verify enabled repos
sudo subscription-manager repos --list-enabled
```

### 4. System Preparation

```bash
# Update all packages
sudo dnf update -y

# Install essential tools
sudo dnf install -y vim curl wget net-tools git python3 python3-pip --allowerasing --skip-broken --nobest
# Disable firewalld (Packstack manages its own rules)
sudo systemctl disable --now firewalld

# do not disable NetworkManager (use network scripts instead)
systemctl enable --now NetworkManager
systemctl status NetworkManager
nmcli device status

nmcli device status
nmcli connection up eth0

# Enable network service
systemctl install --now network
sudo systemctl enable --now network
# Only if legacy network-scripts is absolutely required
dnf install network-scripts
systemctl enable --now network


# Disable SELinux temporarily (re-enable after install)
sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# Verify hostname resolves to IP
hostname
hostname -I
ASUSVIVO2026
172.21.204.100 
```

### 5. Set Static IP and Hostname

```bash
# Set hostname
sudo hostnamectl set-hostname ASUSVIVO2026.openstack.local

# Edit /etc/hosts
sudo tee -a /etc/hosts << 'EOF'
172.21.204.100   ASUSVIVO2026.openstack.local openstack
EOF

# Verify
ping -c 2 ASUSVIVO2026.openstack.local
```

---

## Method 1: Packstack (All-in-One — Dev/Test)

Packstack installs all OpenStack services on a single node using Puppet manifests.

### Step 1 — Install Packstack
# Create RDO repo file manually
cat > /etc/yum.repos.d/rdo-openstack.repo << 'EOF'
[rdo-openstack]
name=RDO OpenStack Caracal for RHEL 9
baseurl=https://mirror.stream.centos.org/SIGs/9-stream/cloud/x86_64/openstack-caracal/
enabled=1
gpgcheck=0
EOF

# Refresh metadata
dnf clean all
dnf makecache

# Verify repo shows up
dnf repolist | grep rdo

```bash
# Install OpenStack client and Packstack
sudo dnf install -y python3-openstackclient openstack-packstack
subscription-manager repos --list | grep -i packstack
dnf install -y https://repos.fedorapeople.org/repos/openstack/openstack-antelope/rdo-release-antelope-1.el9.noarch.rpm
dnf install -y python3-openstackclient openstack-packstack


# 2. Enable RHOSP 17 Tools repo (provides python3-openstackclient)
subscription-manager repos --enable=openstack-17-tools-for-rhel-9-x86_64-rpms


# Verify installation
packstack --version
```

### Step 2 — Generate Answer File

```bash
# Generate default answer file
packstack --gen-answer-file=/root/packstack-answers.txt

# Review and edit key settings
sudo vim /root/packstack-answers.txt
```

Key settings to configure in the answer file:

```ini
# Set the controller IP
CONFIG_CONTROLLER_HOST=172.21.204.100

# Set compute node IP (same for all-in-one)
CONFIG_COMPUTE_HOSTS=172.21.204.100

# Set network node IP
CONFIG_NETWORK_HOSTS=172.21.204.100

# Admin password
CONFIG_KEYSTONE_ADMIN_PW=$Time9fly

# Enable/disable services
CONFIG_HORIZON_INSTALL=y
CONFIG_HEAT_INSTALL=y
CONFIG_CINDER_INSTALL=y
CONFIG_SWIFT_INSTALL=n

# Nova network or Neutron (use Neutron)
CONFIG_NEUTRON_INSTALL=y

# Neutron ML2 plugin
CONFIG_NEUTRON_ML2_TYPE_DRIVERS=vxlan,flat
CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES=vxlan

# External network interface
CONFIG_NEUTRON_OVS_BRIDGE_IFACES=br-ex:eth1
```

### Step 3 — Run Packstack

```bash
# All-in-one installation (uses answer file)
grep -E "CONFIG_DEFAULT_PASSWORD|CONFIG_CONTROLLER_HOST|CONFIG_COMPUTE_HOSTS|CONFIG_NETWORK_HOSTS|CONFIG_STORAGE_HOST" /root/packstack-answers.txt
sed -i 's/CONFIG_DEFAULT_PASSWORD=.*/CONFIG_DEFAULT_PASSWORD=YourPassword123/' /root/packstack-answers.txt

packstack --answer-file=/root/packstack-answers.txt

```

Or run with defaults (quickest):

```bash
sudo packstack --allinone
```

> ⚠️ Installation takes 30–60 minutes. Do not interrupt.

Expected final output:
```
Please check log file /var/tmp/packstack/20260611-171229-ihcsle8h/openstack-setup.log for more information
tail /var/tmp/packstack/20260611-171229-ihcsle8h/openstack-setup.log
sudo dnf install python3-openstackclient
 **** Installation completed successfully ******

Additional information:
 * A new answerfile was created in: /root/packstack-<timestamp>.txt
 * Time synchronization installation was skipped.
 * File /etc/profile.d/openstack-credentials.sh was created
 * To use the command line tools you need to source the file /root/keystonerc_admin
 * To use the Horizon web interface access http://172.21.204.100/dashboard
 * The installation log file is available at: /var/tmp/packstack/...
```

### Step 4 — Load Admin Credentials

```bash
# Load admin environment variables
source /root/keystonerc_admin

# Verify access
openstack token issue
openstack service list
```

---

## Method 2: Manual Installation (Production)

For production multi-node deployments on RHEL 9.

### Node Layout

| Role | Services |
|------|---------|
| Controller | Keystone, Glance, Nova API, Neutron, Horizon, Heat |
| Compute | Nova Compute, Neutron Agent |
| Storage | Cinder, Swift |

### Step 1 — Install MariaDB (Controller)

```bash
sudo dnf install -y mariadb mariadb-server python3-PyMySQL

sudo systemctl enable --now mariadb

# Secure the installation
sudo mysql_secure_installation
```

Configure MariaDB for OpenStack:

```bash
sudo tee /etc/my.cnf.d/openstack.cnf << 'EOF'
[mysqld]
bind-address = 192.168.1.100
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

sudo systemctl restart mariadb
```

### Step 2 — Install RabbitMQ

```bash
sudo dnf install -y rabbitmq-server

sudo systemctl enable --now rabbitmq-server

# Add OpenStack user
sudo rabbitmqctl add_user openstack <rabbit-password>
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"
```

### Step 3 — Install Memcached

```bash
sudo dnf install -y memcached python3-memcached

# Configure to listen on controller IP
sudo sed -i 's/127.0.0.1/192.168.1.100/' /etc/sysconfig/memcached

sudo systemctl enable --now memcached
```

### Step 4 — Install Keystone (Identity)

```bash
# Create Keystone database
mysql -u root -p << 'EOF'
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '<keystone-db-password>';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '<keystone-db-password>';
EOF

# Install Keystone packages
sudo dnf install -y openstack-keystone httpd python3-mod_wsgi

# Configure Keystone
sudo vim /etc/keystone/keystone.conf
```

```ini
[database]
connection = mysql+pymysql://keystone:<keystone-db-password>@192.168.1.100/keystone

[token]
provider = fernet
```

```bash
# Populate Keystone database
sudo keystone-manage db_sync

# Initialize Fernet keys
sudo keystone-manage fernet_setup \
  --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup \
  --keystone-user keystone --keystone-group keystone

# Bootstrap Keystone
sudo keystone-manage bootstrap \
  --bootstrap-password <admin-password> \
  --bootstrap-admin-url http://192.168.1.100:5000/v3/ \
  --bootstrap-internal-url http://192.168.1.100:5000/v3/ \
  --bootstrap-public-url http://192.168.1.100:5000/v3/ \
  --bootstrap-region-id RegionOne

# Configure Apache for Keystone
echo "ServerName 192.168.1.100" | sudo tee -a /etc/httpd/conf/httpd.conf
sudo ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

sudo systemctl enable --now httpd
```

### Step 5 — Install Glance (Image)

```bash
# Create Glance database
mysql -u root -p << 'EOF'
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '<glance-db-password>';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '<glance-db-password>';
EOF

# Create Glance service user
source /root/keystonerc_admin
openstack user create --domain default --password <glance-password> glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://192.168.1.100:9292
openstack endpoint create --region RegionOne image internal http://192.168.1.100:9292
openstack endpoint create --region RegionOne image admin http://192.168.1.100:9292

# Install Glance
sudo dnf install -y openstack-glance

# Populate database
sudo glance-manage db_sync

sudo systemctl enable --now openstack-glance-api
```

### Step 6 — Install Nova (Compute)

```bash
# Create Nova databases
mysql -u root -p << 'EOF'
CREATE DATABASE nova_api;
CREATE DATABASE nova;
CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '<nova-db-password>';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '<nova-db-password>';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '<nova-db-password>';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '<nova-db-password>';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '<nova-db-password>';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '<nova-db-password>';
EOF

# Install Nova packages
sudo dnf install -y openstack-nova-api openstack-nova-conductor \
  openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-compute

# Populate Nova databases
sudo nova-manage api_db sync
sudo nova-manage cell_v2 map_cell0
sudo nova-manage cell_v2 create_cell --name=cell1 --verbose
sudo nova-manage db sync

# Enable Nova services
sudo systemctl enable --now \
  openstack-nova-api \
  openstack-nova-scheduler \
  openstack-nova-conductor \
  openstack-nova-novncproxy \
  openstack-nova-compute
```

### Step 7 — Install Neutron (Networking)

```bash
# Install Neutron packages
sudo dnf install -y openstack-neutron openstack-neutron-ml2 \
  openstack-neutron-openvswitch ebtables

# Enable Open vSwitch
sudo systemctl enable --now openvswitch

# Enable Neutron services
sudo systemctl enable --now \
  neutron-server \
  neutron-openvswitch-agent \
  neutron-dhcp-agent \
  neutron-metadata-agent \
  neutron-l3-agent
```

---

## Accessing OpenStack

### Web Dashboard (Horizon)

- URL: `http://192.168.1.100/dashboard`
- Domain: `Default`
- Admin login: `admin` / `<admin-password>`

### OpenStack CLI

```bash
# Load admin credentials
source /root/keystonerc_admin

# Or create credentials file manually
cat > ~/openstack-credentials.sh << 'EOF'
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=<admin-password>
export OS_AUTH_URL=http://192.168.1.100:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

source ~/openstack-credentials.sh

# Verify
openstack token issue
openstack service list
```

---

## Upload RHEL 9 Cloud Image

```bash
# Download RHEL 9 cloud image (requires RH account)
# https://access.redhat.com/downloads/content/rhel

# Or use CirrOS for testing
wget http://download.cirros-cloud.net/0.5.2/cirros-0.5.2-x86_64-disk.img

# Upload image to Glance
openstack image create "cirros-0.5.2" \
  --file cirros-0.5.2-x86_64-disk.img \
  --disk-format qcow2 \
  --container-format bare \
  --public

# Upload RHEL 9 image
openstack image create "RHEL-9" \
  --file rhel-9-x86_64-kvm.qcow2 \
  --disk-format qcow2 \
  --container-format bare \
  --public

# Verify
openstack image list
```

---

## Post-Installation: Create Demo Resources

```bash
source /root/keystonerc_admin

# Create demo project and user
openstack project create --domain default demo
openstack user create --domain default --password <demo-password> demo
openstack role add --project demo --user demo member

# Create flavors
openstack flavor create --ram 512  --disk 1  --vcpus 1 m1.tiny
openstack flavor create --ram 2048 --disk 20 --vcpus 2 m1.small
openstack flavor create --ram 4096 --disk 40 --vcpus 4 m1.medium

# Create external network
openstack network create --external \
  --provider-physical-network extnet \
  --provider-network-type flat public

openstack subnet create public-subnet \
  --network public \
  --subnet-range 192.168.100.0/24 \
  --allocation-pool start=192.168.100.10,end=192.168.100.100 \
  --gateway 192.168.100.1 \
  --no-dhcp

# Create private network
openstack network create private
openstack subnet create private-subnet \
  --network private \
  --subnet-range 10.0.0.0/24

# Create router
openstack router create main-router
openstack router set --external-gateway public main-router
openstack router add subnet main-router private-subnet

# Create key pair
openstack keypair create admin-key > admin-key.pem
chmod 600 admin-key.pem

# Create security group
openstack security group create allow-ssh-http
openstack security group rule create --proto tcp --dst-port 22 allow-ssh-http
openstack security group rule create --proto tcp --dst-port 80 allow-ssh-http
openstack security group rule create --proto icmp allow-ssh-http

# Launch test instance
openstack server create \
  --flavor m1.tiny \
  --image cirros-0.5.2 \
  --network private \
  --key-name admin-key \
  --security-group allow-ssh-http \
  test-instance

# Assign floating IP
FIP=$(openstack floating ip create public -f value -c floating_ip_address)
openstack server add floating ip test-instance $FIP
echo "Instance accessible at: $FIP"

# SSH to instance
ssh -i admin-key.pem cirros@$FIP
```

---

## Service Management

```bash
# Check all OpenStack service status
for svc in openstack-nova-api openstack-nova-compute openstack-nova-scheduler \
           openstack-nova-conductor openstack-glance-api \
           neutron-server neutron-openvswitch-agent \
           openstack-keystone httpd mariadb rabbitmq-server memcached; do
  echo -n "$svc: "
  systemctl is-active $svc
done

# Restart all OpenStack services
sudo systemctl restart \
  httpd \
  openstack-nova-api \
  openstack-nova-compute \
  openstack-nova-scheduler \
  openstack-nova-conductor \
  openstack-nova-novncproxy \
  openstack-glance-api \
  neutron-server \
  neutron-openvswitch-agent \
  neutron-dhcp-agent \
  neutron-l3-agent \
  neutron-metadata-agent

# View service logs
sudo journalctl -u openstack-nova-api -f
sudo journalctl -u neutron-server -f
sudo journalctl -u openstack-glance-api -f
```

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Packstack fails on repo | Subscription not active | Run `subscription-manager attach --auto` |
| `openstack` command not found | Credentials not sourced | `source /root/keystonerc_admin` |
| Horizon 500 error | Apache/Keystone issue | `sudo systemctl restart httpd` |
| Instance stuck in BUILD | Nova compute not running | `sudo systemctl restart openstack-nova-compute` |
| No network connectivity | Neutron agent down | `sudo systemctl restart neutron-openvswitch-agent` |
| SSH timeout to instance | Security group or floating IP | Check `openstack security group list` |
| MariaDB connection refused | DB not started | `sudo systemctl start mariadb` |

### Common Debug Commands

```bash
# Verify OpenStack endpoints
openstack endpoint list

# Check Nova compute services
openstack compute service list

# Check Neutron agents
openstack network agent list

# Check Keystone catalog
openstack catalog list

# View detailed Nova logs
sudo tail -f /var/log/nova/nova-api.log
sudo tail -f /var/log/nova/nova-compute.log

# View Neutron logs
sudo tail -f /var/log/neutron/server.log
sudo tail -f /var/log/neutron/openvswitch-agent.log

# View Keystone/Apache logs
sudo tail -f /var/log/httpd/keystone_wsgi_main_error_log

# Check MariaDB
mysql -u root -p -e "SHOW DATABASES;"
```

---

## Best Practices

1. **Subscriptions** — keep RHEL subscription active for security patches
2. **SELinux** — re-enable SELinux in enforcing mode after installation and test
3. **Firewall** — configure firewalld rules properly instead of disabling it in production
4. **Passwords** — use strong unique passwords for each service database user
5. **NTP** — sync time across all nodes with Chrony (`sudo dnf install -y chrony`)
6. **Backups** — regularly back up MariaDB databases and Glance image store
7. **Monitoring** — use Gnocchi/Ceilometer for resource monitoring
8. **HA** — use HAProxy + Pacemaker for production high-availability deployments

---

## Useful Resources

- **RHOSP Docs**: https://access.redhat.com/documentation/en-us/red_hat_openstack_platform
- **OpenStack on RHEL**: https://docs.openstack.org/install-guide/
- **Packstack Docs**: https://wiki.openstack.org/wiki/Packstack
- **Red Hat Developer Account**: https://developers.redhat.com/register
- **RHEL 9 Cloud Images**: https://access.redhat.com/downloads/content/rhel
- **OpenStack CLI Ref**: https://docs.openstack.org/python-openstackclient/latest/

---

*Last Updated: 2026 | Status: Active*
