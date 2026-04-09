#!/usr/bin/env python3
"""
Watch a task JSON file for changes in real-time.
Usage: python3 watch-task.py <tasks-dir> <task-id> [field]

Examples:
  python3 watch-task.py /Volumes/johnsmith/.claude/tasks/mac-os-banking-app 53
  python3 watch-task.py /Volumes/johnsmith/.claude/tasks/mac-os-banking-app 53 .metadata.review_result

Monitors the file every 2 seconds and prints when ANY field changes.
If a specific field is given, highlights that field's value on each check.
"""

import json
import sys
import time
import os
from datetime import datetime
from pathlib import Path

def read_task(filepath):
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError) as e:
        return None

def get_nested(data, path):
    """Get a nested value using dot notation like .metadata.review_result"""
    keys = [k for k in path.split('.') if k]
    current = data
    for key in keys:
        if isinstance(current, dict) and key in current:
            current = current[key]
        else:
            return None
    return current

def get_mtime(filepath):
    try:
        return os.path.getmtime(filepath)
    except OSError:
        return 0

def format_summary(data):
    """Extract key fields for display"""
    status = data.get('status', '?')
    approval = get_nested(data, '.metadata.approval') or '?'
    review_stage = get_nested(data, '.metadata.review_stage') or 'null'
    review_result = get_nested(data, '.metadata.review_result') or 'null'
    claimed_by = get_nested(data, '.metadata.claimed_by') or '-'
    comment_count = len(get_nested(data, '.metadata.comments') or [])
    return f"status={status} | approval={approval} | review_stage={review_stage} | review_result={review_result} | claimed_by={claimed_by} | comments={comment_count}"

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 watch-task.py <tasks-dir> <task-id> [field]")
        print("  tasks-dir: path to ~/.claude/tasks/<project>/")
        print("  task-id:   numeric task ID")
        print("  field:     optional jq-style path (e.g. .metadata.review_result)")
        sys.exit(1)

    tasks_dir = sys.argv[1]
    task_id = sys.argv[2]
    watch_field = sys.argv[3] if len(sys.argv) > 3 else None

    filepath = Path(tasks_dir) / f"{task_id}.json"

    if not filepath.exists():
        print(f"ERROR: File not found: {filepath}")
        sys.exit(1)

    print(f"Watching: {filepath}")
    if watch_field:
        print(f"Tracking field: {watch_field}")
    print(f"Polling every 2 seconds. Ctrl+C to stop.")
    print("=" * 80)

    last_mtime = 0
    last_data = None
    last_field_value = None
    check_count = 0

    try:
        while True:
            check_count += 1
            now = datetime.now().strftime("%H:%M:%S")
            current_mtime = get_mtime(filepath)
            current_data = read_task(filepath)

            if current_data is None:
                print(f"[{now}] #{check_count} — ERROR reading file")
                time.sleep(2)
                continue

            # Check if file was modified on disk
            file_changed = current_mtime != last_mtime

            # Check if content actually changed
            content_changed = current_data != last_data

            # Check watched field
            if watch_field:
                current_field = get_nested(current_data, watch_field)
                field_changed = current_field != last_field_value

                if field_changed or check_count == 1:
                    marker = ">>> CHANGED <<<" if (field_changed and check_count > 1) else "(initial)"
                    print(f"[{now}] #{check_count} — {watch_field} = {json.dumps(current_field)}  {marker}")
                    last_field_value = current_field

                elif check_count % 15 == 0:  # Heartbeat every 30s
                    print(f"[{now}] #{check_count} — {watch_field} = {json.dumps(current_field)}  (no change, file_mod={'yes' if file_changed else 'no'})")

            else:
                # No specific field — report any change
                if content_changed or check_count == 1:
                    summary = format_summary(current_data)
                    marker = ">>> CHANGED <<<" if (content_changed and check_count > 1) else "(initial)"
                    print(f"[{now}] #{check_count} — {summary}  {marker}")

                elif check_count % 15 == 0:
                    summary = format_summary(current_data)
                    print(f"[{now}] #{check_count} — {summary}  (no change, file_mod={'yes' if file_changed else 'no'})")

            if file_changed and not content_changed and check_count > 1:
                print(f"[{now}] #{check_count} — NOTE: file mtime changed but content identical")

            last_mtime = current_mtime
            last_data = current_data
            time.sleep(2)

    except KeyboardInterrupt:
        print(f"\nStopped after {check_count} checks ({check_count * 2}s)")
        if last_data:
            print(f"Final state: {format_summary(last_data)}")

if __name__ == "__main__":
    main()
