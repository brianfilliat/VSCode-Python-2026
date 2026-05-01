# Crossplane Overview — Cloud-Native Framework for Platform Engineering

Crossplane is a cloud-native control plane framework that enables platform engineers to compose, assemble, and deliver opinionated control planes for applications rather than just provisioning infrastructure. It extends Kubernetes to manage cloud services and infrastructure through Kubernetes-style APIs.

Key Concepts
- Providers: Components that expose external systems (AWS, Azure, GCP, Terraform, etc.) as managed resources.
- Managed Resources: Kubernetes CRs that represent cloud services (databases, buckets, load balancers).
- Compositions & XRDs (CompositeResourceDefinitions): Compose low-level managed resources into higher-level, opinionated APIs for application teams.
- Claims: Standardized APIs (e.g., `Bucket`, `PostgreSQLInstance`) that apps consume without knowing provider specifics.
- Controllers: Reconcile desired state defined in Kubernetes with the external provider.

Why use Crossplane
- Build platform API surfaces tailored to application needs (self-service DBs, storage, network services).
- Enforce compliance, policies and governance at the control-plane level (RBAC, OPA/Gatekeeper, policies).
- Integrate with GitOps: treat composed control planes and platform definitions as code.
- Reuse and share compositions across teams; provide a stable API during provider/region changes.

Typical Architecture
- Kubernetes cluster hosting Crossplane control plane (provider controllers + core controllers).
- One or more Provider installations for target clouds or Terraform providers.
- GitOps repo holding XRDs, Compositions, ProviderConfigs, and composition revisions.
- CI pipelines to validate composition changes and run integration tests.

Platform Engineering Patterns
- Composition-first: define higher-level application APIs using XRDs and Compositions.
- Delegated control plane: platform team owns Crossplane and provides APIs; application teams consume claims.
- Policy-as-code and validation via OPA/Gatekeeper and admission webhooks.

Getting Started (high-level)
1. Install Crossplane into a Kubernetes cluster.
2. Install and configure Providers (AWS, Azure, GCP, or Terraform provider).
3. Define ProviderConfigs with credentials and region/endpoint settings.
4. Create XRDs and Compositions to model application-facing resources.
5. Publish composition docs and enable consumption via GitOps.

References
- https://crossplane.io
- Crossplane Concepts: Providers, XRDs, Compositions, Claims
