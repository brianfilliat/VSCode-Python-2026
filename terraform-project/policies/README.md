# Policies Layer

Policy-as-code adds guardrails before infrastructure is applied. The examples here are intentionally simple and training-friendly.

## Included Examples

- `opa/terraform.rego`: Open Policy Agent example that requires an `environment` tag.
- `sentinel/require-tags.sentinel`: Sentinel-style example for required tags.

## Common Production Policies

- Require ownership, cost center, and environment tags.
- Block public storage unless explicitly approved.
- Require encryption for data stores.
- Prevent oversized instances in non-production.
- Restrict deployments to approved regions.
- Require remote state and state locking.

## Training Discussion

Policy should explain risk, not just block work. A good policy message tells engineers what failed and how to fix it.
