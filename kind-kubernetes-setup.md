# Kind (Kubernetes in Docker) Setup Guide

**Date**: February 5, 2026  
**System**: Windows with Docker Desktop

## Overview

This document provides a complete guide for setting up a local Kubernetes development cluster using Kind (Kubernetes in Docker) on Windows.

## Prerequisites

### 1. Docker Installation

Docker Desktop version 29.2.0 is installed and running:

```powershell
docker --version
# Output: Docker version 29.2.0, build 0b9d198
```

### 2. kubectl Installation

Kubernetes command-line tool kubectl v1.34.1 is installed:

```powershell
kubectl version --client
# Output: Client Version: v1.34.1
```

### 3. Docker Hub Login

To login to Docker Hub using a Personal Access Token (PAT):

1. Create a Personal Access Token at: https://app.docker.com/settings/personal-access-tokens
2. Login using the token as password:

```powershell
docker login -u brianfilliat
# Enter your Personal Access Token when prompted for password
```

Verify login status:

```powershell
docker system info
```

## Installing Kind

Kind (Kubernetes in Docker) allows you to run Kubernetes clusters using Docker containers as nodes.

### Download Kind Binary

Download the latest Kind binary for Windows:

```powershell
curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64
```

### Rename the Binary

```powershell
Rename-Item .\kind-windows-amd64.exe kind.exe
```

### Verify Installation

```powershell
.\kind.exe --version
# Output: kind version 0.20.0
```

## Creating a Kubernetes Test Cluster

### Create the Cluster

Create a new Kubernetes cluster named "test-cluster":

```powershell
.\kind.exe create cluster --name test-cluster
```

Expected output:
```
Creating cluster "test-cluster" ...
 ✓ Ensuring node image (kindest/node:v1.27.3) 🖼
 ✓ Preparing nodes 📦 
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-test-cluster"
```

### Verify Cluster Status

Check cluster information:

```powershell
kubectl cluster-info --context kind-test-cluster
```

Output:
```
Kubernetes control plane is running at https://127.0.0.1:55226
CoreDNS is running at https://127.0.0.1:55226/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### List Cluster Nodes

```powershell
kubectl get nodes
```

Output:
```
NAME                         STATUS   ROLES           AGE     VERSION
test-cluster-control-plane   Ready    control-plane   6m41s   v1.27.3
```

### View All Pods

```powershell
kubectl get pods -A
```

Output:
```
NAMESPACE            NAME                                                 READY   STATUS    RESTARTS   AGE
kube-system          coredns-5d78c9869d-m9n2s                             1/1     Running   0          6m25s
kube-system          coredns-5d78c9869d-qjtbz                             1/1     Running   0          6m25s
kube-system          etcd-test-cluster-control-plane                      1/1     Running   0          6m38s
kube-system          kindnet-bvkdn                                        1/1     Running   0          6m25s
kube-system          kube-apiserver-test-cluster-control-plane            1/1     Running   0          6m37s
kube-system          kube-controller-manager-test-cluster-control-plane   1/1     Running   0          6m37s
kube-system          kube-proxy-drfj9                                     1/1     Running   0          6m25s
kube-system          kube-scheduler-test-cluster-control-plane            1/1     Running   0          6m37s
local-path-storage   local-path-provisioner-6bc4bddd6b-ssj2p              1/1     Running   0          6m25s
```

## Common kubectl Commands

### Namespaces

```powershell
# List all namespaces
kubectl get namespaces

# Create a new namespace
kubectl create namespace my-app
```

### Deployments

```powershell
# Create a deployment
kubectl create deployment nginx --image=nginx

# List deployments
kubectl get deployments

# Scale a deployment
kubectl scale deployment nginx --replicas=3

# Delete a deployment
kubectl delete deployment nginx
```

### Pods

```powershell
# List pods in default namespace
kubectl get pods

# List pods in all namespaces
kubectl get pods -A

# Get detailed pod information
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>

# Execute command in a pod
kubectl exec -it <pod-name> -- /bin/bash
```

### Services

```powershell
# List services
kubectl get services

# Expose a deployment as a service
kubectl expose deployment nginx --port=80 --type=NodePort

# Get service details
kubectl describe service nginx
```

### ConfigMaps and Secrets

```powershell
# Create a ConfigMap
kubectl create configmap my-config --from-literal=key1=value1

# Create a Secret
kubectl create secret generic my-secret --from-literal=password=mysecretpass

# List ConfigMaps and Secrets
kubectl get configmaps
kubectl get secrets
```

## Managing Kind Clusters

### List All Clusters

```powershell
.\kind.exe get clusters
```

### Delete a Cluster

```powershell
.\kind.exe delete cluster --name test-cluster
```

### Create a Multi-Node Cluster

Create a configuration file `kind-config.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

Create the cluster:

```powershell
.\kind.exe create cluster --name multi-node --config kind-config.yaml
```

### Load Docker Images into Kind

```powershell
# Build a Docker image
docker build -t my-app:latest .

# Load the image into Kind cluster
.\kind.exe load docker-image my-app:latest --name test-cluster
```

## Useful Resources

- **Kind Documentation**: https://kind.sigs.k8s.io/
- **Quick Start Guide**: https://kind.sigs.k8s.io/docs/user/quick-start/
- **kubectl Cheat Sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **Docker Hub**: https://hub.docker.com
- **Kubernetes Documentation**: https://kubernetes.io/docs/home/

## Troubleshooting

### Cluster Not Starting

```powershell
# Check Docker is running
docker ps

# View Kind cluster logs
.\kind.exe export logs --name test-cluster

# Delete and recreate cluster
.\kind.exe delete cluster --name test-cluster
.\kind.exe create cluster --name test-cluster
```

### kubectl Connection Issues

```powershell
# Check current context
kubectl config current-context

# Switch to Kind context
kubectl config use-context kind-test-cluster

# Verify cluster connectivity
kubectl cluster-info
```

### Docker Authentication Issues

```powershell
# Logout and login again
docker logout
docker login -u <username>

# Check Docker daemon status
docker info
```

## Best Practices

1. **Resource Management**: Kind clusters consume Docker resources. Delete unused clusters.
2. **Image Loading**: Load local images into Kind to avoid pulling from registries during development.
3. **Context Switching**: Use `kubectl config use-context` to switch between different clusters.
4. **Cleanup**: Always delete test resources and clusters when done.
5. **Version Compatibility**: Ensure kubectl version is compatible with your Kubernetes cluster version.

## Cluster Configuration

Current test cluster specifications:
- **Cluster Name**: test-cluster
- **Kubernetes Version**: v1.27.3
- **Node Type**: Single control-plane node
- **CNI**: kindnet
- **Storage**: local-path-provisioner
- **DNS**: CoreDNS

## Summary

You now have a fully functional local Kubernetes development environment powered by Kind. This setup allows you to:

- Test Kubernetes deployments locally
- Develop and debug containerized applications
- Learn Kubernetes concepts without cloud costs
- CI/CD testing and validation
- Multi-cluster testing scenarios

Happy Kubernetes learning! 🚀
