# Scenario-based Role-Play Exercises — Storage + Cloud + Kubernetes

## Scenario A — Ceph Cluster Partial Quorum Loss (Role-play)
- Context: One region loses network to a subset of OSDs and some MONs; PGs are degraded.
- Prompt for candidate: Triage and remediate while minimizing data loss and downtime.
- Expected steps:
  - Confirm scope with monitoring and `ceph -s` / `ceph health detail`.
  - Do not immediately remove OSDs; check network and MON status.
  - If split-brain risk: protect the cluster by stopping conflicting services and consult runbook.
  - Re-establish network paths or remove unreachable OSDs via safe out/evict flows and rebalance.
  - Validate data recovery and document timeline for RCA.

## Scenario B — Kubernetes PVs Not Attaching During Node Reboot
- Context: After a kernel patch, several nodes reboot and some PVs fail to reattach.
- Candidate task: Root cause and restore state.
- Expected steps:
  - Check node kubelet logs and `kubectl describe pod` for attach errors.
  - Inspect CSI plugin DaemonSet logs and node connectivity to storage (iSCSI discovery/NVMe discovery).
  - Verify multipath state and restart host-level services if safe.
  - Recreate ephemeral mounts or cordon/evict and reschedule pods if needed.

## Scenario C — Planned Storage Backend Upgrade with Minimal Impact
- Context: Rolling upgrade required for backend array firmware and CSI plugin.
- Candidate task: Create a rollout plan.
- Plan outline:
  - Create LLD and test in staging.
  - Automate upgrade steps via Ansible/Terraform where possible.
  - Use canary nodes and limit blast radius.
  - Communicate maintenance windows and rollback plan.
  - Execute and monitor; run post-upgrade validation scripts.

  ## Scenario D — Crossplane Control Plane Rollout (Role-play)
  - Context: The platform team will roll out a new Crossplane composition that exposes managed PostgreSQL claims to application teams. The rollout must be safe, auditable, and reversible.
  - Prompt for candidate: Provide a rollout plan, testing strategy, and rollback procedure.
  - Expected steps:
    - Validate composition in staging: install Crossplane providers and ProviderConfig with scoped test credentials.
    - Create `CompositePostgresInstance` XRD and Composition; include connection secret generation and reclaim policies.
    - Run integration tests that provision and tear down instances against a sandbox cloud account.
    - Publish Composition to GitOps repo and create a PR for review with automated `plan` checks and policy validations.
    - Canary release: enable composition in a limited namespace or with a feature-flag to a single team.
    - Monitor provisioning logs, Crossplane controller metrics, and external provider quotas; capture audits of resource creation.
    - Rollback: remove composition or revert to previous revision via GitOps if errors occur; run cleanup playbooks to remove orphaned managed resources.

  Scoring criteria: safety, test coverage, automation, policy enforcement, and rollback clarity.

## How to Use These Role-plays
- Run live with a peer or record video answers.
- Time each run: 10–20 minutes for technical scenarios.
- Score on: clarity of assumptions, safety-first steps, automation use, communication, and runbook completeness.
