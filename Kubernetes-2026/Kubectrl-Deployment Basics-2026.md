1.  **Deployment Basics**
    *   A Deployment provides declarative updates for Pods and ReplicaSets, managing the desired state of your applications.
    *   **ReplicaSet:** Ensures a specified number of pod replicas are running.
    *   **Pod Template:** Defines the pods to be created.
    *   **Desired State:** Specified in the YAML manifest (e.g., number of replicas, image version).

2.  **Essential `kubectl` Commands**
    *   **Viewing & Inspecting:**
        *   `kubectl get deployments`: List all deployments.
        *   `kubectl describe deployment <name>`: Get detailed information.
        *   `kubectl get rs`: View ReplicaSets.
        *   `kubectl get pods --show-labels`: List pods with labels.
        *   `kubectl logs deployment/<name>`: View logs for all pods in a deployment.
    *   **Creating & Modifying:**
        *   `kubectl create deployment <name> --image=<image>`: Create a simple deployment.
        *   `kubectl apply -f <file.yaml>`: Create or update deployment from a file.
        *   `kubectl edit deployment <name>`: Edit the deployment manifest in-place.
        *   `kubectl set image deployment/<name> <container>=<new-image>`: Update container image.
    *   **Scaling:**
        *   `kubectl scale deployment <name> --replicas=<num>`: Manual scaling.
        *   `kubectl autoscale deployment <name> --min=2 --max=10`: Set up Horizontal Pod Autoscaler (HPA).

3.  **Rollout & Lifecycle Management**
    *   `kubectl rollout status deployment/<name>`: Check rollout progress.
    *   `kubectl rollout history deployment/<name>`: View previous revisions.
    *   `kubectl rollout undo deployment/<name>`: Roll back to the previous version.
    *   `kubectl rollout undo deployment/<name> --to-revision=2`: Roll back to a specific revision.
    *   `kubectl rollout pause deployment/<name>`: Pause a rollout.
    *   `kubectl rollout resume deployment/<name>`: Resume a paused rollout.
    *   `kubectl rollout restart deployment/<name>`: Trigger a rolling restart.

4.  **Deployment Strategies (`spec.strategy.type`)**
    *   **RollingUpdate (Default):** Gradually replaces old pods with new ones, ensuring no downtime.
        *   `maxUnavailable`: Maximum pods that can be unavailable during an update.
        *   `maxSurge`: Maximum pods that can be created over the desired number.
    *   **Recreate:** All existing pods are terminated before new ones are created, which causes downtime but avoids version mismatch issues.

5.  **Pro Tips**
    *   **Dry Run:** `kubectl apply -f manifest.yaml --dry-run=client` to validate YAML without applying.
    *   **Wait for Ready:** `kubectl wait --for=condition=available deployment/<name> --timeout=60s` to wait for deployment availability.
    *   **Resource Limits:** Always define `resources.requests` and `resources.limits` in your deployment manifest for better resource management.
