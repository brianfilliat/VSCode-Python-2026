# Managed DB Terraform module (Aurora example)

This module provisions an Amazon Aurora cluster (Postgres/MySQL) with a subnet group, security group, optional Secrets Manager secret, and cluster instances.

Usage example is in `examples/usage`.

Key notes:
- Do not store plaintext passwords in source; prefer `create_secret = true` or supply an existing Secrets Manager ARN.
- Use remote state (S3 backend with locking) for production.
- Integrate policy-as-code (tfsec/checkov) in CI.
