# NetApp Astra Trident Deployment Guide: Kubernetes on RHEL 9 WSL

This guide provides step-by-step instructions for deploying and configuring the **NetApp Astra Trident CSI** storage orchestrator on a Kubernetes cluster running inside a **Red Hat Enterprise Linux (RHEL) 9 Windows Subsystem for Linux (WSL 2)** environment.

For this guide, we assume a local development/testing setup using **Minikube** (with the `podman` or `docker` driver) on RHEL 9, interfacing with a remote **NetApp ONTAP** storage system via NFS.

---

## 1. Overview of Astra Trident

**Astra Trident** is an open-source dynamic storage orchestrator maintained by NetApp. It integrates with Kubernetes' CSI (Container Storage Interface) to:
- Automatically provision PVs (Persistent Volumes) on ONTAP storage in response to PVC (Persistent Volume Claim) requests.
- Support standard operations such as volume expansion, cloning, and snapshotting.
- Manage exports, exports policies, and access controls dynamically on the NetApp controllers.

In a WSL 2 / local Minikube developer lab, the **NFS (`ontap-nas` driver)** is the recommended storage backend. This is because **iSCSI** requires specialized SCSI kernel initiator modules (`iscsi-initiator-utils` and multipathing) that are not compiled into the default Microsoft WSL 2 kernel.

---

## 2. Prerequisites & Lab Setup

Ensure your local development environment meets the following requirements:

### A. Environment Specs
- **Windows Host OS**: Windows 10/11 with WSL 2 enabled.
- **WSL 2 Distro**: Red Hat Enterprise Linux (RHEL) 9.x.
- **Kubernetes Cluster**: Minikube (e.g., v1.38.1 running Kubernetes v1.35.1 using the `podman` driver).
- **Target Storage**: NetApp ONTAP (ONTAP 9.x) cluster accessible over the network.
- **CLI Tools**: `kubectl`, `helm` (v3+), and `wget`/`curl` installed.

### B. Network & Firewall
- The RHEL 9 WSL instance must have network connectivity to the:
  - **ONTAP Cluster Management IP/LIF** (for API commands over HTTPS/SSH).
  - **ONTAP Data LIF** (for mounting NFS exports).
- *Note:* Because WSL 2 uses Network Address Translation (NAT) by default, ensure Windows Firewall allows outgoing traffic from WSL to the ONTAP LIFs.

### C. ONTAP Storage Preparation
Prepare a Storage Virtual Machine (SVM) on your ONTAP cluster:
- **SVM Name**: e.g., `svm_nfs`
- **Data LIF**: IP address configured for NFS traffic.
- **NFS Protocol**: Enabled on the SVM.
- **Export Policy**: A policy allowing mount requests from the WSL VM subnet (or `0.0.0.0/0` for sandbox lab simplicity).

---

## 3. Step 1: Prepare the RHEL 9 WSL Host

Because Astra Trident mounts NFS directories onto the Kubernetes nodes (which are containerized inside Podman/Docker on your RHEL 9 host), both the WSL host and the Minikube nodes must have the proper NFS client utilities installed.

### A. Install NFS Client Tools on RHEL 9
Run the following commands inside your RHEL 9 WSL terminal:

```bash
# Update repositories and install nfs-utils
sudo dnf install nfs-utils -y

# Start and enable rpcbind (required for NFS v3/v4 locking services)
sudo systemctl enable --now rpcbind
```

> [!IMPORTANT]
> **WSL 2 Systemd Enablement**
> To run `systemctl` commands in WSL 2, systemd must be enabled. Ensure your `/etc/wsl.conf` has the following lines:
> ```ini
> [boot]
> systemd=true
> ```
> If you make changes, restart WSL from Windows PowerShell:
> ```powershell
> wsl --shutdown
> ```

### B. Verify ONTAP NFS Reachability
Test that your RHEL 9 WSL instance can see the NFS exports of your ONTAP storage:

```bash
# Replace <ONTAP_DATA_LIF_IP> with your ONTAP SVM Data LIF IP
showmount -e <ONTAP_DATA_LIF_IP>
```

---

## 4. Step 2: Install Astra Trident via Helm

Using the **Trident Operator with Helm** is the recommended deployment method for Kubernetes.

### A. Add the Astra Trident Helm Repository
```bash
helm repo add trident https://netapp.github.io/trident-helm-chart
helm repo update
```

### B. Install the Trident Operator
Deploy the operator into the `trident` namespace:

```bash
helm install trident trident/trident-operator \
  --create-namespace \
  --namespace trident \
  --set tridentImageTag=24.10.0
```

*Note: Replace `24.10.0` with the target release matching your Kubernetes version requirements.*

### C. Verify the Operator Deployment
Check the status of the Trident pods:

```bash
kubectl get pods -n trident
```

