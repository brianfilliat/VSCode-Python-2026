[filliat@ip-172-31-42-245 ~]$ cat /etc/os-release
uNAME="Amazon Linux"
VERSION="2023"
ID="amzn"
ID_LIKE="fedora"
VERSION_ID="2023"
PLATFORM_ID="platform:al2023"
PRETTY_NAME="Amazon Linux 2023.12.20260622"
ANSI_COLOR="0;33"
CPE_NAME="cpe:2.3:o:amazon:amazon_linux:2023"
HOME_URL="https://aws.amazon.com/linux/amazon-linux-2023/"
DOCUMENTATION_URL="https://docs.aws.amazon.com/linux/"
SUPPORT_URL="https://aws.amazon.com/premiumsupport/"
BUG_REPORT_URL="https://github.com/amazonlinux/amazon-linux-2023"
VENDOR_NAME="AWS"
VENDOR_URL="https://aws.amazon.com/"
SUPPORT_END="2029-06-30"
[filliat@ip-172-31-42-245 ~]$ uname -m
x86_64


nstalled:
  git-2.50.1-1.amzn2023.0.1.x86_64              git-core-2.50.1-1.amzn2023.0.1.x86_64        
  git-core-doc-2.50.1-1.amzn2023.0.1.noarch     perl-Error-1:0.17030-2.amzn2023.0.1.noarch   
  perl-File-Find-1.37-477.amzn2023.0.9.noarch   perl-Git-2.50.1-1.amzn2023.0.1.noarch        
  perl-TermReadKey-2.38-9.amzn2023.0.3.x86_64   perl-lib-0.65-477.amzn2023.0.9.x86_64        

Complete!
[filliat@ip-172-31-42-245 ~]$ 
[filliat@ip-172-31-42-245 ~]$ sudo systemctl enable --now docker
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
[filliat@ip-172-31-42-245 ~]$ sudo docker info
Client:
 Version:    25.0.14
 Context:    default
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc.)
    Version:  0.12.1
    Path:     /usr/libexec/docker/cli-plugins/docker-buildx

Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 Server Version: 25.0.16
 Storage Driver: overlay2
  Backing Filesystem: xfs
  Supports d_type: true
  Using metacopy: false
  Native Overlay Diff: true
  userxattr: false
 Logging Driver: json-file
 Cgroup Driver: systemd
 Cgroup Version: 2
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version:
 runc version: 488fc13e1f2d3d73ec36d829fdf2c98e47dc5ae8
 init version: de40ad0
 Security Options:
  seccomp
   Profile: builtin
  cgroupns
 Kernel Version: 6.18.35-68.127.amzn2023.x86_64
 Operating System: Amazon Linux 2023.12.20260622
 OSType: linux
 Architecture: x86_64
 CPUs: 2
 Total Memory: 912.9MiB
 Name: ip-172-31-42-245.us-east-2.compute.internal
 ID: 9f5affb5-017e-43a7-aeaf-823129577436
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Experimental: false
 Insecure Registries:
  127.0.0.0/8
 Live Restore Enabled: false


 export PATH=$PWD:$PATH


 ## OPENSHIFT VERSIONS
 [filliat@ip-172-31-42-245 ~]$ ./openshift-install version
release-4.15/stable-4.15


 [filliat@ip-172-31-42-245 ~]$ ./oc version --client
Client Version: 4.15.0-202603031119.g339da8c
Client API Version: The openshift command-line client is version 4.15.0
Server Version: 4.15.0
Feature Git Branch: release-4.15
Feature GitTreeState: clean
Feature GitCommit: 339da8c70440eb49067d8160492a4082312e745e
Host: api.az2023rhel.example.com:6443
```[filliat@ip-172-31-42-245 ~]$ ./openshift-install version
./openshift-install 4.22.2
built from commit 0e39bcd8a1ab4b7aa951b287b0290c94e606cbeb
release image quay.io/openshift-release-dev/ocp-release@sha256:b5fda8b45cab25b4d67b214e4f802a858401367bfd1f30afc77780872a626e42
release architecture amd64