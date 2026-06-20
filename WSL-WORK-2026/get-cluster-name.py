import os
from netapp_ontap import config, HostConnection
from netapp_ontap.resources import ClusterInfo

# Fetch credentials securely from RHEL environment
netapp_user = os.environ.get("ONTAP_USER")
netapp_pass = os.environ.get("ONTAP_PASS")

if not netapp_user or not netapp_pass:
    raise ValueError("Error: ONTAP_USER or ONTAP_PASS environment variables are not set!")

config.CONNECTION = HostConnection(
    host="192.168.1.50",
    username=netapp_user,
    password=netapp_pass,
    verify=False
)

try:
    cluster = ClusterInfo.get()
    print(f"Successfully verified REST API connection to: {cluster.name}")
except Exception as e:
    print(f"Connection failed: {e}")
