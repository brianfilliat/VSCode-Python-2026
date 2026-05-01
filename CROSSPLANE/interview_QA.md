# Principal-level Interview Q&A — Storage, Kubernetes, Cloud, Automation

## Storage Architecture — SDS & Enterprise Arrays
- Q: Design a multi-region Ceph-based SDS that meets HA and DR requirements.
- A: Define MON/MGR/OSD placement with failure-domain-aware CRUSH rules; use replication for hot pools and erasure coding for cold/object pools; segregate control and data networks; enable RGW multisite/realm replication for object DR; automate deployments and config via IaC; implement monitoring, capacity forecasting, and documented DR playbooks.

- Q: How would you approach a migration from legacy SAN arrays to NVMe-oF or cloud block storage?
- A: Inventory workloads (IOPS, latency, dependency maps); choose migration method (array-replication, host-based, vMotion); stage and validate in test; coordinate zoning and multipath changes; run phased cutovers with tested rollback and runbooks; update monitoring and automation.

## Kubernetes CSI & OpenStack Integration
- Q: Build self-service storage workflows for Kubernetes CSI and OpenStack consumers.
- A: Deploy stable CSI drivers (Ceph-CSI, Longhorn), define StorageClasses and quotas, enable dynamic provisioning and snapshot/backup CRDs, integrate backends with OpenStack Cinder where needed, expose service catalog and automate via GitOps.

- Q: Troubleshoot PV attach/mount failures in Kubernetes.
- A: Inspect `kubectl describe` on Pod/PVC/PV, review controller-manager and kubelet logs, check CSI driver logs, verify node connectivity to storage (iSCSI/NVMe), confirm secrets and credentials, validate mount namespaces and SELinux/AppArmor.

## Infrastructure-as-Code & Automation
- Q: Best practices for Terraform/Ansible/Helm in storage IaC.
- A: Keep Terraform modular with remote state and locking, manage secrets with Vault, write idempotent Ansible roles, version Helm charts, enforce policy (OPA), include automated `plan`/review pipelines and unit/integration tests (terratest, molecule).

- Q: What features belong in a production Python automation tool for storage?
- A: Robust API client, idempotency, retries/backoff, structured logging, error handling, safe defaults, unit/integration tests, feature flags for destructive ops, and CI validation.

## Observability, Alerting & Auto-Remediation
- Q: How to instrument storage and Kubernetes for production observability?
- A: Export Prometheus metrics (node, Ceph, CSI), centralize logs (Loki/EFK), create Grafana dashboards and SLO/SLI, enable Alertmanager with runbook links, add synthetic provisioning tests and capacity forecasts.

- Q: Example auto-remediation pattern.
- A: Alertmanager webhook triggers a controller or job that runs safe pre-checks, attempts non-destructive remediation (restart driver, requeue), records audit logs, and escalates if unsuccessful.

## High Availability & Disaster Recovery
- Q: Architect HA and DR for block and object storage across regions.
- A: Use sync replication for metro clusters and async for long-distance; establish clear failover gates and quorum rules; for objects use multi-site replication and DNS-based failover; automate failover drills and validate application reconnect behavior.

## Networking & Storage Protocols
- Q: When to choose FC vs iSCSI vs NVMe-oF?
- A: FC for dedicated low-latency fabric; iSCSI where IP flexibility and cost matter; NVMe-oF for highest-performance NVMe devices over RDMA or FC — pick based on latency, host support, switching, and management overhead.

## Troubleshooting & Incident Response
- Q: On-call steps for major storage outage.
- A: Triage impact, gather metrics/logs, open incident and notify stakeholders, perform containment (failover/redirect), run tested remediation playbooks, restore service, perform RCA and publish postmortem.

## Leadership & Documentation
- Q: How do you maintain runbooks and knowledge base content?
- A: Use standardized templates (symptom → steps → escalation), keep runbooks in Git, test them during drills, add owners and review cycles, and update after incidents.

## Crossplane & Platform Engineering
- Q: What is Crossplane and why is it useful for platform engineering?
- A: Crossplane is a Kubernetes-native control plane framework that lets platform teams expose opinionated, application-facing control planes (APIs) by composing cloud resources via XRDs and Compositions. It enables self-service application provisioning, policy enforcement, and GitOps-driven lifecycle management while decoupling application APIs from underlying provider implementations.

- Q: How would you design a Crossplane composition to provide managed databases to application teams?
- A: Create an XRD like `CompositePostgresInstance` and a Composition that wires provider-specific managed resources (RDS, subnet, security groups). Define connection secrets production-safe, set reclaimPolicy, and include parameters for size/tier. Validate with integration tests and publish via GitOps with RBAC and ProviderConfig referencing least-privileged credentials.

- Q: Troubleshooting Crossplane-managed resources failures.
- A: Check Crossplane and provider-controller logs, inspect managed resource status conditions, check ProviderConfig credentials and permissions, validate composition patches and references, confirm external API rate limits and quotas, and re-run composition reconciliation by updating spec or controller annotations.
