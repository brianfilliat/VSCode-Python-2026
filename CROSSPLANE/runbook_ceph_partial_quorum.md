# Runbook: Ceph Partial Quorum / Degraded PGs

**Purpose:** Provide step-by-step, safe remediation for a Ceph cluster that has lost partial quorum or shows degraded/unclean PGs due to unreachable MONs/OSDs or network partition.

**Scope:** Applies to production and staging Ceph clusters used for block, file, or object storage. Assumes operator access to Ceph CLI and cluster management (SSH, orchestration).

**Assumptions & Prerequisites**
- Operator has `ceph` CLI access and appropriate privileges.
- Access to cluster monitoring (Prometheus/Grafana) and alerting (Alertmanager).
- Known inventory of MONs, MGRs, OSDs and their hostnames/IPs.
- Runbook author and on-call contacts are available for escalation.

**When to use:** Trigger this runbook when alerts indicate `CEPH_HEALTH_WARN` or `CEPH_HEALTH_ERR`, PGs are `degraded` or `unclean`, or `ceph -s` shows missing quorum or lost MONs/OSDs.

---

1) Initial Triage (first 5–10 minutes)
- Confirm alert details and scope: which pools, tenants, or clients are affected.
- Run basic cluster status commands and capture output (save to incident log):

```
ceph -s
ceph health detail
ceph mon stat
ceph osd stat
ceph osd tree
ceph pg stat
ceph pg dump pgs_brief | head -n 50
```

- Note: copy outputs into the incident ticket for RCA.

2) Determine Cause — node vs network vs process
- Check MON health: Are any MONs down or lost quorum? `ceph mon stat` and `/var/log/ceph/ceph-mon.*.log` on host.
- Check OSD status: `ceph osd tree` and `ceph osd out`/`ceph osd down` lists. On hosts, check `systemctl status ceph-osd@<id>` and daemon logs.
- Check network reachability: ping/TCP to MON and OSD addresses, check switch/MTU/segmentation and recent network changes.
- Check for disk/host-level failures: `smartctl`, dmesg, and RAID/controller events on hosts with failed OSDs.

3) Containment (safety-first)
- Do NOT immediately rm OSDs or forcefully change CRUSH unless you confirm permanent hardware loss.
- If the cluster has split-brain risk (multiple isolated partitions), stop any automated maintenance or orchestrator jobs that may `rm` OSDs.
- If clients are suffering, consider mounting blackholing or read-only gating only after discussion with app owners.

4) Safe Remediation Steps

- A) If MONs are down but hosts are reachable:
  1. SSH to MON host(s). Check `systemctl status ceph-mon@<name>` and logs.
  2. Attempt to start/restart MON service: `sudo systemctl restart ceph-mon@<name>` or use orchestrator: `ceph orch restart mon.<name>`.
  3. Wait and re-check quorum: `ceph mon stat` and `ceph -s`.

- B) If OSDs are down but hosts are healthy:
  1. On host, check the OSD process: `sudo systemctl status ceph-osd@<id>` and `journalctl -u ceph-osd@<id> -n 200`.
  2. If OSD process crashed, attempt a graceful restart: `sudo systemctl restart ceph-osd@<id>`.
  3. If device is missing (ZFS/LVM/blk errors), investigate host storage stack and fix underlying device before reintroducing OSD.

- C) If OSDs are unreachable due to network partition:
  1. Work with network team to restore connectivity (BGP, VLAN, MTU, firewall). If immediate fix not possible, follow D below.

- D) If OSDs are permanently failed (confirmed hardware failure) — conservative flow:
  1. Mark OSD out so data will rebalance: `ceph osd out <id>`.
  2. Verify PG recovery progress: `ceph -w` (monitor PGs).
  3. After PGs are back to `active+clean` and rebuilds finish, remove OSD from CRUSH and Ceph inventory if replacement is planned:
     - `ceph osd crush remove osd.<id>`
     - `ceph osd rm <id>`
     - Remove host-level config and replace disk/drive/host.
  4. Add replacement OSDs following standard provisioning playbook and allow rebalance.

- E) If cluster is in split-brain or quorum cannot be re-established safely:
  1. Do NOT use `ceph mon remove` or `ceph quorum` tricks without advisory from senior storage engineer or vendor.
  2. Contact on-call senior engineer or vendor support (see escalation contacts below).

5) Verification
- After each remediation step, confirm:
  - `ceph -s` shows HEALTH_OK or improved state.
  - `ceph pg stat` shows `active+clean` and recovery/backfill is zero.
  - Application-level verification: run test reads/writes against affected pools using `rados bench` or app test harness.

6) Post-Incident Actions
- Communicate: Update incident ticket with timeline, actions taken, and current status.
- Root cause analysis: Collect logs, timeline, and correlate with network/storage changes.
- Remediation tasks: Replace failed hardware, improve monitoring, and add automation to detect/prevent recurrence.
- Runbook update: Add any new checks, commands, or steps discovered during the incident.

7) Escalation Contacts
- On-call Storage Lead: [Name] — pager/email
- Network Team: [Team contact]
- Ceph Vendor/Support: [Support channel]

8) Automation Hooks
- Alertmanager webhook -> run playbook that collects cluster diagnostics and opens incident ticket.
- Safe remediation script (example): `ansible playbook ceph-restart-mons.yml --limit mon_hosts` — run only after approval.

9) Testing the Runbook
- Schedule monthly tabletop drills where an incident owner runs through detection and step 4 actions in a lab/staging cluster.
- Validate all commands in staging and update time estimates in runbook.

10) Safety & Recovery Notes
- Never rm OSDs unless hardware is permanently lost and you understand the capacity and rebuild window.
- Always maintain backups of critical RADOS Gateway metadata (if using RGW multisite) before any destructive action.

---

Appendix — Quick Command Cheat Sheet
- Cluster overview: `ceph -s`
- MON status: `ceph mon stat`
- OSD tree: `ceph osd tree`
- OSD status: `ceph osd stat`
- PG summary: `ceph pg stat` / `ceph pg dump pgs_brief`
- Mark OSD out: `ceph osd out <id>`
- Remove OSD from crush: `ceph osd crush remove osd.<id>`
- Remove OSD from cluster: `ceph osd rm <id>`
- Restart OSD: `systemctl restart ceph-osd@<id>` or `ceph orch restart osd.<id>`
