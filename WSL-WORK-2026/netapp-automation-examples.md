# ---
# ==============================================================================
# Playbook: netapp_automation_example.yml
# Description: Advanced NetApp ONTAP Storage Management & Automation.
#              This playbook showcases production practices for enterprise 
#              storage administration using the official 'netapp.ontap' Ansible
#              collection, targeting the hosts in 'netapp_clusters' inventory.
#
# Operations Included:
# 1. Gather ONTAP Cluster & Node Facts
# 2. Manage Volume Snapshots (On-Demand)
# 3. Enable FlexVol Volume Autosize (Prevent Out-Of-Space Issues)
# 4. Create Qtrees (Logical Volume Sub-directories)
# 5. Define and Enforce Storage Quotas on Qtrees
# 6. Apply Snapshot Policy Schedules to Volumes
# ==============================================================================

- name: Advanced NetApp ONTAP Storage Management
  hosts: netapp_clusters
  gather_facts: false
  collections:
    - netapp.ontap
  vars_files:
    - vault.yml  # Holds vault_netapp_username and vault_netapp_password

  vars:
    # Storage Resource References (Matches site.yml / provision_storage.yml)
    svm_name: "rhel9_app_svm"
    vol_name: "nfs_data_vol"
    
    # Advanced Automation parameters
    snapshot_name: "pre_migration_backup_snap"
    qtree_name: "app_logs_qtree"
    quota_limit: "10GB"
    snapshot_policy_name: "default-1day-keep7"

  tasks:
    # ==========================================
    # TASK 1: GATHER ONTAP CLUSTER FACTS
    # ==========================================
    - name: 1. Gather ONTAP Cluster and Node Details
      netapp.ontap.na_ontap_cluster_info:
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"
      register: cluster_info

    - name: Display ONTAP Cluster Details
      ansible.builtin.debug:
        msg:
          - "Cluster Name: {{ cluster_info.ontap_info.cluster_identity_info.cluster_name }}"
          - "ONTAP Version: {{ cluster_info.ontap_info.cluster_version_info.version_string }}"

    # ==========================================
    # TASK 2: ON-DEMAND SNAPSHOT CREATION
    # ==========================================
    - name: 2. Create on-demand Snapshot for Pre-migration safety
      netapp.ontap.na_ontap_snapshot:
        state: present
        volume: "{{ vol_name }}"
        vserver: "{{ svm_name }}"
        snapshot: "{{ snapshot_name }}"
        comment: "Snapshot created automatically via Ansible before migration copy"
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"

    # ==========================================
    # TASK 3: FLEXVOL AUTOSIZE CONFIGURATION (Grow / Shrink)
    # ==========================================
    - name: 3. Configure Volume Autosize Rules
      netapp.ontap.na_ontap_volume_autosize:
        state: present
        volume: "{{ vol_name }}"
        vserver: "{{ svm_name }}"
        mode: grow_shrink                         # Automatically grow and shrink
        grow_threshold_percent: 85                # Grow when volume reaches 85% full
        shrink_threshold_percent: 50              # Shrink when volume drops below 50%
        maximum_size: 500gb                       # Limit maximum expansion to 500 GB
        minimum_size: 100gb                       # Limit minimum contraction to 100 GB
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"

    # ==========================================
    # TASK 4: QTREE PROVISIONING
    # ==========================================
    - name: 4. Create Qtree inside the FlexVol Volume
      netapp.ontap.na_ontap_qtree:
        state: present
        vserver: "{{ svm_name }}"
        flexvol_name: "{{ vol_name }}"
        name: "{{ qtree_name }}"
        security_style: unix                      # Standard UNIX security settings for RHEL clients
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"

    # ==========================================
    # TASK 5: STORAGE QUOTA MANAGEMENT
    # ==========================================
    - name: 5. Create Storage Quota Rule for Qtree
      netapp.ontap.na_ontap_quota:
        state: present
        vserver: "{{ svm_name }}"
        volume: "{{ vol_name }}"
        quota_target: "{{ qtree_name }}"
        quota_type: tree                          # Target is the Qtree
        policy: default                           # Use the default SVM quota policy
        disk_limit: "{{ quota_limit }}"          # Maximum disk space allowed
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"

    # ==========================================
    # TASK 6: ASSIGN SNAPSHOT POLICY TO VOLUME
    # ==========================================
    - name: 6. Assign Snapshot Policy Schedule to Volume
      netapp.ontap.na_ontap_volume:
        state: present
        name: "{{ vol_name }}"
        vserver: "{{ svm_name }}"
        snapshot_policy: "{{ snapshot_policy_name }}"
        hostname: "{{ ansible_host }}"
        username: "{{ netapp_username }}"
        password: "{{ netapp_password }}"
        https: "{{ https }}"
        validate_certs: "{{ validate_certs }}"
