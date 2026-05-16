subscription-manager
repos
cephtools 9 for rh10
GPG keys public/private
sudo ./cephadm install ceph-common

# Verify SCA is active
sudo subscription-manager status

# List available repos
sudo subscription-manager repos --list

# Enable base repos needed for Ceph
sudo subscription-manager repos \
  --enable=rhel-9-for-x86_64-baseos-rpms \
  --enable=rhel-9-for-x86_64-appstream-rpms
sudo subscription-manager repos --list | grep -i ceph
Repo ID:   rhceph-9-tools-for-rhel-10-x86_64-debug-rpms
Repo Name: Red Hat Ceph Storage Tools 9 for RHEL 10 x86_64 (Debug RPMs)
Repo URL:  https://cdn.redhat.com/content/dist/layered/rhel10/x86_64/rhceph-tools/9/debug  
Repo ID:   rhceph-9-tools-for-rhel-10-x86_64-rpms
Repo Name: Red Hat Ceph Storage Tools 9 for RHEL 10 x86_64 (RPMs)
Repo URL:  https://cdn.redhat.com/content/dist/layered/rhel10/x86_64/rhceph-tools/9/os     
Repo ID:   rhceph-9-tools-for-rhel-10-x86_64-source-rpms
Repo Name: Red Hat Ceph Storage Tools 9 for RHEL 10 x86_64 (Source RPMs)
Repo URL:  https://cdn.redhat.com/content/dist/layered/rhel10/x86_64/rhceph-tools/9/source/SRPMS


# Refresh the RPM GPG keys
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

# Verify the key imported
rpm -qa gpg-pubkey

sudo dnf clean all
sudo dnf makecache

# Install cephadm dependencies
sudo dnf install -y python3 podman

# Download cephadm
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/main/src/cephadm/cephadm.py

chmod +x cephadm.py
sudo mv cephadm.py /usr/local/bin/cephadm

# Verify
cephadm --version

# Remove the broken one
sudo rm /usr/local/bin/cephadm

# Download the correct standalone cephadm for Reef (single binary, no deps)
curl --silent --remote-name --location \
  https://download.ceph.com/rpm-reef/el9/noarch/cephadm

chmod +x cephadm
sudo mv cephadm /usr/local/bin/cephadm

# PATH verification
# Option 1 — use full path with sudo
sudo /usr/local/bin/cephadm --help

# Option 2 — copy to /usr/sbin so sudo finds it
sudo cp /usr/local/bin/cephadm /usr/sbin/cephadm
which cephadm
ls -la /usr/local/bin/cephadm

sudo cephadm --help
sudo dnf repolist

sudo tee /etc/yum.repos.d/ceph-reef.repo << 'EOF'
[ceph-reef]
name=Ceph Reef
baseurl=https://download.ceph.com/rpm-reef/el9/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc
EOF


sudo /usr/local/bin/cephadm add-repo --release reef





# Option 1 — use full path with sudo
sudo /usr/local/bin/cephadm --help
sudo /usr/local/bin/cephadm 
sudo /usr/local/bin/cephadm 
sudo /usr/local/bin/cephadm 

# Option 2 — copy to /usr/sbin so sudo finds it
sudo cp /usr/local/bin/cephadm /usr/sbin/cephadm
sudo cephadm --help

# Remove old repo
sudo rm /etc/yum.repos.d/ceph-reef.repo

# Create correct repo pointing to noarch
sudo tee /etc/yum.repos.d/ceph-reef.repo << 'EOF'
[ceph-reef-noarch]
name=Ceph Reef noarch
baseurl=https://download.ceph.com/rpm-reef/el9/noarch/
enabled=1
gpgcheck=0

[ceph-reef-x86_64]
name=Ceph Reef x86_64
baseurl=https://download.ceph.com/rpm-reef/el9/x86_64/
enabled=1
gpgcheck=0
EOF

sudo dnf clean all
sudo dnf install -y cephadm
##    Complete!
##############################
## install  iputils
sudo dnf install -y bind-utils
sudo dnf install -y iputils

# Check DNS config
cat /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

curl -I http://google.com.
# Test DNS resolution
nslookup google.com

# Test basic HTTP
curl -I http://google.com

# Check network interfaces
ip addr show
 inet 172.21.204.100
# Check routing
ip route show
default via 172.21.192.1 dev eth0 proto kernel 


cat /etc/yum.repos.d/ceph-reef.repo

# Basic connectivity
ping -c 3 8.8.8.8

# DNS resolution
nslookup download.ceph.com

# Try without SSL
curl -I http://download.ceph.com/rpm-reef/el9/x86_64/

# Check if it's a cert issue
curl -Ik https://download.ceph.com/rpm-reef/el9/x86_64/

# Check ca-certificates
# Update CA certificates
sudo dnf install -y ca-certificates
sudo update-ca-trust
sudo update-ca-trust extract

# Test HTTPS now
curl -I https://download.ceph.com/rpm-reef/el9/x86_64/


