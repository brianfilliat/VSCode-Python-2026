# Simplified Ceph Storage Cluster Deployment Guide

This guide outlines the essential steps for deploying a Ceph storage cluster using `cephadm`, based on the provided documentation. It is a simplified overview and assumes a basic understanding of Linux command-line operations and network configuration.

## 1. Prepare Your Nodes (Prerequisites)

Perform these steps on all nodes intended for your Ceph cluster (e.g., `ceph0`, `ceph1`, `ceph2`).

### 1.1 Configure DNS Resolution
Ensure all nodes can resolve each other's hostnames and IP addresses. You might need to update `/etc/hosts` or configure a DNS server.

```bash
# Example: Verify DNS resolution (replace with your hostnames/IPs)
nslookup ceph0.manohar.in 192.168.0.200
nslookup ceph1.manohar.in 192.168.0.200
nslookup ceph2.manohar.in 192.168.0.200
```

### 1.2 Configure Passwordless SSH
Set up SSH keys for passwordless communication between `ceph0` (your administration node) and all other Ceph nodes. Generate an SSH key pair on `ceph0` and copy the public key to all other nodes.

```bash
# On ceph0:
ssh-keygen

# On all nodes (from ceph0, replace with your hostnames):
ssh-copy-id root@ceph0
ssh-copy-id root@ceph1
ssh-copy-id root@ceph2
```

### 1.3 Configure NTP Synchronization
Ensure all nodes have synchronized time using NTP. This example uses `chronyd`.

```bash
# On all nodes:
sed 's/^pool/#&/' -i /etc/chrony.conf
echo -e "pool 192.168.0.30 iburst \nallow 192.168.0.0/24 " >> /etc/chrony.conf
systemctl enable chronyd
systemctl restart chronyd
```

### 1.4 Install Cephadm
Install the `cephadm` utility and common Ceph client tools on all nodes.

```bash
# On all nodes:
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
chmod +x cephadm
./cephadm add-repo --release quincy
./cephadm install
./cephadm install ceph-common
```

## 2. Bootstrap the Ceph Cluster

Run the bootstrap command on your designated administration node (e.g., `ceph0`). This initializes the cluster and sets up the initial monitor and manager services.

```bash
cephadm bootstrap \
  --mon-ip 192.168.0.30 \
  --initial-dashboard-user "ceph-admin" \
  --initial-dashboard-password "ADMIN_123" \
  --dashboard-password-noupdate \
  --cluster-network=192.168.0.0/24 \
  --allow-fqdn-hostname
```

## 3. Add Additional Hosts to the Cluster

After bootstrapping, add your other Ceph nodes to the cluster and assign them roles.

### 3.1 Copy Ceph SSH Key
Copy the Ceph public SSH key from the bootstrap node (`ceph0`) to the newly added hosts for secure communication.

```bash
# On ceph0:
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph1
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph2
```

### 3.2 Add Hosts to Orchestrator
Add the remaining nodes to the Ceph orchestrator inventory.

```bash
# On ceph0:
ceph orch host add ceph1.manohar.in 192.168.0.31
ceph orch host add ceph2.manohar.in 192.168.0.32
```

### 3.3 Apply Service Labels
Assign appropriate labels to your hosts for services like monitors (mon), managers (mgr), and OSDs (osd-node).

```bash
# On ceph0:
ceph orch host label add ceph0.manohar.in osd-node
ceph orch host label add ceph1.manohar.in osd-node
ceph orch host label add ceph2.manohar.in osd-node

ceph orch host label add ceph0.manohar.in mon
ceph orch host label add ceph1.manohar.in mon
ceph orch host label add ceph2.manohar.in mon

ceph orch host label add ceph0.manohar.in mgr
ceph orch host label add ceph1.manohar.in mgr
ceph orch host label add ceph2.manohar.in mgr
```

## 4. Add OSD Disks and Create Storage Pools

Once the basic cluster is up and hosts are added, you can deploy OSDs (Object Storage Daemons) on available disks and create storage pools.

### 4.1 Deploy OSDs
Cephadm can automatically discover and deploy OSDs on unmanaged disks. You can use `ceph orch device ls` to list available devices and `ceph orch osd create` to deploy OSDs.

```bash
# On ceph0 (example to list devices):
ceph orch device ls

# On ceph0 (example to deploy OSDs on all available devices on osd-nodes):
ceph orch apply osd --all-available-devices
```

### 4.2 Create Storage Pools
Create a storage pool for your data. Replace `my_pool` with your desired pool name and adjust parameters as needed.

```bash
# On ceph0 (example to create a replicated pool):
ceph osd pool create my_pool 64 64 replicated

# On ceph0 (example to create an erasure coded pool - more advanced):
ceph osd pool create ec_pool 64 64 erasure
```

## 5. Verify Cluster Health

Regularly check the health of your Ceph cluster.

```bash
# On ceph0:
ceph health detail
ceph -s
```

This completes the simplified deployment steps. Further configuration, such as setting up CephFS or integrating with other platforms, would follow these initial steps.
