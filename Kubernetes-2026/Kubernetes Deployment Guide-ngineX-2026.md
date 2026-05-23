## Kubernetes Deployment Guide: Deploying a Simple Nginx Application

This guide will walk you through the process of deploying, managing, and updating a simple Nginx application on a Kubernetes cluster using the `kubectl` command-line tool. We will leverage the concepts and commands outlined in the Kubernetes Deployment Cheat Sheet.

### 1. Prerequisites

Before you begin, ensure you have the following:

*   A running Kubernetes cluster (e.g., Minikube, Docker Desktop Kubernetes, or a cloud-managed cluster).
*   `kubectl` installed and configured to connect to your Kubernetes cluster.

### 2. Deployment Manifest

We will use a simple YAML manifest to define our Nginx deployment. This manifest declares a Deployment named `nginx-deployment` that will manage three replicas of an Nginx container running version `1.14.2`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

Save this content to a file named `nginx-deployment.yaml`.

### 3. Deploying the Application

To deploy the Nginx application to your Kubernetes cluster, use the `kubectl apply` command with your manifest file:

```bash
kubectl apply -f nginx-deployment.yaml
```

This command will create the Deployment and the associated ReplicaSet and Pods as defined in the YAML file.

### 4. Verifying the Deployment

After applying the manifest, you can check the status of your deployment and its associated resources:

*   **List Deployments:** To see your deployment, use:
    ```bash
kubectl get deployments
    ```

*   **Get Detailed Deployment Information:** To inspect the deployment's status, events, and managed ReplicaSets, use:
    ```bash
kubectl describe deployment nginx-deployment
    ```

*   **List Pods:** To see the individual Nginx pods created by the deployment, use:
    ```bash
kubectl get pods --show-labels
    ```

*   **View Pod Logs:** To check the logs of the Nginx containers, use:
    ```bash
kubectl logs deployment/nginx-deployment
    ```

### 5. Scaling the Application

You can easily scale your application up or down by changing the number of replicas. For example, to scale the Nginx deployment to 5 replicas:

```bash
kubectl scale deployment nginx-deployment --replicas=5
```

Verify the scaling by checking the deployments and pods again:

```bash
kubectl get deployments
kubectl get pods
```

### 6. Updating the Application

To update the Nginx application to a newer version (e.g., `nginx:1.16.1`), you can use the `kubectl set image` command. This will trigger a rolling update, replacing the old pods with new ones gradually, ensuring no downtime.

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.16.1
```

Monitor the rollout status:

```bash
kubectl rollout status deployment/nginx-deployment
```

### 7. Rolling Back the Application

If an update introduces issues, you can easily roll back to a previous stable version. First, check the rollout history:

```bash
kubectl rollout history deployment/nginx-deployment
```

Then, to roll back to the immediately previous version, use:

```bash
kubectl rollout undo deployment/nginx-deployment
```

To roll back to a specific revision (e.g., revision 2), use:

```bash
kubectl rollout undo deployment/nginx-deployment --to-revision=2
```

### 8. Cleaning Up

When you no longer need the application, you can delete the deployment and all its associated resources (ReplicaSets and Pods) using the `kubectl delete` command:

```bash
kubectl delete deployment nginx-deployment
```

This completes the demonstration of deploying and managing a simple application using Kubernetes deployments. This process highlights the declarative nature of Kubernetes, allowing you to define your desired state and let the system manage the actual state.