cephadm version 18.2.8 (efac5a54607c13fa50d4822e50242b86e6e446df) reef (stable)
hostname -I
172.21.204.100 172.17.0.1 
## CHECK
systemctl --version
cat /proc/1/comm

The root cause is nftables — WSL2 kernel doesn't support it. Podman's network backend netavark uses nftables which fails in WSL. 
RHEL 10 dropped iptables-legacy entirely. 
# Test podman with host networking
podman run --rm --network=host hello-world

# Clean up failed cluster
sudo /usr/local/bin/cephadm rm-cluster --fsid d9331df6-4d71-11f1-b2fa-00155d49dc91 --force

##  # Create the missing udev directory
sudo mkdir -p /run/udev

# Clean up failed cluster
sudo cephadm rm-cluster --fsid 855301a4-4d73-11f1-8d8f-00155d49dc91 --force

# Test podman now
podman run --rm --network=host hello-world


# Bootstrap with skip flags to avoid networking issues
sudo /usr/local/bin/cephadm bootstrap \
  --mon-ip 172.21.204.100 \
  --skip-monitoring-stack \
  --single-host-defaults 
  
  



podman ps -a | grep ceph
podman logs $(podman ps -aq | head -1)







###   BOOTSTRAP
sudo cephadm bootstrap --mon-ip 172.21.204.100
This will:

Pull the Ceph container image via podman
Start the monitor daemon
Generate the cluster config and keyrings
Print the Ceph dashboard URL and credentials
It takes a few minutes on first run — paste the output as it goes.