You should see output similar to this:
```text
NAME                                READY   STATUS    RESTARTS   AGE
trident-controller-6d4b76c8c-xxxxx  6/6     Running   0          45s
trident-node-linux-xxxxx            2/2     Running   0          45s
trident-operator-76495dbbd9-xxxxx   1/1     Running   0          60s
```

- **`trident-operator`**: Manages the life cycle of Trident.
- **`trident-controller`**: The CSI controller pod that talks to the ONTAP API.
- **`trident-node-linux`**: Run as a DaemonSet on every node (including Minikube) to manage the storage attachments and mount NFS shares.

---

## 5. Step 3: Configure the ONTAP Backend

The Trident Operator uses Custom Resource Definitions (CRDs) to define storage backends. We will define a `TridentBackendConfig` (TBC) for ONTAP NFS.

### A. Create a Kubernetes Secret for ONTAP Credentials
Store your ONTAP SVM administrative username and password in a Kubernetes Secret:

```yaml
# ontap-credentials.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ontap-credentials
  namespace: trident
type: Opaque
stringData:
  username: admin
  password: ONTAP_PASSWORD_HERE
```

Apply the secret:
```bash
kubectl apply -f ontap-credentials.yaml
```

### B. Create the TridentBackendConfig Definition
Define the backend configuration file using the `ontap-nas` driver:

```yaml
# trident-backend-nas.yaml
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: backend-ontap-nas
  namespace: trident
spec:
  version: 1
  storageDriverName: ontap-nas
  managementLIF: 10.0.0.50          # Replace with SVM Mgmt IP or Cluster Mgmt IP
  dataLIF: 10.0.0.51                # Replace with SVM Data LIF IP
  svm: svm_nfs                      # Replace with SVM Name
  credentials:
    name: ontap-credentials
  defaults:
    spaceReserve: none
    exportPolicy: default
```

Apply the backend configuration:
```bash
kubectl apply -f trident-backend-nas.yaml
```

### C. Verify Backend Status
Confirm that Astra Trident successfully registered the backend:

```bash
# Check custom resource status
kubectl get tridentbackendconfigs -n trident

# Check underlying backend object status
kubectl get tridentbackends -n trident
```

The state should show as `Bound` or `Online`.

---

## 6. Step 4: Create a StorageClass

A Kubernetes `StorageClass` maps container storage requests to the Trident backend.

```yaml
# trident-storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: trident-nfs
provisioner: csi.trident.netapp.io
parameters:
  backendType: "ontap-nas"
allowVolumeExpansion: true
```

Apply the StorageClass:
```bash
kubectl apply -f trident-storageclass.yaml
```

Verify it is created:
```bash
kubectl get storageclass trident-nfs
```

---

## 7. Step 5: Test and Verify Dynamic Provisioning

Let's test the deployment by creating a PersistentVolumeClaim (PVC) and mounting it inside an Nginx Pod.

### A. Create a PVC
Create a request for a 2 GB volume using our new StorageClass:

```yaml
# test-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: trident-test-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
  storageClassName: trident-nfs
```

Apply the PVC:
```bash
kubectl apply -f test-pvc.yaml
```

Check the PVC status:
```bash
kubectl get pvc trident-test-pvc
```

It should transition to `Bound`. Astra Trident will have automatically logged into ONTAP, created a flexvol, configured the export policy, and bound the PV.

### B. Deploy a Test Pod (Nginx)
Create a Pod that mounts the dynamically provisioned volume:

```yaml
# test-nginx-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: trident-test-nginx
spec:
  containers:
  - name: web-server
    image: nginx:latest
    ports:
    - containerPort: 80
    volumeMounts:
    - name: nfs-storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: nfs-storage
    persistentVolumeClaim:
      claimName: trident-test-pvc
```

Apply the Pod configuration:
```bash
kubectl apply -f test-nginx-pod.yaml
```

Wait for the Pod to run:
```bash
kubectl get pod trident-test-nginx -w
```

### C. Verify NFS Mount inside the Container
Write a test file into the mount path and verify it is preserved:

```bash
# Write test message
kubectl exec trident-test-nginx -- sh -c "echo 'Hello from Trident on RHEL9 WSL' > /usr/share/nginx/html/index.html"

# Verify content from the container
kubectl exec trident-test-nginx -- cat /usr/share/nginx/html/index.html
```

You can also log into your ONTAP CLI and run `volume show` to verify the volume name matching the Kubernetes PV ID (e.g., `trident_pvc_xxxx`).

---

## 8. Troubleshooting & WSL Specifics

If your storage fails to bind or the pod remains stuck in `ContainerCreating` or `MountVolume.SetUp failed`, check these common failure points:

### A. SELinux Issues on RHEL 9
On RHEL 9, SELinux defaults to `Enforcing` which might prevent containerized processes from running mounts.
- Check SELinux status: `sestatus`
- For troubleshooting, set SELinux to permissive temporarily:
  ```bash
  sudo setenforce 0
  ```
- If this resolves the issue, adjust your SELinux policy or make it permanent in `/etc/selinux/config`.

