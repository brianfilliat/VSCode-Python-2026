# Canary Rollout Checklist (Template)

Purpose: a concise, repeatable checklist to validate cookbook/policy changes via a canary rollout.

Pre-Canary (gates before any production exposure)
- Confirm change scope and acceptance criteria (tests, performance, business checks).
- Ensure artifact immutability (image digest / artifact hash).
- Run full CI: unit, lint, policy-lint, and integration tests in `staging`.
- Confirm monitoring and dashboards are available for canary targets (metrics + logs + traces).
- Notify stakeholders and on-call; open a tracked change ticket with links to runbooks and rollback plan.

Canary Target Selection
- Choose canary target: single host/pod, specific host group, or small percentage of traffic (start 1%).
- Prefer low-risk tenant(s) or a non-critical region for first canary.

Canary Rollout Steps
1. Deploy artifact to canary target(s) with canary flag/annotation.
2. Wait initial stabilization window (e.g., 5–15 minutes) then run smoke tests.
3. If smoke tests pass, increase traffic/instances to 5% and wait defined validation window (e.g., 15–30 minutes).
4. Run automated validation suites (functional, policy-specific checks, synthetic business transactions).
5. Compare canary vs baseline metrics (error rate, latency p95/p99, key business metrics).
6. If thresholds are met, progress to 25% → 50% → 100% in staged increments with waits and validations between each step.

Validation Metrics & Thresholds (examples)
- Error rate: no increase > 1.5x baseline for 10 minutes.
- Latency: p95 increase < 20% compared to baseline.
- Success rate of synthetic transactions: ≥ 99%.
- Business metric(s): no adverse movement beyond agreed tolerance.

Automated Actions on Failure
- If any threshold exceeded, automatically halt rollout and trigger alert to on-call.
- Optionally auto-rollback if severe (e.g., error rate > X% for Y minutes) via feature-flag or deployment rollback.

Rollback Playbook (fast path)
1. Immediately flip feature flag to previous behavior OR scale down/remove canary target.
2. If using deployments, run `helm rollback` or `kubectl rollout undo` to previous revision.
3. Run smoke tests and validate metrics returned to baseline.
4. Create incident ticket and capture timeline; do not redeploy until root cause is understood.

Post-Rollout
- Confirm final verification tests pass across all targets.
- Update change ticket with final status, timestamps, and any actions taken.
- Run a short retrospective if rollback or degradation occurred; record lessons learned.

Operational Notes
- Keep the validation window and thresholds documented per-service; avoid one-size-fits-all.
- Prefer feature flags for instant, low-risk rollback when feasible.
- Automate as much of the validation (smoke + synthetic checks) as possible to reduce time-to-detection.
- Maintain a public canary dashboard comparing canary vs baseline for quick human inspection.

References
- Link your runbooks, dashboards, and CI/CD playbooks from the change ticket.
