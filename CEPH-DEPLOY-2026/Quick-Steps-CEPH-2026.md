# Ceph Cluster Setup — Quick Steps
**Date:** May 18, 2026   steps for deploying and configuring your Ceph storage cluster and provide a simplified guide for you.

1. Install cephadm repo and bootstrap first node
2. Copy SSH public key to all nodes
Add nodes to the cluster
List available devices on all nodes
Add all available disks as OSDs
Create rack buckets (Rack-01, Rack-02)
Move racks under root default
Assign hosts to racks
Export and edit CRUSH map (change type host → type rack)
Recompile and inject new CRUSH map
Create a pool
Initialize pool for RBD
Set replication size and min_size
Create RBD image on pool
Create auth keyring for client
Copy keyring and ceph.conf to client machine
Install ceph-common on client
Map the RBD image
Create filesystem on mapped device
Mount and write data
---

## 1. Bootstrap First Node

The file covers all 10 steps:

Bootstrap first node
Add nodes to cluster
Add OSDs (disks)
Configure rack failure domain
Update CRUSH map for rack-level replication
Create a pool
Create an RBD image
Create client auth keyring
Mount RBD image on client
Verify cluster health

```bash
# Install cephadm repo
dnf install -y centos-release-ceph-reef.noarch

# Bootstrap cluster on first node
cephadm bootstrap --mon-ip <MON_IP> --allow-fqdn-hostname
```

---

## 2. Add Nodes to Cluster

```bash
# Copy SSH public key to all nodes
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph02
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph03
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph04
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph05
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph06

# Add nodes to cluster
ceph orch host add ceph02 --labels _admin
ceph orch host add ceph03 --labels _admin
ceph orch host add ceph04 --labels _admin
ceph orch host add ceph05 --labels _admin
ceph orch host add ceph06 --labels _admin
```

---

## 3. Add OSDs (Storage Disks)

```bash
# List available devices on all nodes
ceph orch device ls

# Add all available disks automatically
ceph orch apply osd --all-available-devices
```

---

## 4. Configure Rack Failure Domain (HA)

```bash
# Create rack buckets
ceph osd crush add-bucket Rack-01 rack
ceph osd crush add-bucket Rack-02 rack

# Move racks under root default
ceph osd crush move Rack-01 root=default
ceph osd crush move Rack-02 root=default

# Assign hosts to Rack-01
ceph osd crush move ceph01 rack=Rack-01
ceph osd crush move ceph02 rack=Rack-01
ceph osd crush move ceph03 rack=Rack-01

# Assign hosts to Rack-02
ceph osd crush move ceph04 rack=Rack-02
ceph osd crush move ceph05 rack=Rack-02
ceph osd crush move ceph06 rack=Rack-02
```

---

## 5. Update CRUSH Map for Rack-Level Replication

```bash
# Export CRUSH map
ceph osd getcrushmap -o /tmp/crush.bin

# Decompile to text
crushtool -d /tmp/crush.bin -o /tmp/crush.txt

# Edit crush.txt — change 'type host' to 'type rack' in replicated_rule
# rule replicated_rule {
#     step chooseleaf firstn 0 type rack   <-- change this line
# }

# Recompile
crushtool -c /tmp/crush.txt -o /tmp/crush.new.bin

# Inject new map
ceph osd setcrushmap -i /tmp/crush.new.bin
```

---

## 6. Create a Pool

```bash
ceph osd pool create test-pool01 64
rbd pool init test-pool01

# Set replication (2 racks = size 2)
ceph osd pool set test-pool01 size 2
ceph osd pool set test-pool01 min_size 1
```

---

## 7. Create an RBD Image

```bash
rbd create test-image01 --size 100G --pool test-pool01 --image-feature layering
```

---

## 8. Create Client Auth Keyring

```bash
ceph auth get-or-create client.test_client \
  mon 'profile rbd' \
  osd 'profile rbd pool=test-pool01' \
  -o /etc/ceph/ceph.client.test_client.keyring
```

---

## 9. Mount RBD Image on Client

```bash
# Copy keyring and config to client
scp /etc/ceph/ceph.client.test_client.keyring ceph-client:/etc/ceph/.
scp /etc/ceph/ceph.conf ceph-client:/etc/ceph/.

# On client — install ceph-common
dnf install -y ceph-common

# Map the image
rbd map test-pool01/test-image01 --id test_client

# Create filesystem and mount
mkfs.xfs /dev/rbd0
mkdir /mnt/ceph-test
mount /dev/rbd0 /mnt/ceph-test/
```

---

## 10. Verify Cluster Health

```bash
ceph -s
ceph osd tree
ceph pg dump pgs_brief
```

---

## References

- Ceph Reef Docs: https://docs.ceph.com/en/reef/
- HA Ceph Design: https://medium.com/@satishdotpatel/deploy-high-availability-ceph-storage-design-4c6dc0d32e41

---

*Date: May 18, 2026 | Ceph 18.x Reef*
