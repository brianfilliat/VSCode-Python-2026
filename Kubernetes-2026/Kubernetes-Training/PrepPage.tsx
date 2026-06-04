import { useState, useMemo } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Search, Copy, Download, ExternalLink } from "lucide-react";
import { toast } from "sonner";
import "./PrepPage.css";

const SECTIONS = [
  {
    id: "kubectl-apply",
    title: "kubectl apply: A Visual Walkthrough",
    icon: "⚙️",
    content: `
## Overview
kubectl apply is the primary command for deploying and updating Kubernetes resources. It follows a declarative approach where you define the desired state in YAML files.

## Process Flow

**Step 1: Local Workstation**
- Create or modify Pod.yaml file
- Run kubectl apply command

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

## Key Components Involved
- **API Server**: Entry point for all requests
- **etcd**: Persistent storage for cluster state
- **Scheduler**: Assigns pods to nodes
- **Kubelet**: Runs containers on nodes
- **Kube-proxy**: Manages network rules
    `,
  },
  {
    id: "kubernetes-dns",
    title: "Kubernetes DNS",
    icon: "🌐",
    content: `
## What is Kubernetes DNS?

Kubernetes uses DNS to provide service discovery. Because Pods are dynamic—they restart, scale, and their IPs keep changing—DNS is essential for reliable communication.

## CoreDNS: The Internal DNS Server

CoreDNS acts as the internal DNS server of your cluster. It automatically discovers services and resolves their names to IP addresses.

## How Kubernetes DNS Works

1. **Pod sends a DNS query** (e.g., my-service.default.svc.cluster.local)
2. **Request goes to CoreDNS** - The CoreDNS service intercepts the query
3. **CoreDNS checks Kubernetes API** - Looks up the Service IP
4. **Returns the Cluster IP** - CoreDNS returns the Service's Cluster IP
5. **Traffic is routed to the correct Pod** - Kube-proxy handles the routing

## DNS Format

\`<service-name>.<namespace>.svc.cluster.local\`

## Why This Matters

- Pods are dynamic and their IPs keep changing
- Service Discovery: Applications can reference services by name instead of IP
- Load Balancing: Requests are automatically distributed across all pod replicas
- Namespace Isolation: Services can be scoped to specific namespaces
    `,
  },
  {
    id: "kubernetes-architecture",
    title: "Kubernetes Architecture",
    icon: "🏗️",
    content: `
## High-Level Overview

Kubernetes is a containerization platform that provides automated deployment, scaling, and management of containerized applications.

## Control Plane (Brain of Kubernetes)

The Control Plane is the management layer that maintains the desired state of the cluster.

**Key Components:**

1. **API Server** - Entry point for all requests, RESTful interface for cluster management
2. **etcd** - Distributed key-value store, stores all cluster state and configuration
3. **Scheduler** - Watches for unscheduled pods, assigns pods to appropriate worker nodes
4. **Controller Manager** - Runs multiple controllers, maintains desired state of resources

## Worker Nodes (Execution Layer)

Worker Nodes run the actual application containers.

**Key Components:**

1. **Kubelet** - Node agent that ensures containers run in pods
2. **Kube-proxy** - Handles networking and service routing
3. **Container Runtime** - Docker, containerd, or other container runtime

## Flow in Simple Terms

\`kubectl → API Server → etcd → Scheduler → Node → Pod runs\`

## Why This Architecture Matters

- **Separation of Concerns**: Control Plane manages, Worker Nodes execute
- **Scalability**: Add more nodes without changing control plane logic
- **Resilience**: Control Plane can be replicated for high availability
- **Flexibility**: Different workload types can run on different nodes
    `,
  },
  {
    id: "kubernetes-ingress",
    title: "Kubernetes Ingress",
    icon: "🌍",
    content: `
## What is Ingress?

Ingress is a Kubernetes API object that manages external HTTP/HTTPS access to services. It exposes services in a Kubernetes cluster to the internet.

## How Ingress Works

1. **Ingress Controller** - Watches for Ingress resources, configures the load balancer
2. **Ingress Rules** - Define routing rules based on hostname and path
3. **Service Routing** - Routes traffic to the appropriate service

## Ingress Routing Patterns

### Path-Based Routing
\`\`\`
example.com/api → api-service
example.com/web → web-service
\`\`\`

### Host-Based Routing
\`\`\`
api.example.com → api-service
web.example.com → web-service
\`\`\`

### SSL/TLS Termination
- Ingress handles SSL certificates
- Encrypted traffic to Ingress
- Unencrypted traffic to services (optional)

## Popular Ingress Controllers

- **NGINX Ingress Controller**: Most popular, feature-rich
- **Traefik**: Modern, dynamic
- **HAProxy Ingress**: High-performance
- **AWS ALB Ingress Controller**: For AWS EKS
    `,
  },
  {
    id: "kubernetes-probes",
    title: "Kubernetes Probes",
    icon: "🔍",
    content: `
## What are Probes?

Probes are diagnostic checks that Kubernetes runs to determine the health of containers. They ensure only healthy pods receive traffic.

## Liveness Probe vs Readiness Probe

### Liveness Probe
- **Purpose**: Checks if the container is still running
- **Failure Action**: Restart the container
- **Use Cases**: Detect deadlocks, infinite loops, crashed applications

### Readiness Probe
- **Purpose**: Checks if the container is ready to receive traffic
- **Failure Action**: Remove from load balancer
- **Use Cases**: Application is starting up, temporarily unavailable, performing maintenance

## Probe Types

1. **HTTP Probe** - Sends HTTP request to a health endpoint
2. **TCP Probe** - Opens TCP connection to a port
3. **Exec Probe** - Executes a command inside the container

## Key Differences

| Aspect | Liveness Probe | Readiness Probe |
|--------|----------------|-----------------|
| Purpose | Is container alive? | Is container ready for traffic? |
| Failure Action | Restart container | Remove from load balancer |
| Typical Use | Detect deadlocks | Detect startup delays |
| Timing | Throughout container lifetime | During startup and updates |
    `,
  },
  {
    id: "how-kubernetes-works",
    title: "How Kubernetes Works (End-to-End)",
    icon: "⚡",
    content: `
## Complete Flow: From kubectl to Running Pod

### Step 1: User Executes kubectl apply
\`\`\`bash
kubectl apply -f deployment.yaml
\`\`\`

### Step 2: API Server Receives Request
- Validates YAML syntax
- Checks authorization
- Stores in etcd

### Step 3: Controller Detects Change
- Deployment Controller watches for new Deployments
- Creates ReplicaSet
- ReplicaSet Controller creates Pods

### Step 4: Scheduler Assigns Pods
- Scheduler watches for unscheduled Pods
- Evaluates node resources and constraints
- Assigns Pod to suitable node

### Step 5: Kubelet Receives Assignment
- Kubelet on the assigned node receives the Pod spec
- Pulls the container image
- Creates the container via container runtime

### Step 6: Pod Runs
- Container starts
- Application begins executing
- Kubelet monitors the container

### Step 7: Service Routes Traffic
- Service selector matches Pod labels
- Kube-proxy creates network rules
- Traffic is routed to the Pod

## State Management

\`\`\`
Desired State (YAML) → API Server → etcd
                           ↓
                    Controllers
                           ↓
                    Actual State (Running Pods)
\`\`\`

## Key Principles

1. **Declarative**: You declare desired state, Kubernetes makes it happen
2. **Reconciliation**: Controllers continuously work to match desired state
3. **Self-Healing**: Kubernetes automatically restarts failed pods
4. **Scalability**: Easy to scale by changing replica count
    `,
  },
  {
    id: "kubernetes-6-swipes",
    title: "Kubernetes in 6 Swipes",
    icon: "📱",
    content: `
## Swipe 1: Pods - The Basic Unit

**What**: Smallest deployable unit in Kubernetes
**Contains**: One or more containers (usually one)
**Lifecycle**: Ephemeral, can be created and destroyed

## Swipe 2: Deployments - Manage Replicas

**What**: Manages ReplicaSets and Pods
**Purpose**: Ensure desired number of Pod replicas are running
**Features**: Rolling updates, rollback, scaling

## Swipe 3: Services - Expose Pods

**What**: Stable endpoint for accessing Pods
**Purpose**: Load balance traffic to Pods
**Types**: ClusterIP, NodePort, LoadBalancer

## Swipe 4: ConfigMaps - Store Configuration

**What**: Store non-sensitive configuration data
**Purpose**: Decouple configuration from application code
**Usage**: Environment variables, configuration files

## Swipe 5: Secrets - Store Sensitive Data

**What**: Store sensitive data like passwords and API keys
**Purpose**: Protect sensitive information
**Types**: Opaque, docker-registry, basic-auth, ssh-auth, tls

## Swipe 6: Persistent Volumes - Store Data

**What**: Storage abstraction for persistent data
**Purpose**: Decouple storage from Pods
**Types**: Local, NFS, AWS EBS, GCP PD, Azure Disk
    `,
  },
  {
    id: "first-kubernetes-object",
    title: "Your First Kubernetes Object: Pod",
    icon: "📦",
    content: `
## What is a Pod?

A **Pod** is the smallest deployable unit in Kubernetes. It's a wrapper around one or more containers that run together on the same node.

## Pod Characteristics

- **Ephemeral**: Pods are temporary and can be created/destroyed
- **Atomic**: All containers in a Pod start and stop together
- **Shared Networking**: Containers in a Pod share the same IP address
- **Shared Storage**: Containers can share storage volumes

## Pod Lifecycle

1. **Pending**: Pod is being created, waiting for resources
2. **Running**: All containers are running
3. **Succeeded**: All containers completed successfully
4. **Failed**: One or more containers failed
5. **Unknown**: Pod state cannot be determined

## Creating a Pod

\`\`\`bash
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
\`\`\`

## Common kubectl Commands

**Cluster Information**
- kubectl cluster-info
- kubectl get nodes
- kubectl describe node <node-name>

**Pod Management**
- kubectl get pods
- kubectl describe pod <pod-name>
- kubectl logs <pod-name>
- kubectl exec -it <pod-name> -- /bin/bash

**Deployment Management**
- kubectl get deployments
- kubectl create deployment <name> --image=<image>
- kubectl scale deployment/<name> --replicas=<count>

**Service Management**
- kubectl get services
- kubectl expose pod <pod-name> --port=80

**Configuration Management**
- kubectl get configmaps
- kubectl get secrets
    `,
  },
];

