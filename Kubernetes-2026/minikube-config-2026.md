# Minikube Configuration Notes - 2026
kubectl cluster-info
## Current Lab Configuration Reference

Current lab system:

```text
Host: ASUSVIVO2026
Operating system: Red Hat 9.8
Architecture: kvm/amd64
Minikube version: v1.38.1
Kubernetes version prepared by Minikube: v1.35.1
Selected driver after troubleshooting: podman
Failed driver attempt: kvm2
CPUs: 2
Memory: 3072 MB
Disk: 20000 MB
Default namespace: default
Current context: minikube
Enabled addons: storage-provisioner, default-storageclass, dashboard
Recommended additional addon: metrics-server
```

Current cluster information:

```text
Kubernetes control plane: https://127.0.0.1:43199
CoreDNS proxy: https://127.0.0.1:43199/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Dashboard proxy: http://127.0.0.1:38631/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```

Important lab notes:

Minikube was started from the root account, and Minikube warned that Podman and KVM2 should not normally be used with root privileges. The cluster eventually started with the Podman driver by using `--force`, but for future training labs it is better to run Minikube from a regular non-root user account with sudo access.

The KVM2 driver failed while waiting for the Minikube VM to return an IP address. Minikube deleted the failed KVM2 cluster and then started successfully with Podman.

The system had about 3917 MB of total memory, and Minikube warned that allocating 3072 MB may leave limited room for system overhead. If the cluster becomes unstable, reduce the memory setting or use a host with more RAM.

Minikube is a local Kubernetes environment used for learning, testing, and development. It creates a small Kubernetes cluster on a local workstation or virtual machine so administrators and developers can practice Kubernetes commands before working in a shared or production cluster.

For training purposes, Minikube is useful because it provides a safe lab environment. You can start a cluster, create deployments, expose services, test YAML files, view logs, troubleshoot pods, and reset the environment without affecting real business applications.

## Starting Minikube

Use `minikube start` to create and start the local Kubernetes cluster.

```bash
minikube start
```

During startup, Minikube checks the local system, selects a driver, downloads required images, creates the cluster, and configures `kubectl` to use the `minikube` context.

In the lab output, Minikube selected the Podman driver on Red Hat 9.8 after the KVM2 driver failed to start correctly. This is a good troubleshooting example because Minikube may choose a different driver depending on what is installed and available on the system.

## Important Root User Note

Minikube should normally be started from a regular user account with administrator or sudo access. In the lab output, Minikube warned that the Podman and KVM2 drivers should not be used with root privileges.

If Minikube is started as root, it may require the `--force` option, but this is not the recommended training approach.

```bash
minikube start --force
```

For cleaner practice labs, log in as a non-root user and run Minikube from that account.

## Configure CPU and Memory

Minikube can be started with specific CPU and memory settings. This is helpful when the local machine has limited resources or when the lab requires more capacity.

```bash
minikube start --cpus=2 --memory=3072
```

In the lab output, Minikube warned that 3072 MB of memory did not leave much room for system overhead because the system had about 3917 MB total memory. This means the cluster may start, but it could be unstable if the host machine does not have enough free memory.

## Save Default Configuration

Instead of typing the same startup options each time, Minikube settings can be saved as defaults.

```bash
minikube config set memory 3072
minikube config set cpus 2
```

After these values are saved, future `minikube start` commands will use the configured defaults.

To view the current Minikube configuration, use:

```bash
minikube config view
```

## Verify Cluster Status

After Minikube starts, always verify that the cluster is running and that `kubectl` can communicate with it.

```bash
minikube status
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

The `kubectl cluster-info` command shows the Kubernetes control plane URL. The `kubectl get pods -A` command shows pods across all namespaces, including system pods such as CoreDNS and storage provisioner.

If `kubectl` reports that no server is found for the Minikube cluster, confirm that the Minikube profile exists and that the cluster is running.

```bash
minikube profile list
kubectl config current-context
kubectl config use-context minikube
```

## Kubernetes Dashboard

Minikube includes a dashboard addon that provides a web interface for viewing Kubernetes resources.

```bash
minikube dashboard
```

In the lab output, Minikube enabled the dashboard and launched a local proxy URL similar to this:

```text
http://127.0.0.1:38631/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/
```

The dashboard is useful for training because it gives a visual view of deployments, pods, services, namespaces, and cluster events.

## Enable Metrics Server

Some dashboard features require the metrics server addon. The metrics server is also useful when learning about resource usage and autoscaling.

```bash
minikube addons enable metrics-server
```

To list available addons, use:

```bash
minikube addons list
```

Common training addons include `dashboard`, `metrics-server`, and `ingress`.

## Deploy a Sample Application

A simple test deployment can be created with the echo server image.

```bash
kubectl create deployment hello-minikube --image=kicbase/echo-server:1.0
kubectl expose deployment hello-minikube --type=NodePort --port=8080
kubectl get services hello-minikube
```

To open the service through Minikube, use:

```bash
minikube service hello-minikube
```

You can also use port forwarding:

```bash
kubectl port-forward service/hello-minikube 7080:8080
```

After port forwarding, the application should be available from the local machine at:

```text
http://localhost:7080/
```

## Manage the Cluster

Use `minikube pause` to pause Kubernetes without deleting deployed applications.

```bash
minikube pause
minikube unpause
```

Use `minikube stop` to stop the cluster while keeping the cluster data.

```bash
minikube stop
```

Use `minikube delete` when the training environment needs to be reset.

```bash
minikube delete
```

To delete all Minikube clusters, use:

```bash
minikube delete --all
```

## Troubleshooting Notes

If Minikube does not start, check that the selected driver is installed and running. For Red Hat based systems, common driver options include Podman, KVM2, SSH, or none. For Windows training systems, common options include Docker Desktop, Hyper-V, and WSL2.

If the KVM2 driver fails while waiting for an IP address, delete the failed cluster and try a different driver.

```bash
minikube delete
minikube start --driver=podman
```

If pods are not running, inspect the pods and node events.

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl describe node minikube
```

If dashboard features are missing, enable the metrics server addon.

```bash
minikube addons enable metrics-server
```

## Training Summary

Minikube is best used as a local Kubernetes practice environment. Start with simple commands, verify cluster status, deploy a small application, expose a service, review logs and events, and reset the cluster when needed.

For documentation purposes, record the operating system, Minikube version, selected driver, CPU setting, memory setting, enabled addons, and any troubleshooting steps used during the lab.
