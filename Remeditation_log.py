"""AWS incident remediation decision logic.

This module demonstrates two parts of an automated remediation workflow:

1. ``should_remediate`` decides whether a single normalized event should
   trigger remediation.
2. ``process_events`` shows a simple batch processor for raw AWS-like events.

System design notes:
- Processing should be stateless except for a shared state store. In AWS, a
  practical choice is DynamoDB keyed by resource_id, with fields like
  last_status, last_remediated, and last_event_timestamp.
- Remediation workers should perform conditional writes so only one Lambda wins
  the right to remediate a resource during the cooldown window.
- Automated actions should be idempotent where possible: restart EC2, reboot
  RDS, open/close tickets, etc.
- Each action should emit audit logs and metrics. Failures should go to a DLQ,
  retries should use backoff, and repeated failures should escalate to humans
  instead of looping forever.
- For distributed safety across 100 Lambdas, DynamoDB conditional updates are
  the main guardrail. For example: update only if no state exists, status
  changed, or cooldown expired.
- Add TTL to expire old resource state after some retention period.

Expected normalized event shape:
    {
        "resource_id": "i-123",
        "resource_type": "ec2",
        "status": "stopped",
        "timestamp": 1714290000,
    }

Expected state_store shape:
    {
        "i-123": {
            "last_remediated": 1714289900,
            "last_status": "stopped",
            "last_event_timestamp": 1714289900,
        }
    }
"""




    """Decide whether an event should trigger remediation.

    This function is intentionally stateful: when it returns ``True``, it also
    records the remediation decision in ``state_store``. That makes repeated
    calls with the same event idempotent in this local simulation.

    Decision rules:
    - Missing state allows remediation.
    - The same resource cannot be remediated more than once every 5 minutes.
    - A status change allows remediation even inside the cooldown window.
    - Older out-of-order events are ignored.
    - Malformed events fail closed and return ``False``.

    Args:
        event: Normalized event with resource_id, status, and timestamp.
        state_store: Mutable dictionary simulating durable per-resource state.

    Returns:
        ``True`` when remediation should run, otherwise ``False``.

    The state store simulates durable storage. In production, this update should
    be an atomic conditional write keyed by resource_id.
    """

COOLDOWN_SECONDS = 5 * 60

def should_remediate(event: dict, state_store: dict) -> bool:
    resource_id = event.get("resource_id")
    status = event.get("status")
    event_timestamp = event.get("timestamp")

    if not resource_id or not status or event_timestamp is None:
        return False

    current_state = state_store.get(resource_id)

    if current_state is None:
        state_store[resource_id] = {
            "last_remediated": event_timestamp,
            "last_status": status,
            "last_event_timestamp": event_timestamp,
        }
        return True

    last_status = current_state.get("last_status")
    last_remediated = current_state.get("last_remediated")
    last_event_timestamp = current_state.get("last_event_timestamp", last_remediated)

    if last_event_timestamp is not None and event_timestamp < last_event_timestamp:
        return False

    status_changed = status != last_status
    cooldown_elapsed = (
        last_remediated is None
        or event_timestamp - last_remediated >= COOLDOWN_SECONDS
    )

    if status_changed or cooldown_elapsed:
        current_state.update({
            "last_remediated": event_timestamp,
            "last_status": status,
            "last_event_timestamp": event_timestamp,
        })
        return True

    current_state["last_event_timestamp"] = event_timestamp
    return False
