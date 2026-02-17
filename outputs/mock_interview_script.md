# Mock Interview Script — Principal Storage/Kubernetes Engineer

Interviewer: Quick intro (1 minute) — "Tell me about your most recent storage platform role and primary responsibilities."

Candidate guidance (30–60s): Brief summary focusing on leadership, architecture, and automation: platforms managed, IaC tools used, and scope (teams, cloud/hybrid). Keep to impact and ownership.

--

Interviewer: Technical deep dive (10–15 minutes)
- Question: "Design a Ceph cluster for HA and cross-region DR — start from topology to automation."

Candidate structure: 1) Goals & constraints (RPO/RTO, region latency); 2) Topology (MON/MGR/OSD placement, CRUSH rules, RGW multisite); 3) Networking & security; 4) Automation & testing (Terraform/Ansible, CI pipelines); 5) Runbooks and DR drills.

Follow-ups:
- "How do you handle GC/repair/OSD rebuild impact?"
- "What metrics and alerts are critical?"

Interviewer: Troubleshooting (5–10 minutes)
- Scenario: "A production Kubernetes PV attach is failing on multiple nodes." Ask candidate to walk through triage steps.

Interviewer: Platform engineering deep dive (8–12 minutes)
- Question: "Design a Crossplane-based control plane to expose managed Postgres instances to application teams. Walk me through XRDs, Compositions, ProviderConfigs, and GitOps deployment." 

Candidate structure: 1) Define `CompositePostgresInstance` XRD and schema; 2) Create Composition mapping to provider-managed resources (RDS/DBInstance, subnet, SG); 3) ProviderConfig with least-privilege credentials; 4) Publish composition via GitOps and define admission policies; 5) Testing and rollback strategy.

Candidate checklist:
- Check Pod/PVC/PV events and logs
- Inspect CSI logs and kubelet/controller-manager
- Verify node-level storage connectivity and multipath
- Confirm credentials and secrets
- Execute safe remediation and escalate to vendor if needed

Interviewer: Automation & CI/CD (5–10 minutes)
- Question: "Show me your approach to safely apply Terraform changes to storage backends in prod."

Candidate bullets:
- Use remote state locking, `plan` gating, separate state per environment, automated `plan` diff in PR, review/approval, automated acceptance tests, incremental apply and canary where possible, documented rollback.

Interviewer: Behavioral / Leadership (5 minutes)
- Question: "Describe a time you led a cross-team storage migration or major upgrade."

Candidate framework: Situation → Task → Action → Result; emphasize planning, communication, risk mitigation, and postmortem actions.

Closing (2 minutes): Candidate asks 2–3 clarifying questions about team structure, SLAs, and success metrics.

Tips: Use structured answers, state assumptions, call out safety and rollback, and reference automation and documentation practices.
