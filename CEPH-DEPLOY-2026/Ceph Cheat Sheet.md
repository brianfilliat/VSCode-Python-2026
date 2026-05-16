# Ceph Cheat Sheet

Ceph is a unified, distributed storage system providing **Object, Block, and File storage** from a single cluster.

## 🏗️ Core Architecture & Components
*   **RADOS (Reliable Autonomic Distributed Object Store):** The foundation of all Ceph clusters.
*   **Ceph OSD (Object Storage Daemon):** Stores data, handles replication, recovery, and rebalancing. (1 per disk)
*   **Ceph Monitor (MON):** Maintains cluster maps (Mon, OSD, PG, CRUSH) and ensures high availability via Paxos.
*   **Ceph Manager (MGR):** Provides monitoring, orchestration, and dashboard services.
*   **Ceph Metadata Server (MDS):** Stores metadata for CephFS (not needed for Block/Object).
*   **RADOS Gateway (RGW):** Object storage interface (S3/Swift compatible).
*   **CRUSH Algorithm:** Calculates data placement without a central lookup table.

---

## 🛠️ Essential CLI Commands

### 🩺 Cluster Health & Status
| Command | Description |
| :--- | :--- |
| `ceph health [detail]` | Check cluster health status |
| `ceph -s` / `ceph status` | Show cluster status summary |
| `ceph -w` | Watch cluster events in real-time |
| `ceph df` | Show cluster storage usage |
| `ceph osd tree` | View OSD hierarchy and status |

### 💾 Pool Management
| Command | Description |
| :--- | :--- |
| `ceph osd lspools` | List all pools |
| `ceph osd pool create <name> <pg_num>` | Create a new pool |
| `ceph osd pool delete <name> <name> --yes-i-really-really-mean-it` | Delete a pool |
| `ceph osd pool rename <old> <new>` | Rename a pool |
| `ceph osd pool set <name> size <num>` | Set replica count |

### 🔧 OSD Management
| Command | Description |
| :--- | :--- |
| `ceph osd stat` | Show OSD status summary |
| `ceph osd out <id>` | Mark OSD as out (starts rebalancing) |
| `ceph osd in <id>` | Mark OSD as in |
| `ceph osd down <id>` | Force OSD status to down |
| `ceph osd df` | Show utilization per OSD |

### 📂 Storage Interfaces
*   **Block (RBD):** `rbd create <img_name> --size <MB>`, `rbd ls`, `rbd map <img_name>`
*   **File (CephFS):** `ceph fs ls`, `ceph fs status`, `mount -t ceph <mon_ip>:/ <mnt_pt>`
*   **Object (RGW):** Managed via `radosgw-admin` (e.g., `radosgw-admin user create`)

---

## 🔍 Troubleshooting & Monitoring
*   **Logs:** Usually in `/var/log/ceph/`
*   **Check Auth:** `ceph auth list`
*   **PG Status:** `ceph pg stat`, `ceph pg dump`
*   **Check Versions:** `ceph versions`
*   **Monitor Quorum:** `ceph mon stat`
