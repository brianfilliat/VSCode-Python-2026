# Providers Layer

Provider configuration controls which APIs Terraform can use. In this training project, environments use the `local` provider so learners can practice safely.

## Production Pattern

For real cloud projects, each environment usually defines:

- required Terraform version
- required provider versions
- backend configuration
- provider aliases, if multiple accounts/subscriptions/regions are used

## Example Provider Responsibilities

- AWS: account, region, default tags, assume-role configuration
- Azure: subscription, tenant, features block
- Google Cloud: project, region, credentials source
- Kubernetes: cluster endpoint and authentication method

Keep provider versions pinned with constraints and commit `.terraform.lock.hcl` after trusted upgrades.
