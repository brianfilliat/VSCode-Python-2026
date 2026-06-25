# OpenShift Deployment Guide: AZ2023RHEL-2026

## Overview
This deployment guide covers installing and configuring OpenShift on the `ami-linux777` host. It includes the required environment setup, Red Hat Enterprise Linux preparation, OpenShift installation steps, and basic post-install configuration training.

> SSH access to the target host is assumed via:
>
> ```bash
ssh -i "/mnt/d/DOCU-2026/ASCTO-KEYS-2026/keypair777.pem" filliat@ec2-16-59-147-50.us-east-2.compute.amazonaws.com
> ```

---

## 1. Environment and Prerequisites

### 1.1 Host Requirements
- Target host: `ami-linux777`
- Operating System: RHEL-based Linux for OpenShift installation
- Access: SSH key pair available at `/mnt/d/DOCU-2026/ASCTO-KEYS-2026/keypair777.pem`
- User: `filliat`

### 1.2 OpenShift Versions
- OpenShift 4.x is the recommended supported release.
- Ensure the selected RHEL image and host size meet OpenShift requirements.

### 1.3 Required Packages and Tools
- `docker` for container runtime tools
- `oc` CLI for OpenShift administration
- `openshift-install` command-line utility
- `jq`, `git`, `curl`, `wget`, `vim` or preferred editor

### 1.4 Connectivity
- Internet access to pull OpenShift images and operator catalogs
- DNS resolution for cluster API endpoints and applications
- Firewall rules open for cluster communication

---

## 2. Connect to the Host

```bash
ssh -i "/mnt/d/DOCU-2026/ASCTO-KEYS-2026/keypair777.pem" filliat@ec2-16-59-147-50.us-east-2.compute.amazonaws.com
```

Verify the host is reachable and confirm the OS distribution:

```bash
cat /etc/os-release
uname -m
```

---

## 3. Install Required Packages on Amazon Linux 2023

### 3.1 Update system packages

```bash
sudo dnf update -y
```

### 3.2 Install dependencies

```bash
sudo dnf install -y git wget vim jq python3 docker
sudo systemctl enable --now docker
```

> Note: Amazon Linux 2023 supports installing Docker directly. Ensure the docker service is started and enabled.

### 3.3 Configure host networking
- Ensure required ports are open for OpenShift cluster communication.
- For Amazon Linux 2023, use `firewalld` or `iptables` as appropriate.
- Ensure `/etc/hosts` contains any required local DNS entries if not using external DNS.

---

## 4. Prepare OpenShift Installer Files

### 4.1 Download the OpenShift installer

```bash
curl -L -o openshift-install-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz
tar xvf openshift-install-linux.tar.gz
chmod +x openshift-install
```

### 4.2 Download the OpenShift client

```bash
curl -L -o oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
tar xvf oc.tar.gz
chmod +x oc
```
```bash
./openshift-install version
./oc version --client
```

### 4.3 Add tools to PATH

```bash
export PATH=$PWD:$PATH
```

---

## 5. Create the Install Configuration

### 5.1 Create install directory

```bash
mkdir openshift-install-az2023rhel
cd openshift-install-az2023rhel
```

### 5.2 Create `install-config.yaml`

Example `install-config.yaml` for a simple OpenShift install:

```yaml
apiVersion: v2
baseDomain: testcluster.com
metadata:
  name: az2023rhel
platform:
  aws: 
    region: us-east-2     
controlPlane:
  name: master
  replicas: 3
compute:
  - name: worker
    replicas: 0
pullSecret: 
sshKey: 


networking:
  networkType: OpenShiftSDN
```

**Note:** You must replace `baseDomain`, `pullSecret`, and `sshKey` with your real cluster values. Here is how to obtain them:

1. **`baseDomain`**: This is the base DNS domain of the cluster (e.g., `example.com`). All cluster endpoints will be subdomains of this (like `api.clustername.example.com`). If you are just testing and don't need external DNS, you can use a dummy domain like `

