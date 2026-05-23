# Daily Operations: Provisioning and Managing Ceph

In an SRE interview, being able to explain your "day-to-day" work is just as important as your big projects. This guide refines your experience into a story about how you handle the end-to-end lifecycle of a Ceph storage cluster.

## The Story: "The Full-Stack Storage Lifecycle"
### How to use this in the interview:
When the interviewer asks, *"Walk me through your daily routine,"* you can say:
> "Typically, I start by checking my **Ceph Dashboard** to ensure the cluster is healthy and rebalancing correctly. If a developer needs a new volume for a Kubernetes app, I'll provision a **Ceph Block Device**. If they need S3-compatible storage, I set up a bucket via the **Object Gateway**. I use **Cephadm** to keep the whole environment updated and consistent, spend time on optimizing performance."

**Situation**
In my daily work as a storage and platform engineer, I don't just "fix" things when they break; I manage the entire lifecycle of our storage infrastructure. We needed a system that could handle everything from simple file shares to complex object storage for our cloud-native apps.

**Ceph Storage Clusters** are healthy, properly provisioned, and ready to serve whatever data the developers need—whether that’s a block device for a database or an object bucket for a web app.

“I first confirmed customer impact, checked dashboards and recent deploys, narrowed the failure domain, mitigated with rollback/traffic shift/config change, communicated status, then followed up with a postmortem and prevention work.”

**Action**
I handle the "ground up" operations using **Cephadm**. My daily workflow involves:
*   **Cluster Health & Management**: I use the **Ceph Dashboard** and **Ceph Manager (mgr)** to keep an eye on the cluster's "heartbeat." I check for rebalancing issues or slow OSDs before they impact performance.
*   **Provisioning on Demand**: Depending on the request, I provision the right type of storage:
    *   **Ceph Block Device (RBD)**: For high-performance needs like virtual machine disks or Kubernetes persistent volumes.
    *   **Ceph File System (CephFS)**: When teams need shared folders for collaboration or legacy apps.
    *   **Ceph Object Gateway (RGW)**: For modern, S3-compatible storage used by our developers for media and backups.
*   **Proactive Monitoring**: I don't wait for the dashboard to turn red. I use the **Monitoring Overview** to track capacity trends, ensuring we add new disks or nodes *before* we hit 80% utilization.

**Result**
By standardizing on Ceph and using modern tools like Cephadm, I’ve made our storage "invisible" to the developers—it just works. We’ve achieved a high level of uptime, and because I manage the full stack (Block, File, and Object), we can support any workload that comes our way with a single, unified platform.

---

## Technical Cheat Sheet for the Interviewer
If they dig deeper into your "Daily Tasks," here is how to explain the components simply:

| Component | Simple Explanation |
| :--- | :--- |
| **Cephadm** | The "installer and manager" that keeps the cluster running in containers. |
| **Ceph Manager (mgr)** | The "brain" that tracks metrics and runs the dashboard. |
| **RBD (Block)** | Like a virtual hard drive for a single server or container. |
| **CephFS (File)** | Like a giant shared folder that many servers can use at once. |
| **RGW (Object)** | Like our own private version of Amazon S3 for storing files and data. |
| **Dashboard** | My "mission control" for seeing the health of the whole system at a glance. |