### B. ONTAP Export Policies
The NFS export policy configured on ONTAP must allow mounting from the network namespace of WSL/Minikube.
- Identify the outbound NAT IP of WSL or the host bridge interface.
- If you are running a single-node local development environment, you can modify the default export policy rule on ONTAP to allow all hosts (`0.0.0.0/0`) with read/write access and root squash disabled (`superuser=sys`), specifically for developer sandbox environments.

### C. Trident Logs Analysis
If the PVC is stuck in `Pending` state:
```bash
kubectl describe pvc trident-test-pvc
```
If the event logs show Trident controller errors, view the Trident controller logs:
```bash
kubectl logs -n trident -l app=controller
```
Look for connection timeouts or invalid authentication details in the log.




AFF A30	2025	All-Flash	Latest mid-range all-flash
AFF A50	2025	All-Flash	Latest high-end mid-range
ASA A150	2023	All-SAN	Dedicated SAN array
ASA A250	2023	All-SAN	Dedicated SAN array
ASA A400	2023	All-SAN	Dedicated SAN array
ASA A800	2023	All-SAN	Dedicated SAN array
ASA A900	2023	All-SAN	Dedicated SAN array
ASA A1K	2024	All-SAN	Next-gen SAN flagship
ASA A70	2024	All-SAN	Next-gen mid-range SAN
ASA A90	2024	All-SAN	Next-gen high-end SAN
ASA A20	2025	All-SAN (r2)	New simplified SAN experience
ASA A30	2025	All-SAN (r2)	New simplified SAN experience
ASA A50	2025	All-SAN (r2)	New simplified SAN experience
FAS250	2004	Hybrid	Entry-level, early ONTAP 7-mode
FAS270	2004	Hybrid	Entry-level, early ONTAP 7-mode
FAS3020	2005	Hybrid	Mid-range workhorse
FAS3050	2005	Hybrid	Mid-range workhorse
FAS3070	2006	Hybrid	High-end mid-range
FAS6030	2006	Hybrid	Enterprise-class storage
FAS6070	2006	Hybrid	Enterprise-class storage
FAS2020	2007	Hybrid	Successor to FAS200 series
FAS2050	2007	Hybrid	Mid-range entry-level
FAS3040	2007	Hybrid	AMD Opteron based
FAS6040	2007	Hybrid	Enterprise-class storage
FAS6080	2007	Hybrid	Enterprise-class storage
FAS3140	2008	Hybrid	Performance boost over 3000 series
FAS3160	2008	Hybrid	Performance boost over 3000 series
FAS3170	2008	Hybrid	High-end 3100 series
FAS2040	2009	Hybrid	High-performance entry-level
FAS3210	2010	Hybrid	Unified storage focus
FAS3240	2010	Hybrid	Unified storage focus
FAS3270	2010	Hybrid	High-end unified storage
FAS6210	2010	Hybrid	Scale-out enterprise storage
FAS6240	2010	Hybrid	Scale-out enterprise storage
FAS6280	2010	Hybrid	High-end enterprise storage
FAS2240	2011	Hybrid	Introduction of internal SAS shelves
FAS2220	2012	Hybrid	Lower-cost entry model
FAS3220	2012	Hybrid	Mid-life refresh
FAS3250	2012	Hybrid	Mid-life refresh
FAS6220	2013	Hybrid	Refresh of 6200 series
FAS6250	2013	Hybrid	Refresh of 6200 series
FAS6290	2013	Hybrid	Refresh of 6200 series
FAS2520	2014	Hybrid	Refresh with faster processors
FAS2552	2014	Hybrid	High-density entry-level
FAS2554	2014	Hybrid	High-capacity entry-level
FAS8020	2014	Hybrid	Unified platform for FAS3000/6000
FAS8040	2014	Hybrid	Unified platform for FAS3000/6000
FAS8060	2014	Hybrid	Unified platform for FAS3000/6000
FAS8080EX	2014	Hybrid	Extreme performance hybrid
FAS2620	2016	Hybrid	Refresh of FAS2500 series
FAS2650	2016	Hybrid	Refresh of FAS2500 series
FAS8200	2016	Hybrid	Modern mid-range hybrid
FAS9000	2016	Hybrid	Modular enterprise hybrid
FAS2720	2018	Hybrid	Updated with Skylake CPUs
FAS2750	2018	Hybrid	Updated with Skylake CPUs
FAS8300	2019	Hybrid	NVMe-accelerated hybrid
FAS8700	2019	Hybrid	NVMe-accelerated hybrid
FAS500f	2020	Hybrid	All-flash entry in FAS family
FAS2820	2022	Hybrid	Latest entry-level hybrid
FAS9500	2022	Hybrid	Latest high-end hybrid
FAS50	2024	Hybrid	Next-gen entry-level hybrid
FAS70	2024	Hybrid	Next-gen mid-range hybrid
FAS90	2024	Hybrid	Next-gen high-end hybrid
