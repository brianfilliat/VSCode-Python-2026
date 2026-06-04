# Kubernetes Training Content Structure

## Overview
The PDF contains 52 pages of comprehensive Kubernetes training materials organized by topic with visual diagrams, code examples, and detailed explanations.

## Main Topics Identified

### 1. kubectl apply: A Visual Walkthrough (Page 1)
- Local workstation setup
- Cluster control plane architecture
- Worker node operations
- Pod lifecycle and scheduling
- Includes Python code example with Counter collection

### 2. Kubernetes DNS (Page 2)
- What is Kubernetes DNS?
- DNS components and CoreDNS
- DNS name resolution workflow
- DNS format: `<service-name>.<namespace>.svc.cluster.local`
- Example configurations
- Key concepts about dynamic pod IPs

### 3. Kubernetes Architecture (Page 2)
- Control Plane (Brain of Kubernetes)
  - API Server: entry point for all requests
  - etcd: stores cluster state
  - Scheduler: decides where pods should run
  - Controller Manager: maintains desired state
- Worker Nodes (Execution Layer)
  - Kubelet: ensures containers are running
  - Kube-proxy: handles networking & service routing
  - Pods: smallest deployable units
- Flow: kubectl → API Server → etcd → Scheduler → Node → Pod runs

### 4. Kubernetes Ingress (Page 3)
- How Ingress works
- Ingress monitoring
- Ingress routing examples
- Ingress controllers
- Multiple ingress configurations

### 5. Kubernetes Probes: Liveness vs Readiness (Page 3)
- Liveness Probe: checks if container is running
- Readiness Probe: checks if application is ready to handle traffic
- Probe types: HTTP, TCP, Exec
- Key differences table
- Example YAML configurations

### 6. How Kubernetes Works (End-to-End) (Page 4)
- Complete workflow from deployment to pod execution
- All major components and their interactions
- Request flow through the system

### 7. Kubernetes in 6 Swipes (Page 5)
- Quick reference guide
- 6 key concepts for learning Kubernetes
- Visual summary of core components

### 8. Your First Kubernetes Object: Pod (Page 5)
- Pod definition structure
- YAML configuration example
- Key fields and their meanings
- Container specifications
- Environment variables and ports

## Content Types
- Visual diagrams and architecture charts
- Code examples (Python, YAML)
- Configuration tables
- Workflow flowcharts
- Comparison matrices
- Detailed explanations and notes

## Design Elements
- Color-coded sections (blue, green, yellow, purple)
- Icons and visual indicators
- Structured layouts with clear hierarchies
- Tables for comparisons and specifications
