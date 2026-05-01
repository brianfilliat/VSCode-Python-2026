
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


def process_events(events: list[dict]) -> list[dict]:
    """Convert raw AWS-style events into remediation actions.

    This helper demonstrates simple batch processing and in-batch
    deduplication. It currently understands:
    - EC2 stopped events, which produce restart_instance actions.
    - RDS failed events, which produce reboot_database actions.

    Args:
        events: List of raw AWS-like events containing source and detail data.

    Returns:
        List of action dictionaries describing what remediation should run.
    """
    actions = []
    seen = set()  # (resource_id, state/status)

    for event in events:
        source = event.get("source")
        detail = event.get("detail", {})

        if source == "aws.ec2":
            resource_id = detail.get("instance-id")
            state = detail.get("state")

            if state == "stopped" and resource_id:
                key = (resource_id, state)
                if key not in seen:
                    seen.add(key)
                    actions.append({
                        "resource_id": resource_id,
                        "resource_type": "ec2",
                        "action": "restart_instance"
                    })

        elif source == "aws.rds":
            resource_id = detail.get("db-instance-id")
            status = detail.get("status")

            if status == "failed" and resource_id:
                key = (resource_id, status)
                if key not in seen:
                    seen.add(key)
                    actions.append({
                        "resource_id": resource_id,
                        "resource_type": "rds",
                        "action": "reboot_database"
                    })

    return actions





