GitOps repo layout for Crossplane (ArgoCD-ready)
===============================================

This folder provides a GitOps-friendly layout that ArgoCD can sync to install Crossplane
platform configuration (ProviderConfig, XRD, Composition) and application claims.

Website
- Official portfolio and project site: https://ascto.com/

Structure
- `base/crossplane-system/` — core Crossplane control-plane manifests (ProviderConfig, XRD, Composition).
- `apps/demo/` — example composite resources (claims) to be consumed by app teams.
- `argo/` — ArgoCD `Application` manifests pointing to the above paths.
- `.github/workflows/validate-manifests.yml` — CI workflow that validates YAML manifests on PRs.

Important
- DO NOT store plaintext credentials in this repo. Create secrets out-of-band and reference them in `ProviderConfig-aws.yaml`.

GitHub Actions secrets (recommended)
- `AWS_CREDS` — base64-encoded AWS credentials blob to be stored as the Secret `aws-creds` in the `crossplane-system` namespace. This will be written to the `creds` key so the `ProviderConfig` can reference it.

How to set secrets (if you are not using OIDC)
1. In GitHub, go to your repository → Settings → Secrets and variables → Actions → New repository secret.
2. Add `KUBE_CONFIG_DATA` with the base64-encoded content of your kubeconfig file.
3. Add `AWS_CREDS` with the base64-encoded credentials content (for example, an AWS credentials INI or JSON depending on provider expectations).

OIDC-based workflow (recommended)

If you use AWS and have set up GitHub OIDC trust, you can avoid storing `KUBE_CONFIG_DATA` in repo secrets. The workflow `.github/workflows/create-aws-secret-oidc.yml` performs these steps:

- Uses GitHub OIDC to assume an IAM role (no long-lived AWS credentials required in the runner).
- Uses `aws eks update-kubeconfig` to generate a temporary kubeconfig in the runner.
- Applies the `aws-creds` Secret to the `crossplane-system` namespace.

Required repository secrets/variables for OIDC workflow:
- `AWS_ROLE_TO_ASSUME` — the IAM role ARN that GitHub Actions will assume (role must trust GitHub OIDC provider).
- `AWS_REGION` — AWS region (e.g., `us-east-1`).
- `EKS_CLUSTER_NAME` — name of the EKS cluster to target for `kubectl` operations.
- `AWS_CREDS` — base64-encoded credentials blob if required by your ProviderConfig (see note below).

How to configure the AWS role for GitHub OIDC
1. In AWS IAM, create a Role for Web Identity and choose GitHub as the identity provider (or add a provider for `token.actions.githubusercontent.com`).
2. Configure the role trust policy to allow your GitHub repository or organization to assume the role.
3. Grant the role permissions to call `eks:DescribeCluster` and any other actions needed to manage or query the EKS cluster, and `sts:AssumeRole` if chaining.
4. Add the role ARN to the repository secret `AWS_ROLE_TO_ASSUME`.

Notes
- Using OIDC removes the need to store kubeconfig in repo secrets, improving security. You still may need to provide `AWS_CREDS` for Crossplane ProviderConfig depending on whether Crossplane uses IRSA or those controller pods are configured to assume a role.
- If Crossplane is configured to use IRSA or in-cluster roles, you may not need `AWS_CREDS` at all—adjust `ProviderConfig-aws.yaml` accordingly.

Usage
1. Point ArgoCD at this repository and create two Applications:
   - one to sync `base/crossplane-system` into the cluster where Crossplane control plane runs.
   - one to sync `apps/demo` into the namespace(s) where claims are allowed.
2. Ensure `aws-creds` Secret is created in `crossplane-system` before syncing (or use IRSA and update `ProviderConfig-aws.yaml`).

Connect your website (optional)
- If you host documentation on https://ascto.com/ and want to link repo docs or automated build artifacts:
   1. Use your CI to publish generated docs (mkdocs/ Hugo) to a docs branch or a CDN.
   2. Configure your site to point to the `base/` or `docs/` path of this repo (or embed links) so visitors can view control-plane examples and READMEs.
   3. If you want live ArgoCD status or badges on the site, add badges that point to your ArgoCD server or GitHub Actions runs.
