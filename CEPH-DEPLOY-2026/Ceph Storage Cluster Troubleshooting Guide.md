# Ceph Storage Cluster Troubleshooting Guide

This guide provides practical steps to diagnose and resolve common issues encountered during and after a Ceph deployment using `cephadm`.

## 1. Essential Diagnostic Commands

Before diving into specific issues, use these commands to get an overview of the cluster's state.

| Command | Description |
| :--- | :--- |
| `ceph health detail` | Shows a detailed report of the cluster's health status and any warnings/errors. |
| `ceph status` or `ceph -s` | Provides a high-level summary of the cluster, including OSD status, monitor quorum, and data usage. |
| `ceph orch ps` | Lists all daemons managed by the orchestrator and their current status (running, starting, etc.). |
| `ceph orch ls` | Shows the status of all services (mon, mgr, osd, etc.) and their placement rules. |
| `ceph -W cephadm` | Monitors the `cephadm` log in real-time to see orchestrator activities and errors. |

## 2. Common Deployment Issues

### 2.1 SSH Authentication Failures
One of the most common issues when adding hosts is SSH connectivity.

*   **Symptoms:** `ceph orch host add` fails with "Failed to connect" or "Permission denied" errors.
*   **Resolution:**
    1.  **Verify SSH Key:** Ensure `cephadm` has an SSH identity key:
        ```bash
        ceph config-key get mgr/cephadm/ssh_identity_key > ~/cephadm_private_key
        chmod 0600 ~/cephadm_private_key
        ```
    2.  **Check Public Key:** Ensure the Ceph public key is in the `/root/.ssh/authorized_keys` file on the target host:
        ```bash
        ceph cephadm get-pub-key >> /root/.ssh/authorized_keys
        ```
    3.  **Manual Test:** Try connecting manually from the bootstrap node:
        ```bash
        ssh -i ~/cephadm_private_key root@<target-host-ip>
        ```

### 2.2 CIDR Network Errors
Errors related to network inference often occur during bootstrap or when adding monitors.

*   **Symptoms:** Errors like `Failed to infer CIDR network` or `Must set public_network config option`.
*   **Resolution:** Explicitly set the public network for the cluster:
    ```bash
    ceph config set global public_network <your-network-cidr>
    # Example: ceph config set global public_network 192.168.0.0/24
    ```

### 2.3 OSD Deployment Issues
OSDs might fail to deploy if disks are not "clean" or if there are hardware issues.

*   **Symptoms:** `ceph orch device ls` shows devices as "unmanaged" or "locked," or OSDs fail to start.
*   **Resolution:**
    1.  **Zap the Disk:** If a disk was previously used, you may need to "zap" it to clear existing partitions (Warning: This destroys data on the disk):
        ```bash
        ceph orch device zap <hostname> <device-path>
        # Example: ceph orch device zap ceph1 /dev/sdb
        ```
    2.  **Check Logs:** View logs for a specific OSD daemon:
        ```bash
        cephadm logs --name osd.<id>
        ```

## 3. Advanced Troubleshooting Techniques

### 3.1 Pausing the Orchestrator
If `cephadm` is stuck in a loop or behaving unexpectedly, you can pause its background activities.
```bash
ceph orch pause
# To resume:
ceph orch resume
```

### 3.2 Accessing Daemon Logs via Journald
Since `cephadm` runs daemons in containers, logs are typically managed by `journald` on the host where the daemon is running.
```bash
# On the host running the daemon:
journalctl -u ceph-<cluster-fsid>@<daemon-name>.service
# Example: journalctl -u ceph-8c9b0072-67ca-11eb-af06-001a4a0002a0@mon.ceph0.service
```

### 3.3 Using the Admin Socket
For deep-level debugging of a specific daemon without going through the monitors:
```bash
# Enter the daemon's container:
cephadm enter --name <daemon-name>
# Use the admin socket (inside the container):
ceph --admin-daemon /var/run/ceph/ceph-<daemon-name>.asok config show
```

### 3.4 Manually Deploying a Manager (MGR)
If all MGR daemons are lost, the orchestrator will stop working. You must manually deploy one to restore functionality.
1.  Generate a minimal configuration: `ceph config generate-minimal-conf`
2.  Create an authentication entry: `ceph auth get-or-create mgr.<hostname> ...`
3.  Deploy using `cephadm --image <image-name> deploy ...` (refer to official docs for the full JSON structure required).

## 4. Health Check Reference

| Status | Meaning | Action |
| :--- | :--- | :--- |
| **HEALTH_OK** | Cluster is healthy. | No action needed. |
| **HEALTH_WARN** | Issues detected but cluster is still operational. | Run `ceph health detail` and address warnings (e.g., clock skew, nearly full OSDs). |
| **HEALTH_ERR** | Critical issues; data might be at risk or unavailable. | Immediate investigation required. Check for down OSDs or lost monitor quorum. |

---
**Note:** Always refer to the [official Ceph documentation](https://docs.ceph.com) for the most up-to-date troubleshooting procedures specific to your Ceph version.