[root@ASUSVIVO2026 CEPH-DEPLOY-2026]# podman run --rm --network=host hello-world
!... Hello Podman World ...!

         .--"--.
       / -     - \
      / (O)   (O) \
   ~~~| -=(,Y,)=- |
    .---. /`  \   |~~      
 ~/  o  o \~~~~.----. ~~
  | =(X)= |~  / (O (O) \
   ~~~~~~~  ~| =(Y_)=-  |
  ~~~~    ~~~|   U      |~~

Project:   https://github.com/containers/podman
Website:   https://podman.io
Desktop:   https://podman-desktop.io
Documents: https://docs.podman.io
YouTube:   https://youtube.com/@Podman
X/Twitter: @Podman_io
Mastodon:  @Podman_io@fosstodon.org
[root@ASUSVIVO2026 CEPH-DEPLOY-2026]# sudo cephadm rm-cluster --fsid 855301a4-4d73-11f1-8d8f-00155d49dc91 --force

sudo cephadm bootstrap \
  --mon-ip 172.21.204.100 \
  --skip-monitoring-stack \
  --single-host-defaults
Deleting cluster with fsid: 855301a4-4d73-11f1-8d8f-00155d49dc91
Verifying podman|docker is present...
Verifying lvm2 is present...
Verifying time synchronization is in place...
Unit chronyd.service is enabled and running
Repeating the final host check...
podman (/bin/podman) version 5.6.0 is present
systemctl is present
lvcreate is present
Unit chronyd.service is enabled and running
Host looks OK
Cluster fsid: 4f287b4e-4d74-11f1-aa0d-00155d49dc91
Verifying IP 172.21.204.100 port 3300 ...
Verifying IP 172.21.204.100 port 6789 ...
Mon IP `172.21.204.100` is in CIDR network `172.21.192.0/20`
Mon IP `172.21.204.100` is in CIDR network `172.21.192.0/20`
Internal network (--cluster-network) has not been provided, OSD replication will default to the public_network
Adjusting default settings to suit single-host cluster...
Pulling container image quay.io/ceph/ceph:v18...
Ceph version: ceph version 18.2.8 (efac5a54607c13fa50d4822e50242b86e6e446df) reef (stable)
Extracting ceph user uid/gid from container image...
Creating initial keys...
Creating initial monmap...
Creating mon...
Waiting for mon to start...
Waiting for mon...
mon is available
Assimilating anything we can from ceph.conf...
Generating new minimal ceph.conf...
Restarting the monitor...
Setting public_network to 172.21.192.0/20 in global config section
Wrote config to /etc/ceph/ceph.conf
Wrote keyring to /etc/ceph/ceph.client.admin.keyring
Creating mgr...
Verifying port 0.0.0.0:9283 ...
Verifying port 0.0.0.0:8765 ...
Waiting for mgr to start...
Waiting for mgr...
mgr not available, waiting (1/15)...
mgr not available, waiting (2/15)...
mgr not available, waiting (3/15)...
mgr not available, waiting (4/15)...
mgr is available
Enabling cephadm module...
Waiting for the mgr to restart...
Waiting for mgr epoch 5...
mgr epoch 5 is available
Setting orchestrator backend to cephadm...
Generating ssh key...
Wrote public SSH key to /etc/ceph/ceph.pub
Adding key to root@localhost authorized_keys...
Adding host ASUSVIVO2026...
Deploying mon service with default placement...
Deploying mgr service with default placement...
Deploying crash service with default placement...
Enabling the dashboard module...
Waiting for the mgr to restart...
Waiting for mgr epoch 9...
mgr epoch 9 is available
Generating a dashboard self-signed certificate...
Creating initial admin user...
Fetching dashboard port number...
Ceph Dashboard is now available at:

             URL: https://ASUSVIVO2026.localdomain:8443/
            User: admin
        Password: u20legmoz2

Enabling client.admin keyring and conf on hosts with "admin" label
Saving cluster configuration to /var/lib/ceph/4f287b4e-4d74-11f1-aa0d-00155d49dc91/config directory
Enabling autotune for osd_memory_target
You can access the Ceph CLI as following in case of multi-cluster or non-default config:

        sudo /sbin/cephadm shell --fsid 4f287b4e-4d74-11f1-aa0d-00155d49dc91 -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

Or, if you are only running a single cluster on this host:

        sudo /sbin/cephadm shell

Please consider enabling telemetry to help improve Ceph:

        ceph telemetry on

For more information see:

        https://docs.ceph.com/en/latest/mgr/telemetry/

Bootstrap complete.


Created CEPH-WSL-RHEL10-Install-2026-05-11.md in your CEPH-DEPLOY-2026 folder. It covers:

Full cluster info (FSID, dashboard URL, credentials)
All 5 errors hit during the session with root cause and fix for each
Complete step-by-step install sequence in order
WSL2 limitations table with workarounds
Key file locations
Post-bootstrap commands (health check, OSD add, CLI access)




## 
##
##
##
##
##
## OLD UBUNTU-24.04 install










filliat@ASUSVIVO2026:~$ sudo cephadm bootstrap --mon-ip 172.21.204.100
Verifying podman|docker is present...
Verifying lvm2 is present...
Verifying time synchronization is in place...
Unit systemd-timesyncd.service is enabled and running
Repeating the final host check...
docker (/usr/bin/docker) is present
systemctl is present
lvcreate is present
Unit systemd-timesyncd.service is enabled and running
Host looks OK
Cluster fsid: 017fd008-4bc3-11f1-84ff-00155d49d688
Verifying IP 172.21.204.100 port 3300 ...
Verifying IP 172.21.204.100 port 6789 ...
Mon IP `172.21.204.100` is in CIDR network `172.21.192.0/20`
Mon IP `172.21.204.100` is in CIDR network `172.21.192.0/20`
Internal network (--cluster-network) has not been provided, OSD replication will default to the public_network
Pulling container image quay.io/ceph/ceph:v19...
Ceph version: ceph version 19.2.3 (c92aebb279828e9c3c1f5d24613efca272649e62) squid (stable)
Extracting ceph user uid/gid from container image...
Creating initial keys...
Creating initial monmap...
Creating mon...
Waiting for mon to start...
Waiting for mon...
mon is available
Assimilating anything we can from ceph.conf...
Generating new minimal ceph.conf...
Restarting the monitor...
Setting public_network to 172.21.192.0/20 in mon config section
Wrote config to /etc/ceph/ceph.conf
Wrote keyring to /etc/ceph/ceph.client.admin.keyring
Creating mgr...
Verifying port 0.0.0.0:9283 ...
Verifying port 0.0.0.0:8765 ...
Verifying port 0.0.0.0:8443 ...
Waiting for mgr to start...
Waiting for mgr...
mgr not available, waiting (1/15)...
mgr not available, waiting (2/15)...
mgr not available, waiting (3/15)...
mgr not available, waiting (4/15)...
mgr not available, waiting (5/15)...
mgr is available
Enabling cephadm module...
Waiting for the mgr to restart...
Waiting for mgr epoch 5...
mgr epoch 5 is available
Setting orchestrator backend to cephadm...
Generating ssh key...
Wrote public SSH key to /etc/ceph/ceph.pub
Adding key to root@localhost authorized_keys...
Adding host ASUSVIVO2026...
Deploying mon service with default placement...
Deploying mgr service with default placement...
Deploying crash service with default placement...
Deploying ceph-exporter service with default placement...
Deploying prometheus service with default placement...
Deploying grafana service with default placement...
Deploying node-exporter service with default placement...
Deploying alertmanager service with default placement...
Enabling the dashboard module...
Waiting for the mgr to restart...
Waiting for mgr epoch 9...
mgr epoch 9 is available
Generating a dashboard self-signed certificate...
Creating initial admin user...
Fetching dashboard port number...
Ceph Dashboard is now available at:

             URL: https://ASUSVIVO2026.localdomain:8443/
            User: admin
        Password: q57kkzscry

Enabling client.admin keyring and conf on hosts with "admin" label
Saving cluster configuration to /var/lib/ceph/017fd008-4bc3-11f1-84ff-00155d49d688/config directory
You can access the Ceph CLI as following in case of multi-cluster or non-default config:

        sudo /usr/sbin/cephadm shell --fsid 017fd008-4bc3-11f1-84ff-00155d49d688 -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

Or, if you are only running a single cluster on this host:

        sudo /usr/sbin/cephadm shell

Please consider enabling telemetry to help improve Ceph:

        ceph telemetry on

For more information see:

        https://docs.ceph.com/en/latest/mgr/telemetry/

Bootstrap complete.
filliat@ASUSVIVO2026:~$







