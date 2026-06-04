# Kubernetes Training Content Organization

## Topic Sections Structure

### Section 1: kubectl apply - A Visual Walkthrough
**Description**: Understanding how kubectl apply works from local workstation through cluster deployment

**Key Concepts**:
- Local workstation setup with pod.yaml
- Cluster control plane architecture
- API Server validation and storage
- Scheduler pod assignment
- Worker node execution
- Running app pod lifecycle

**Content Type**: Diagram + Code Example

---

### Section 2: Kubernetes DNS
**Description**: How DNS resolution works within Kubernetes clusters using CoreDNS

**Key Concepts**:
- What is Kubernetes DNS?
- DNS components (CoreDNS, kube-dns)
- DNS name resolution workflow
- DNS format: `<service-name>.<namespace>.svc.cluster.local`
- DNS records and lookups
- Example configurations

**Tables**:
- DNS Record Types (A, AAAA, SRV, PTR)
- DNS Resolution Process Steps

**Content Type**: Diagram + Tables + Examples

---

### Section 3: Kubernetes Architecture
**Description**: Complete overview of Kubernetes cluster architecture and components

**Key Concepts**:
- Control Plane (Kubernetes Brain)
  - API Server: entry point for all requests
  - etcd: distributed key-value store for cluster state
  - Scheduler: assigns pods to nodes
  - Controller Manager: maintains desired state
  - Cloud Controller Manager: cloud-specific logic

- Worker Nodes (Execution Layer)
  - Kubelet: node agent ensuring containers run
  - Kube-proxy: network proxy and load balancer
  - Container Runtime: runs containers
  - Pods: smallest deployable units

- Flow: kubectl → API Server → etcd → Scheduler → Node → Pod

**Tables**:
- Control Plane Components and Responsibilities
- Worker Node Components and Functions
- Component Dependencies and Communication

**Content Type**: Architecture Diagram + Component Tables + Flowchart

---

### Section 4: Kubernetes Ingress
**Description**: External access to services through Ingress resources

**Key Concepts**:
- What is Ingress?
- Ingress Controller role
- Ingress rules and routing
- Host-based routing
- Path-based routing
- TLS/SSL termination
- Multiple ingress configurations

**Tables**:
- Ingress Annotations
- Ingress Controller Types
- Routing Rules Examples

**Content Type**: Diagram + Configuration Examples + Tables

---

### Section 5: Kubernetes Probes - Liveness vs Readiness
**Description**: Health checking mechanisms for container lifecycle management

**Key Concepts**:
- Liveness Probe: determines if container should be restarted
- Readiness Probe: determines if pod should receive traffic
- Startup Probe: checks if application has started
- Probe types: HTTP GET, TCP Socket, Exec

**Tables**:
- Probe Type Comparison
- Probe Configuration Parameters
- Probe Behavior Examples
- Key Differences (Liveness vs Readiness)

**YAML Examples**:
- HTTP Liveness Probe
- TCP Readiness Probe
- Exec Startup Probe

**Content Type**: Flowcharts + Comparison Tables + YAML Examples

---

### Section 6: How Kubernetes Works (End-to-End)
**Description**: Complete workflow from user request through pod execution

**Key Concepts**:
- User submits kubectl command
- API Server validation
- etcd persistence
- Scheduler assignment
- Kubelet execution
- Container runtime startup
- Service networking
- Monitoring and logging

**Workflow Steps**:
1. kubectl apply deployment.yaml
2. API Server validates and stores in etcd
3. Scheduler watches for unscheduled pods
4. Scheduler assigns pod to node
5. Kubelet on node pulls image
6. Container runtime starts container
7. Pod becomes ready
8. Service routes traffic to pod

**Content Type**: End-to-End Flowchart + Step-by-Step Explanation

---

### Section 7: Kubernetes in 6 Swipes
**Description**: Quick reference guide to core Kubernetes concepts

**Key Concepts**:
1. Why Kubernetes exists
2. What is a Pod?
3. How apps stay running
4. How traffic reaches apps
5. How data persists
6. How security works

**Content Type**: Quick Reference Guide + Visual Summary

---

### Section 8: Your First Kubernetes Object - Pod
**Description**: Understanding Pod definition and configuration

**Key Concepts**:
- Pod definition structure
- apiVersion and kind
- Metadata (name, namespace, labels)
- Spec (containers, volumes, resources)
- Container specification
- Environment variables
- Ports and networking
- Resource requests and limits
- Volume mounts

**YAML Structure**:
```
apiVersion: v1
kind: Pod
metadata:
  name: first-pod
  namespace: default
  labels: {}
spec:
  containers:
  - name: container-name
    image: image:tag
    ports: []
    env: []
    resources: {}
  volumes: []
```

**Content Type**: YAML Examples + Field Descriptions + Configuration Tables

---

## Database Schema for Training Content

### Tables Structure

#### `training_topics` table
- id (primary key)
- title (string)
- slug (string, unique)
- description (text)
- order (integer)
- icon (string)
- created_at (timestamp)
- updated_at (timestamp)

#### `training_sections` table
- id (primary key)
- topic_id (foreign key)
- title (string)
- content (text, editable)
- order (integer)
- created_at (timestamp)
- updated_at (timestamp)

#### `training_tables` table
- id (primary key)
- section_id (foreign key)
- title (string)
- table_name (string)
- created_at (timestamp)
- updated_at (timestamp)

#### `training_table_rows` table
- id (primary key)
- table_id (foreign key)
- row_data (JSON)
- order (integer)
- created_at (timestamp)
- updated_at (timestamp)

#### `training_notes` table
- id (primary key)
- section_id (foreign key)
- note_type (enum: 'definition', 'example', 'tip', 'warning')
- content (text, editable)
- created_at (timestamp)
- updated_at (timestamp)

#### `content_revisions` table
- id (primary key)
- section_id (foreign key)
- original_content (text)
- modified_content (text)
- modified_by (foreign key to users)
- revision_number (integer)
- created_at (timestamp)

---

## Editable Elements

### Text Fields
- Section descriptions and explanations
- Note content (definitions, examples, tips, warnings)
- Table cell content
- Code examples

### Table Operations
- Add new row
- Edit row data
- Delete row
- Reorder rows
- Add/remove columns

### Admin Functions
- Reset all content to original PDF defaults
- View revision history
- Restore previous versions
- Manage user permissions

---

## Search and Filter Capabilities

### Search Scope
- Topic titles and descriptions
- Section content
- Table data
- Note content
- Code examples

### Filter Options
- By topic
- By content type (diagram, table, code, text)
- By difficulty level
- By last modified date
- By author (if tracking)

---

## Export and Print Features

### Export Formats
- PDF (with all tables and formatting)
- Markdown (for note-taking)
- HTML (standalone)
- JSON (for backup)

### Print View
- Optimized layout for printing
- Hide interactive elements
- Show all expanded content
- Page breaks at section boundaries
