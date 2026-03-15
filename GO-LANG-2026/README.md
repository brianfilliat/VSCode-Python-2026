# GO-LANG-2026

## Key Components Explained

- `rest.InClusterConfig()`: Essential for Kubernetes-focused Go services. It automatically looks for the service account token and CA certificate mounted at `/var/run/secrets/kubernetes.io/serviceaccount/` when running inside a cluster.
- `clientcmd.BuildConfigFromFlags`: Useful for local development. It parses your local `~/.kube/config` so you can test against a live cluster (for example, RKE or EKS) before deploying.
- `context.Context`: Required by modern `client-go` (v0.18+) API calls. It lets you add timeouts and cancellation for unresponsive API server requests.
- `kubernetes.NewForConfig(config)` (Clientset): Creates the primary Kubernetes API interface. From there, you can use `CoreV1()` for Pods/Nodes, `AppsV1()` for Deployments, and other typed clients.

## Run

From this folder (`GO-LANG-2026`):

```powershell
go mod tidy
go run .
```

Run with an explicit kubeconfig path:

```powershell
go run . --kubeconfig "$HOME\.kube\config"
```

Troubleshooting: If you see a "connection refused" error when listing pods, your current kubeconfig context likely points to a cluster/API endpoint that is not running or not reachable. Verify your Kubernetes cluster is up, confirm the active context with `kubectl config current-context`, and retry.
