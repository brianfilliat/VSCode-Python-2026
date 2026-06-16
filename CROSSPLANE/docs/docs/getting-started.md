# Getting Started

This page explains how to view and apply the Crossplane GitOps manifests in this repository.

Local inspection

1. Browse the manifests in the repo at `outputs/crossplane/gitops/gitops-repo`.
2. Review the ArgoCD Application manifests in `argo/` and the crossplane base resources in `base/crossplane-system`.

Apply control-plane locally (for testing)

```bash
# Apply ProviderConfig and XRD/Composition to the cluster where Crossplane runs
kubectl apply -R -f outputs/crossplane/gitops/gitops-repo/base/crossplane-system

# Apply demo claims (in namespace `demo`)
kubectl apply -R -f outputs/crossplane/gitops/gitops-repo/apps/demo
```

Notes
- Ensure the `aws-creds` Secret exists in `crossplane-system` before applying provider-managed resources, or use the OIDC workflow to create the Secret via Actions.