test.local
2. **`pullSecret`**: This authenticates your cluster to download OpenShift container images. Get it for free by logging into Red Hat at: [
  
  
  https://console.redhat.com/openshift/install/pull-secret
  
  
  
  
  
  ](https://console.redhat.com/openshift/install/pull-secret). Click "Download pull secret" or "Copy pull secret" and paste the entire JSON string.
3. **`sshKey`**: This is the **public** SSH key that will be added to the `core` user on your OpenShift nodes so you can SSH into them for debugging. 
   - Generate one on your host if you don't have one: `
   
   
   ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa`
   - View the public key: `
   cat ~/.ssh/id_rsa.pub
   - Paste the output (starting with `ssh-rsa ...`) into the `
   - Generate one on your host if you don't have one: `ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa`
   - View the public key: `cat ~/.ssh/id_rsa.pub`
   - Paste the output (starting with `ssh-rsa ...`) into the `sshKey` field.

---

## 6. Install OpenShift

#### 6.1 AWS Credentials Setup
The OpenShift Installer refuses to use the EC2 Instance Profile (`EC2RoleProvider`) by default. You must provide static IAM credentials with Administrator access before running the installer:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
```

### 6.2 Route 53 Public Hosted Zone Requirement
The OpenShift Installer (IPI) requires a public Route 53 Hosted Zone in your AWS account matching your `baseDomain`. You can create a dummy zone using the AWS CLI:

```bash
aws route53 create-hosted-zone --name testcluster.com --caller-reference "az2023rhel-openshift-test"
```

### 6.3 Create manifests and ignition files

```bash
./openshift-install create manifests
```

### 6.4 Create the cluster

To deploy a "Compact Cluster" (3 master nodes that also act as workers, consuming only 12 vCPUs and fitting under the default AWS 16 vCPU limit), ensure `replicas: 0` is set for workers in your `install-config.yaml` before running the command below.

```bash
./openshift-install create cluster --log-level=info
~/openshift-install destroy cluster --log-level=info
INFO Deleted                                       id=vpc-0714c8627ed58976f resourceType=vpc subnet=subnet-0f14449e7444507d1
INFO Deleted                                       id=vpc-0714c8627ed58976f resourceType=vpc
INFO Released                                      id=eipalloc-03445e1dcc67d993a resourceType=elastic-ip
INFO Time elapsed: 1m13s
INFO Uninstallation complete!
[filliat@ip-172-31-42-245 ~]$
[filliat@ip-172-31-42-245 ~]$

cat .openshift_install_state.json | grep kubeadmin
            "Filename": "auth/kubeadmin-password",
[filliat@ip-172-31-42-245 ~]$ cat ~/auth/kubeadmin-password
MMMmz-ehE9u-27piI-Bdfr4[filliat@ip-172-31-42-245 ~]$

[filliat@ip-172-31-42-245 ~]$ find ~ -name ".openshift_install.log" 2>/dev/null
/home/filliat/.openshift_install.log
[filliat@ip-172-31-42-245 ~]$

Web console URL"

Monitor the installation output. The installation process takes roughly 35-45 minutes. OpenShift will provision the infrastructure and automatically bootstrap the cluster. When it finishes, it will print out the Web Console URL, the `kubeadmin` username, and your temporary admin password!

---

## 7. Post-Install Verification

### 7.1 Login with `oc`

```bash
./oc login -u kubeadmin -p $(cat auth/kubeadmin-password) https://api.az2023rhel.example.com:6443
```

### 7.2 Verify cluster status

```bash
./oc get nodes
./oc get clusterversion
./oc get pods -n openshift-monitoring
```

---

## 8. Training and Configuration Topics (Test and Learn)
## Note: OpenShift on AWS will incur real AWS costs — the minimum cluster (3 masters + 2 workers) costs roughly $0.80–$1.50/hour depending on region.
### 8.1 OpenShift architecture
- Control plane vs worker nodes
- Kubernetes operators and CRDs
- OpenShift networking and SDN

### 8.2 Cluster administration
- Managing projects and users
- Applying security context constraints
- Monitoring cluster health and metrics

### 8.3 Common configuration tasks
- Deploying applications with `oc apply`
- Configuring persistent storage
- Setting up routes and ingress

### 8.4 Test and Learn: Deploying a Sample Application
To thoroughly test the OpenShift cluster and learn the basics of deployment, follow this exercise to deploy a simple Nginx web server.
> [!NOTE]
> **Do I need to install `kubectl` separately? No.**
> 
> 1. **`oc` IS `kubectl`**: The OpenShift CLI (`oc`) is actually built directly on top of `kubectl`. Any command you would normally run with `kubectl` (like `kubectl get pods` or `kubectl apply -f`), you can simply run with `./oc` instead.
> 2. **You already have it!**: When you downloaded and extracted the `oc.tar.gz` file back in Section 4.2, it automatically extracted both the `oc` and the `kubectl` binaries!
> 3. **Architecture compatibility**: Standard `curl` download commands often target `arm64` architectures (like Mac M1/AWS Graviton). Be careful not to download `arm64` binaries on an `x86_64` host, as they will fail to execute.
> GET the password - terminal disconnected unexpectedly,  You'll see a lot of logs scrolling by as it:

Creates the AWS network infrastructure
Boots the EC2 instances
Installs the OpenShift operating system (CoreOS)
Bootstraps the Kubernetes control plane
Installs all the built-in OpenShift operators
Just let that terminal run, and when it finishes, it will print out the Web Console URL, the kubeadmin username, and your temporary admin password!
Need to get Web Console URL, the kubeadmin username, and your temporary admin password!

> To test standard Kubernetes commands on your cluster, simply use `./oc` or `./kubectl` directly from your current folder!

1. **Create a new project (namespace):**
   ```bash
   ./oc new-project test-and-learn
   ```

2. **Deploy the Nginx application:**
   ```bash
   ./oc new-app nginx:latest --name=my-nginx
   ```

3. **Expose the application to create a route for external access:**
   ```bash
   ./oc expose svc/my-nginx
   ```

4. **Verify the deployment and route:**
   ```bash
   ./oc get pods
   ./oc get routes
   ```

5. **Test the application:**
   Copy the HOST/PORT from the `oc get routes` output and `curl` it to verify it's running:
   ```bash
   curl http://<route-host>
   ```

6. **Clean up resources:**
   ```bash
   ./oc delete project test-and-learn
   ```

---

## 9. Notes for `ami-linux777`

- Ensure the host is sized appropriately for the selected cluster profile.
- Confirm the host is using the RHEL-compatible kernel required by OpenShift.
- If this host is the bootstrap or installer machine, keep it available until cluster installation completes.

---

## 10. Helpful Commands

```bash
# Verify SSH access
ssh -i "/mnt/d/DOCU-2026/ASCTO-KEYS-2026/keypair777.pem" filliat@ec2-16-59-147-50.us-east-2.compute.amazonaws.com

# Verify OpenShift install binary exists
ls -l openshift-install

# Access the cluster via oc
./oc status
```

---

## References
- OpenShift Installation documentation: https://docs.openshift.com
- OpenShift CLI documentation: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html
- RHEL subscription and repository guidance: https://access.redhat.com
