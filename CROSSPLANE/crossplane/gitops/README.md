Crossplane GitOps Example
=========================

Files in this folder show a minimal, GitOps-friendly example to expose a managed
Postgres claim to application teams.

Files
- `ProviderConfig-aws.yaml` — ProviderConfig referencing a Kubernetes Secret for AWS creds (placeholder).
- `xrd_postgres.yaml` — CompositeResourceDefinition (XRD) `CompositePostgresInstance`.
- `composition_postgres.yaml` — Composition that maps the XRD to an AWS RDS instance.
- `claim_example_postgres.yaml` — Example composite resource that requests a Postgres instance.

Usage (high-level)
1. Install Crossplane and the provider-aws controller in your control-cluster.
2. Create an appropriately-scoped `Secret` in `crossplane-system` containing credentials, named `aws-creds`.
3. Apply `ProviderConfig-aws.yaml` then the XRD and Composition.
4. Apply `claim_example_postgres.yaml` in a namespace where the platform allows claims.

Security
- Never commit plaintext credentials. Use sealed secrets, KMS-encrypted secrets, or platform-native mechanisms (IRSA/OIDC) where possible.

Note
- API group and resource names for provider-managed resources may differ by provider and Crossplane version. Adjust `apiVersion`/`kind` fields to match the provider controller you install.
