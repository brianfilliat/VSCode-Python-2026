# Kubernetes Complete Reference Guide

**Last Updated:** March 18, 2026  
**Source:** Kubernetes OneNotes 2026  
**Total Content:** 52 Pages of Comprehensive Kubernetes Training Material

---

## Table of Contents

1. [kubectl apply: A Visual Walkthrough](#kubectl-apply-a-visual-walkthrough)
2. [Kubernetes DNS](#kubernetes-dns)
3. [Kubernetes Architecture](#kubernetes-architecture)
4. [Kubernetes Ingress](#kubernetes-ingress)
5. [Kubernetes Probes](#kubernetes-probes)
6. [How Kubernetes Works (End-to-End)](#how-kubernetes-works)
7. [Kubernetes in 6 Swipes](#kubernetes-in-6-swipes)
8. [Your First Kubernetes Object: Pod](#your-first-kubernetes-object-pod)
9. [Additional Reference Materials](#additional-reference-materials)

---

## kubectl apply: A Visual Walkthrough

### Overview
`kubectl apply` is the primary command for deploying and updating Kubernetes resources. It follows a declarative approach where you define the desired state in YAML files.

### Process Flow

**Step 1: Local Workstation**
- Create or modify `Pod.yaml` file
- Run `kubectl apply` command

**Step 2: Cluster Communication**
- YAML is sent to the Kubernetes API Server
- Located in the Control Plane

**Step 3: API Server Processing**
- Validates the YAML syntax and schema
- Stores the configuration in etcd (distributed key-value store)
- Watches for changes

**Step 4: Scheduler Assignment**
- Scheduler picks up unscheduled pods
- Assigns pods to appropriate worker nodes based on resource requirements

**Step 5: Worker Node Execution**
- Kubelet (node agent) pulls the image and starts the container
- Kube-proxy handles networking and service routing
- Running app pod is deployed

### Key Components Involved
- **API Server**: Entry point for all requests
- **etcd**: Persistent storage for cluster state
- **Scheduler**: Assigns pods to nodes
- **Kubelet**: Runs containers on nodes
- **Kube-proxy**: Manages network rules

### Example Python Code
```python
from collections import Counter

events = [
    {'ticket_id': 'T001', 'group': 'FOC'},
    {'ticket_id': 'T002', 'group': 'DCEO'},
    {'ticket_id': 'T003', 'group': 'FOC'},
    {'ticket_id': 'T004', 'group': 'BMS'}
]

counts = Counter(event['group'] for event in events)
```

---

## Kubernetes DNS

### What is Kubernetes DNS?

Kubernetes uses DNS to provide service discovery. Because Pods are dynamic—they restart, scale, and their IPs keep changing—DNS is essential for reliable communication.

### CoreDNS: The Internal DNS Server

**CoreDNS** acts as the internal DNS server of your cluster. It automatically discovers services and resolves their names to IP addresses.

### How Kubernetes DNS Works

1. **Pod sends a DNS query**
   - Example: `my-service.default.svc.cluster.local`

2. **Request goes to CoreDNS**
   - The CoreDNS service intercepts the query

3. **CoreDNS checks Kubernetes API**
   - Looks up the Service IP in the Kubernetes API

4. **Returns the Cluster IP**
   - CoreDNS returns the Service's Cluster IP

5. **Traffic is routed to the correct Pod**
   - Kube-proxy handles the actual routing

### DNS Format

```
<service-name>.<namespace>.svc.cluster.local
```

### Example
```
backend.default.svc.cluster.local
```

### Why This Matters

- **Banjaare • Bairan**: Pods are dynamic and their IPs keep changing
- **Service Discovery**: Applications can reference services by name instead of IP
- **Load Balancing**: Requests are automatically distributed across all pod replicas
- **Namespace Isolation**: Services can be scoped to specific namespaces

### DNS Resolution Process

| Step | Description |
|------|-------------|
| 1 | Pod sends DNS query for service name |
| 2 | Query reaches CoreDNS service |
| 3 | CoreDNS checks Kubernetes API for Service IP |
| 4 | CoreDNS returns the Cluster IP |
| 5 | Traffic is routed to the correct Pod |

---

## Kubernetes Architecture

### High-Level Overview

Kubernetes is a containerization platform that provides automated deployment, scaling, and management of containerized applications.

### Control Plane (Brain of Kubernetes)

The Control Plane is the management layer that maintains the desired state of the cluster.

**Key Components:**

1. **API Server**
   - Entry point for all requests
   - RESTful interface for cluster management
   - Validates and processes all requests

2. **etcd**
   - Distributed key-value store
   - Stores all cluster state and configuration
   - Single source of truth for cluster data

3. **Scheduler**
   - Watches for unscheduled pods
   - Assigns pods to appropriate worker nodes
   - Considers resource requirements and constraints

4. **Controller Manager**
   - Runs multiple controllers
   - Maintains desired state of resources
   - Examples: Deployment Controller, StatefulSet Controller, DaemonSet Controller

### Worker Nodes (Execution Layer)

Worker Nodes run the actual application containers.

**Key Components:**

1. **Kubelet**
   - Node agent that ensures containers run in pods
   - Communicates with the API Server
   - Manages pod lifecycle

2. **Kube-proxy**
   - Handles networking and service routing
   - Maintains network rules
   - Enables service discovery

3. **Container Runtime**
   - Docker, containerd, or other container runtime
   - Pulls and runs container images
   - Manages container lifecycle

### Flow in Simple Terms

```
kubectl → API Server → etcd → Scheduler → Node → Pod runs
```

### Why This Architecture Matters

**Understanding architecture = faster debugging, better design**

- **Separation of Concerns**: Control Plane manages, Worker Nodes execute
- **Scalability**: Add more nodes without changing control plane logic
- **Resilience**: Control Plane can be replicated for high availability
- **Flexibility**: Different workload types can run on different nodes

---

## Kubernetes Ingress

### What is Ingress?

Ingress is a Kubernetes API object that manages external HTTP/HTTPS access to services. It exposes services in a Kubernetes cluster to the internet.

### How Ingress Works

1. **Ingress Controller**
   - Watches for Ingress resources
   - Configures the load balancer
   - Routes traffic to services

2. **Ingress Rules**
   - Define routing rules based on hostname and path
   - Specify which service to route to

3. **Service Routing**
   - Routes traffic to the appropriate service
   - Service distributes traffic to pods

### Ingress Routing Patterns

#### Path-Based Routing
```
example.com/api → api-service
example.com/web → web-service
```

#### Host-Based Routing
```
api.example.com → api-service
web.example.com → web-service
```

#### SSL/TLS Termination
```
Ingress handles SSL certificates
Encrypted traffic to Ingress
Unencrypted traffic to services (optional)
```

### Ingress Manifest Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

### Ingress Controllers

Popular Ingress Controllers:
- **NGINX Ingress Controller**: Most popular, feature-rich
- **Traefik**: Modern, dynamic
- **HAProxy Ingress**: High-performance
- **AWS ALB Ingress Controller**: For AWS EKS

---

## Kubernetes Probes

### What are Probes?

Probes are diagnostic checks that Kubernetes runs to determine the health of containers. They ensure only healthy pods receive traffic.

### Liveness Probe vs Readiness Probe

#### Liveness Probe

**Purpose**: Checks if the container is still running

**Actions**:
- **Passed**: Container is alive, keep it running
- **Failed**: Container is stuck, restart it

**When to use**:
- Detect deadlocks
- Detect infinite loops
- Detect crashed applications

#### Readiness Probe

**Purpose**: Checks if the container is ready to receive traffic

**Actions**:
- **Passed**: Container is ready, send traffic
- **Failed**: Container is not ready, don't send traffic

**When to use**:
- Application is starting up
- Application is temporarily unavailable
- Application is performing maintenance

### Probe Types

1. **HTTP Probe**
   ```yaml
   httpGet:
     path: /health
     port: 8080
   ```

2. **TCP Probe**
   ```yaml
   tcpSocket:
     port: 3306
   ```

3. **Exec Probe**
   ```yaml
   exec:
     command:
     - /bin/sh
     - -c
     - mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'SELECT 1'
   ```

### Key Differences

| Aspect | Liveness Probe | Readiness Probe |
|--------|----------------|-----------------|
| Purpose | Is container alive? | Is container ready for traffic? |
| Failure Action | Restart container | Remove from load balancer |
| Typical Use | Detect deadlocks | Detect startup delays |
| Timing | Throughout container lifetime | During startup and updates |

### Example YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-app
    image: my-app:1.0
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

---

## How Kubernetes Works (End-to-End)

### Complete Flow: From kubectl to Running Pod

#### Step 1: User Executes kubectl apply

```bash
kubectl apply -f deployment.yaml
```

#### Step 2: API Server Receives Request

- Validates YAML syntax
- Checks authorization
- Stores in etcd

#### Step 3: Controller Detects Change

- Deployment Controller watches for new Deployments
- Creates ReplicaSet
- ReplicaSet Controller creates Pods

#### Step 4: Scheduler Assigns Pods

- Scheduler watches for unscheduled Pods
- Evaluates node resources and constraints
- Assigns Pod to suitable node

#### Step 5: Kubelet Receives Assignment

- Kubelet on the assigned node receives the Pod spec
- Pulls the container image
- Creates the container via container runtime

#### Step 6: Pod Runs

- Container starts
- Application begins executing
- Kubelet monitors the container

#### Step 7: Service Routes Traffic

- Service selector matches Pod labels
- Kube-proxy creates network rules
- Traffic is routed to the Pod

### State Management

```
Desired State (YAML) → API Server → etcd
                           ↓
                    Controllers
                           ↓
                    Actual State (Running Pods)
```

### Key Principles

1. **Declarative**: You declare desired state, Kubernetes makes it happen
2. **Reconciliation**: Controllers continuously work to match desired state
3. **Self-Healing**: Kubernetes automatically restarts failed pods
4. **Scalability**: Easy to scale by changing replica count

---

## Kubernetes in 6 Swipes

### Swipe 1: Pods - The Basic Unit

**What**: Smallest deployable unit in Kubernetes
**Contains**: One or more containers (usually one)
**Lifecycle**: Ephemeral, can be created and destroyed

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: my-image:latest
```

### Swipe 2: Deployments - Manage Replicas

**What**: Manages ReplicaSets and Pods
**Purpose**: Ensure desired number of Pod replicas are running
**Features**: Rolling updates, rollback, scaling

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 3
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
        image: my-app:1.0
```

### Swipe 3: Services - Expose Pods

**What**: Stable endpoint for accessing Pods
**Purpose**: Load balance traffic to Pods
**Types**: ClusterIP, NodePort, LoadBalancer

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP
```

### Swipe 4: ConfigMaps - Store Configuration

**What**: Store non-sensitive configuration data
**Purpose**: Decouple configuration from application code
**Usage**: Environment variables, configuration files

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  DATABASE_HOST: db.example.com
  DATABASE_PORT: "5432"
```

### Swipe 5: Secrets - Store Sensitive Data

**What**: Store sensitive data like passwords and API keys
**Purpose**: Protect sensitive information
**Types**: Opaque, docker-registry, basic-auth, ssh-auth, tls

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  username: dXNlcm5hbWU=  # base64 encoded
  password: cGFzc3dvcmQ=  # base64 encoded
```

### Swipe 6: Persistent Volumes - Store Data

**What**: Storage abstraction for persistent data
**Purpose**: Decouple storage from Pods
**Types**: Local, NFS, AWS EBS, GCP PD, Azure Disk

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

---

## Your First Kubernetes Object: Pod

### What is a Pod?

A **Pod** is the smallest deployable unit in Kubernetes. It's a wrapper around one or more containers that run together on the same node.

### Pod Characteristics

- **Ephemeral**: Pods are temporary and can be created/destroyed
- **Atomic**: All containers in a Pod start and stop together
- **Shared Networking**: Containers in a Pod share the same IP address
- **Shared Storage**: Containers can share storage volumes

### Single Container Pod

Most common use case - one container per pod.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

### Multi-Container Pod

Containers in a Pod share network namespace and can communicate via localhost.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: app
    image: my-app:latest
    ports:
    - containerPort: 8080
  - name: sidecar
    image: logging-sidecar:latest
    ports:
    - containerPort: 9000
```

### Pod Lifecycle

1. **Pending**: Pod is being created, waiting for resources
2. **Running**: All containers are running
3. **Succeeded**: All containers completed successfully
4. **Failed**: One or more containers failed
5. **Unknown**: Pod state cannot be determined

### Creating a Pod

```bash
# Create from YAML file
kubectl apply -f pod.yaml

# Create from command line
kubectl run my-pod --image=nginx:latest

# Get pod status
kubectl get pods

# Describe pod details
kubectl describe pod my-pod

# View pod logs
kubectl logs my-pod

# Execute command in pod
kubectl exec -it my-pod -- /bin/bash

# Delete pod
kubectl delete pod my-pod
```

### Resource Requests and Limits

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod
spec:
  containers:
  - name: app
    image: my-app:latest
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

### Init Containers

Init containers run before app containers and must complete successfully.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-container-pod
spec:
  initContainers:
  - name: init
    image: busybox:latest
    command: ['sh', '-c', 'echo "Initializing..." && sleep 5']
  containers:
  - name: app
    image: my-app:latest
```

---

## Additional Reference Materials

### Common kubectl Commands

```bash
# Cluster Information
kubectl cluster-info
kubectl get nodes
kubectl describe node <node-name>

# Pod Management
kubectl get pods
kubectl get pods -n <namespace>
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl exec -it <pod-name> -- /bin/bash
kubectl port-forward <pod-name> 8080:8080
kubectl delete pod <pod-name>

# Deployment Management
kubectl get deployments
kubectl create deployment <name> --image=<image>
kubectl set image deployment/<name> <container>=<image>
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl scale deployment/<name> --replicas=<count>

# Service Management
kubectl get services
kubectl expose pod <pod-name> --port=80 --target-port=8080
kubectl port-forward service/<service-name> 8080:80

# Configuration Management
kubectl get configmaps
kubectl create configmap <name> --from-file=<file>
kubectl get secrets
kubectl create secret generic <name> --from-literal=key=value

# Namespace Management
kubectl get namespaces
kubectl create namespace <name>
kubectl delete namespace <name>

# Debugging
kubectl get events
kubectl describe <resource-type> <resource-name>
kubectl logs <pod-name>
kubectl exec <pod-name> -- <command>
```

### YAML Structure Best Practices

1. **Always specify namespace**: Avoid default namespace in production
2. **Use labels and selectors**: For organization and selection
3. **Set resource requests/limits**: For proper scheduling
4. **Use health probes**: For reliability
5. **Version your images**: Avoid using `latest` tag
6. **Use ConfigMaps for config**: Keep code and config separate
7. **Use Secrets for sensitive data**: Never hardcode passwords

### Kubernetes Best Practices

1. **Use Deployments, not Pods**: Deployments provide self-healing
2. **Set resource requests/limits**: Helps scheduler and prevents resource starvation
3. **Use health probes**: Ensure only healthy pods receive traffic
4. **Use namespaces**: Organize resources logically
5. **Use RBAC**: Control who can do what
6. **Use NetworkPolicies**: Control traffic between pods
7. **Use PodSecurityPolicies**: Enforce security standards
8. **Monitor and log**: Use Prometheus, ELK, or similar
9. **Use GitOps**: Manage infrastructure as code
10. **Plan for disaster recovery**: Regular backups and testing

### Useful Resources

- **Official Documentation**: https://kubernetes.io/docs/
- **Kubernetes API Reference**: https://kubernetes.io/docs/reference/
- **kubectl Cheat Sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **Kubernetes Community**: https://kubernetes.io/community/
- **CNCF**: https://www.cncf.io/

---

## Quick Reference Tables

### Pod Phases

| Phase | Description |
|-------|-------------|
| Pending | Pod is being created, waiting for resources |
| Running | All containers are running |
| Succeeded | All containers completed successfully |
| Failed | One or more containers failed |
| Unknown | Pod state cannot be determined |

### Service Types

| Type | Description | Use Case |
|------|-------------|----------|
| ClusterIP | Internal IP, accessible within cluster | Internal services |
| NodePort | Exposes on node IP and port | External access, testing |
| LoadBalancer | External load balancer | Production external access |
| ExternalName | Maps to external DNS name | External service integration |

### Probe Types

| Type | Description | Use Case |
|------|-------------|----------|
| HTTP | Sends HTTP request | Web applications |
| TCP | Opens TCP connection | Databases, caches |
| Exec | Executes command | Custom health checks |

### Resource Units

| Resource | Unit | Example |
|----------|------|---------|
| CPU | millicores (m) | 250m = 0.25 CPU |
| Memory | bytes (Mi, Gi) | 128Mi, 1Gi |
| Storage | bytes (Ki, Mi, Gi) | 10Gi |

---

## Glossary

- **API Server**: Entry point for all Kubernetes API requests
- **etcd**: Distributed key-value store for cluster state
- **Kubelet**: Node agent that runs containers
- **Kube-proxy**: Network proxy that maintains network rules
- **Pod**: Smallest deployable unit in Kubernetes
- **Deployment**: Manages Pods and ReplicaSets
- **Service**: Stable endpoint for accessing Pods
- **ConfigMap**: Stores non-sensitive configuration data
- **Secret**: Stores sensitive data
- **Namespace**: Logical cluster partition
- **Label**: Key-value pair for organizing resources
- **Selector**: Query for selecting resources by labels
- **Annotation**: Metadata for resources
- **RBAC**: Role-Based Access Control
- **NetworkPolicy**: Rules for pod-to-pod communication
- **Ingress**: Manages external HTTP/HTTPS access
- **PersistentVolume**: Storage abstraction
- **PersistentVolumeClaim**: Request for storage

---

**End of Kubernetes Complete Reference Guide**

*This guide contains comprehensive information extracted from the Kubernetes OneNotes 2026 document. For the latest information, visit https://kubernetes.io/docs/*
