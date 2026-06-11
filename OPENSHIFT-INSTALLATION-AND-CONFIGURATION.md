# OpenShift Installation and Configuration Guide

**Date**: 2026  
**System**: Windows with WSL2 / Linux

## Overview

This document provides a complete guide for setting up OpenShift locally using OpenShift Local (CRC - CodeReady Containers) on Windows, and deploying applications using the `oc` CLI.

---

## Prerequisites

### 1. System Requirements

| Resource | Minimum |
|----------|---------|
| CPU | 4 virtual CPUs |
| RAM | 10.5 GB free |
| Disk | 35 GB free |
| OS | Windows 10/11 64-bit |

### 2. Required Software

- **Hyper-V** or **VirtualBox** enabled
- **Red Hat account** (free): https://console.redhat.com

---

## Installing OpenShift Local (CRC)

### Step 1 — Download CRC

1. Go to: https://console.redhat.com/openshift/create/local
2. Log in with your Red Hat account
3. Download **OpenShift Local** for Windows
4. Download the **pull secret** (required during setup)

### Step 2 — Install CRC

```powershell
# Run the installer
crc-windows-installer.exe

# Verify installation
crc version
# Output: CRC version: 2.x.x
```

### Step 3 — Setup CRC

```powershell
# Initial setup (run once)
crc setup
```

Expected output:
```
Checking if running as non-root
Checking if crc-admin-helper executable is cached
Checking if hosts file is writable
Checking if Hyper-V is installed and operational
Checking if user is part of Hyper-V Admins group
Setup is complete, you can now run 'crc start'
```

---

## Starting OpenShift Cluster

### Start the Cluster

```powershell
# Start with pull secret file
crc start --pull-secret-file pull-secret.txt
```

Expected output:
```
INFO Checking if running as non-root
INFO Caching oc binary
INFO Starting OpenShift cluster...
INFO Waiting for the cluster to stabilize
Started the OpenShift cluster.

To access the cluster, first set up your environment:
  eval $(crc oc-env)

Then you can access it using:
  oc login -u developer https://api.crc.testing:6443
  oc login -u kubeadmin https://api.crc.testing:6443
```

### Configure Environment

```powershell
# Set up oc CLI environment
crc oc-env | Invoke-Expression

# Verify oc CLI
oc version
# Output: Client Version: 4.x.x
```

### Login to Cluster

```powershell
# Login as developer (standard user)
oc login -u developer -p developer https://api.crc.testing:6443

# Login as admin
oc login -u kubeadmin -p <kubeadmin-password> https://api.crc.testing:6443
```

> Get kubeadmin password: `crc console --credentials`

---

## OpenShift Web Console

```powershell
# Open web console in browser
crc console

# Get console URL and credentials
crc console --credentials
```

Output:
```
To login as a regular user, run 'oc login -u developer -p developer https://api.crc.testing:6443'.
To login as an admin, run 'oc login -u kubeadmin -p <generated-password> https://api.crc.testing:6443'.
```

Web Console URL: `https://console-openshift-console.apps-crc.testing`

---

## Common oc CLI Commands

### Projects (Namespaces)

```bash
# List all projects
oc get projects

# Create a new project
oc new-project my-app

# Switch to a project
oc project my-app

# Delete a project
oc delete project my-app
```

### Deploying Applications

```bash
# Deploy from Docker image
oc new-app nginx:latest --name=my-nginx

# Deploy from Git repository
oc new-app https://github.com/<username>/my-repo.git

# Deploy from local Dockerfile
oc new-build --binary --name=my-app
oc start-build my-app --from-dir=. --follow

# List all deployments
oc get deployments
```

### Pods

```bash
# List pods
oc get pods

# Get pod details
oc describe pod <pod-name>

# View pod logs
oc logs <pod-name>

# Execute command in pod
oc exec -it <pod-name> -- /bin/bash
```

### Services and Routes

```bash
# List services
oc get services

# Expose a service as a route (external URL)
oc expose service my-nginx

# List routes (external URLs)
oc get routes

# Get route URL
oc get route my-nginx -o jsonpath='{.spec.host}'
```

### ConfigMaps and Secrets

```bash
# Create ConfigMap
oc create configmap my-config --from-literal=key1=value1

# Create Secret
oc create secret generic my-secret --from-literal=password=<secret-value>

# List ConfigMaps and Secrets
oc get configmaps
oc get secrets
```

### Scaling

```bash
# Scale deployment
oc scale deployment my-nginx --replicas=3

# Autoscale
oc autoscale deployment my-nginx --min=2 --max=5 --cpu-percent=80
```

---

## Deploying a Sample Application

### Example: Deploy Node.js App

```bash
# Create project
oc new-project demo-app

# Deploy from Git
oc new-app nodejs~https://github.com/sclorg/nodejs-ex.git

# Watch build progress
oc logs -f bc/nodejs-ex

# Expose the app
oc expose svc/nodejs-ex

# Get the app URL
oc get route nodejs-ex
```

### Example: Deploy from YAML

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: demo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:latest
        ports:
        - containerPort: 80
```

```bash
oc apply -f deployment.yaml
```

---

## Managing the CRC Cluster

```powershell
# Check cluster status
crc status

# Stop the cluster
crc stop

# Delete the cluster
crc delete

# List available OpenShift versions
crc config view
```

---

## ROSA — OpenShift on AWS

For cloud-based OpenShift on AWS (ROSA):

```bash
# Install ROSA CLI
# Download from: https://console.redhat.com/openshift/downloads

# Login to AWS
aws configure

# Login to Red Hat
rosa login

# Create ROSA cluster
rosa create cluster --cluster-name my-rosa-cluster

# Check cluster status
rosa describe cluster --cluster my-rosa-cluster

# Create admin user
rosa create admin --cluster my-rosa-cluster
```

Reference: https://docs.aws.amazon.com/rosa/latest/userguide/getting-started.html

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `crc start` fails | Insufficient memory | Free up RAM or increase allocation |
| `oc login` refused | Cluster not running | Run `crc start` first |
| Pull secret error | Expired/missing pull secret | Re-download from Red Hat console |
| Route not accessible | DNS not configured | Run `crc setup` again |
| Hyper-V conflict | VirtualBox installed | Disable VirtualBox or use Hyper-V |

### Common Debug Commands

```powershell
# Check CRC status
crc status

# View CRC logs
crc logs

# Check cluster health
oc get nodes
oc get clusteroperators

# Restart cluster
crc stop
crc start
```

---

## Best Practices

1. **Stop when not in use** — `crc stop` to free system resources
2. **Use projects** — isolate apps with `oc new-project`
3. **Use routes** — expose services externally with `oc expose`
4. **Resource limits** — always set CPU/memory limits in deployments
5. **Image streams** — use OpenShift image streams for automated rebuilds
6. **Health checks** — add liveness and readiness probes to deployments

---

## Useful Resources

- **OpenShift Local Docs**: https://access.redhat.com/documentation/en-us/red_hat_openshift_local
- **OpenShift Docs**: https://docs.openshift.com
- **ROSA on AWS**: https://docs.aws.amazon.com/rosa/latest/userguide/
- **oc CLI Reference**: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html
- **Red Hat Console**: https://console.redhat.com

---

*Last Updated: 2026 | Status: Active*
