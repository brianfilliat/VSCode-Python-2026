Ceph Ansible Playbook
=====================

Purpose
- Collect diagnostics from Ceph MON/OSD hosts and optionally perform safe restarts of services.

Usage
- Ensure you have an inventory with groups `ceph_mons` and `ceph_osds` and relevant host variables (e.g., `osd_id`).
- Run:

```bash
ansible-playbook -i inventory ceph_diagnostics_and_safe_restart.yml -e "restart_services=false"
```

- To enable restarts (use with caution):

```bash
ansible-playbook -i inventory ceph_diagnostics_and_safe_restart.yml -e "restart_services=true"
```

Safety
- This playbook defaults to diagnostics-only. Never enable `restart_services=true` in production without approval and a rollback plan.