export default function PrepPage() {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedSection, setSelectedSection] = useState("kubectl-apply");
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const filteredSections = useMemo(() => {
    if (!searchQuery) return SECTIONS;
    const query = searchQuery.toLowerCase();
    return SECTIONS.filter(
      (section) =>
        section.title.toLowerCase().includes(query) ||
        section.content.toLowerCase().includes(query)
    );
  }, [searchQuery]);

  const currentSection = SECTIONS.find((s) => s.id === selectedSection);

  const handleCopySection = (sectionId: string) => {
    const section = SECTIONS.find((s) => s.id === sectionId);
    if (section) {
      navigator.clipboard.writeText(section.content);
      setCopiedId(sectionId);
      toast.success("Section copied to clipboard");
      setTimeout(() => setCopiedId(null), 2000);
    }
  };

  const handleDownloadMarkdown = () => {
    const content = SECTIONS.map((s) => `# ${s.title}\n\n${s.content}`).join("\n\n---\n\n");
    const blob = new Blob([content], { type: "text/markdown" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `kubernetes-prep-${new Date().toISOString().split("T")[0]}.md`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    toast.success("Markdown downloaded");
  };

  return (
    <div className="prep-page">
      {/* Header */}
      <header className="prep-header">
        <div className="header-content">
          <h1 className="header-title">Kubernetes Prep Reference</h1>
          <p className="header-subtitle">
            Complete guide to Kubernetes concepts, architecture, and best practices
          </p>
        </div>
        <Button onClick={handleDownloadMarkdown} className="download-button">
          <Download className="w-4 h-4 mr-2" />
          Download All
        </Button>
      </header>

      {/* Main Content */}
      <div className="prep-container">
        {/* Sidebar Navigation */}
        <aside className="prep-sidebar">
          {/* Search */}
          <div className="sidebar-search">
            <Search className="search-icon" />
            <Input
              placeholder="Search topics..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="search-input"
            />
          </div>

          {/* Section List */}
          <nav className="section-list">
            {filteredSections.map((section) => (
              <button
                key={section.id}
                onClick={() => {
                  setSelectedSection(section.id);
                  setSearchQuery("");
                }}
                className={`section-button ${selectedSection === section.id ? "active" : ""}`}
              >
                <span className="section-icon">{section.icon}</span>
                <span className="section-name">{section.title}</span>
              </button>
            ))}
          </nav>
        </aside>

        {/* Main Content Area */}
        <main className="prep-content">
          {currentSection ? (
            <Card className="content-card">
              <div className="content-header">
                <div className="header-title-section">
                  <span className="section-icon-large">{currentSection.icon}</span>
                  <h2>{currentSection.title}</h2>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleCopySection(currentSection.id)}
                  className="copy-button"
                >
                  <Copy className="w-4 h-4 mr-2" />
                  {copiedId === currentSection.id ? "Copied!" : "Copy"}
                </Button>
              </div>

              <div className="content-body">
                <div className="markdown-content">
                  {currentSection.content.split("\n").map((line, idx) => {
                    if (line.startsWith("## ")) {
                      return (
                        <h3 key={idx} className="content-h3">
                          {line.substring(3)}
                        </h3>
                      );
                    }
                    if (line.startsWith("### ")) {
                      return (
                        <h4 key={idx} className="content-h4">
                          {line.substring(4)}
                        </h4>
                      );
                    }
                    if (line.startsWith("**") && line.endsWith("**")) {
                      return (
                        <p key={idx} className="content-bold">
                          {line.substring(2, line.length - 2)}
                        </p>
                      );
                    }
                    if (line.startsWith("- ")) {
                      return (
                        <li key={idx} className="content-li">
                          {line.substring(2)}
                        </li>
                      );
                    }
                    if (line.startsWith("| ")) {
                      return (
                        <p key={idx} className="content-table-row">
                          {line}
                        </p>
                      );
                    }
                    if (line.trim() === "") {
                      return <div key={idx} className="content-spacer" />;
                    }
                    return (
                      <p key={idx} className="content-p">
                        {line}
                      </p>
                    );
                  })}
                </div>
              </div>
            </Card>
          ) : (
            <div className="empty-state">
              <p>No sections found matching your search.</p>
            </div>
          )}
        </main>
      </div>

      {/* Footer */}
      <footer className="prep-footer">
        <p>
          Kubernetes Prep Reference • Last Updated: March 18, 2026 •{" "}
          <a href="https://kubernetes.io/docs/" target="_blank" rel="noopener noreferrer">
            Official Docs
            <ExternalLink className="w-3 h-3 inline ml-1" />
          </a>
        </p>
      </footer>
    </div>
  );
}
