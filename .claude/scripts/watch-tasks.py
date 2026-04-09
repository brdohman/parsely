#!/usr/bin/env python3
"""
Watch an entire tasks directory for changes in real-time.
Usage: python3 watch-tasks.py <tasks-dir> [--log <logfile>]

Examples:
  python3 watch-tasks.py /Volumes/johnsmith/.claude/tasks/mac-os-banking-app
  python3 watch-tasks.py /Volumes/johnsmith/.claude/tasks/mac-os-banking-app --log /tmp/task-changes.jsonl

Monitors ALL .json files in the directory every 2 seconds.
Prints every change with full before/after diff.
Optionally logs every change as JSONL for later analysis.
"""

import json
import sys
import time
import os
from datetime import datetime
from pathlib import Path
from copy import deepcopy

def read_task(filepath):
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return None

def get_nested(data, path):
    keys = [k for k in path.split('.') if k]
    current = data
    for key in keys:
        if isinstance(current, dict) and key in current:
            current = current[key]
        else:
            return None
    return current

def diff_dicts(old, new, path=""):
    """Recursively find differences between two dicts. Returns list of (path, old_val, new_val)."""
    changes = []
    if old is None:
        old = {}
    if new is None:
        new = {}

    all_keys = set(list(old.keys()) + list(new.keys()))
    for key in sorted(all_keys):
        full_path = f"{path}.{key}" if path else key
        old_val = old.get(key)
        new_val = new.get(key)

        if old_val == new_val:
            continue

        # Special handling for comments array — show new entries only
        if key == "comments" and isinstance(old_val, list) and isinstance(new_val, list):
            if len(new_val) > len(old_val):
                for i in range(len(old_val), len(new_val)):
                    comment = new_val[i]
                    c_type = comment.get('type', '?')
                    c_author = comment.get('author', '?')
                    c_content = (comment.get('content', '')[:120] + '...') if len(comment.get('content', '')) > 120 else comment.get('content', '')
                    changes.append((f"{full_path}[{i}]", None, f"NEW {c_type} by {c_author}: {c_content}"))
            elif len(new_val) < len(old_val):
                changes.append((full_path, f"{len(old_val)} comments", f"{len(new_val)} comments (REMOVED)"))
            else:
                changes.append((full_path, f"{len(old_val)} comments", f"{len(new_val)} comments (modified)"))
            continue

        if isinstance(old_val, dict) and isinstance(new_val, dict):
            changes.extend(diff_dicts(old_val, new_val, full_path))
        elif isinstance(old_val, list) and isinstance(new_val, list):
            if old_val != new_val:
                changes.append((full_path, f"[{len(old_val)} items]", f"[{len(new_val)} items]"))
        else:
            changes.append((full_path, old_val, new_val))

    return changes

def format_summary(data):
    if not data:
        return "?"
    task_id = data.get('id', '?')
    status = data.get('status', '?')
    subject = data.get('subject', 'untitled')[:60]
    review_stage = get_nested(data, 'metadata.review_stage') or '-'
    review_result = get_nested(data, 'metadata.review_result') or '-'
    return f"[{status}] {subject} (stage={review_stage} result={review_result})"

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 watch-tasks.py <tasks-dir> [--log <logfile>]")
        sys.exit(1)

    tasks_dir = Path(sys.argv[1])
    log_file = None

    if "--log" in sys.argv:
        log_idx = sys.argv.index("--log")
        if log_idx + 1 < len(sys.argv):
            log_file = open(sys.argv[log_idx + 1], 'a')

    if not tasks_dir.exists():
        print(f"ERROR: Directory not found: {tasks_dir}")
        sys.exit(1)

    print(f"Watching: {tasks_dir}")
    print(f"Logging to: {log_file.name if log_file else 'stdout only'}")
    print(f"Polling every 2 seconds. Ctrl+C to stop.")
    print("=" * 100)

    # Initial snapshot
    snapshots = {}  # filename -> {data, mtime}
    change_count = 0
    check_count = 0

    # Load initial state
    for f in sorted(tasks_dir.glob("*.json")):
        data = read_task(f)
        mtime = os.path.getmtime(f)
        snapshots[f.name] = {"data": data, "mtime": mtime}
        if data:
            task_num = f.stem
            print(f"  {task_num:>4}: {format_summary(data)}")

    print(f"\nTracking {len(snapshots)} task files. Waiting for changes...\n")

    try:
        while True:
            check_count += 1
            now = datetime.now()
            now_str = now.strftime("%H:%M:%S.%f")[:-3]
            now_iso = now.isoformat()

            current_files = set(f.name for f in tasks_dir.glob("*.json"))
            known_files = set(snapshots.keys())

            # Detect new files
            for fname in sorted(current_files - known_files):
                fpath = tasks_dir / fname
                data = read_task(fpath)
                mtime = os.path.getmtime(fpath)
                snapshots[fname] = {"data": data, "mtime": mtime}
                change_count += 1
                task_num = Path(fname).stem
                subject = data.get('subject', '?') if data else '?'
                print(f"[{now_str}] NEW FILE: {task_num} — {subject}")

                if log_file:
                    log_entry = {"timestamp": now_iso, "event": "new_file", "task": task_num, "subject": subject, "data": data}
                    log_file.write(json.dumps(log_entry) + "\n")
                    log_file.flush()

            # Detect deleted files
            for fname in sorted(known_files - current_files):
                task_num = Path(fname).stem
                old_data = snapshots[fname].get("data", {})
                subject = old_data.get('subject', '?') if old_data else '?'
                del snapshots[fname]
                change_count += 1
                print(f"[{now_str}] DELETED: {task_num} — {subject}")

                if log_file:
                    log_entry = {"timestamp": now_iso, "event": "deleted", "task": task_num, "subject": subject}
                    log_file.write(json.dumps(log_entry) + "\n")
                    log_file.flush()

            # Check existing files for changes
            for fname in sorted(current_files & known_files):
                fpath = tasks_dir / fname
                current_mtime = os.path.getmtime(fpath)
                old_mtime = snapshots[fname]["mtime"]

                if current_mtime == old_mtime:
                    continue

                # File was modified — read and diff
                current_data = read_task(fpath)
                old_data = snapshots[fname]["data"]
                task_num = Path(fname).stem

                if current_data == old_data:
                    # mtime changed but content identical (touch without write)
                    snapshots[fname]["mtime"] = current_mtime
                    continue

                # Real content change
                change_count += 1
                changes = diff_dicts(old_data or {}, current_data or {})
                subject = (current_data or {}).get('subject', '?')[:50]

                print(f"[{now_str}] CHANGED: task {task_num} — {subject}")
                for field_path, old_val, new_val in changes:
                    old_display = json.dumps(old_val) if not isinstance(old_val, str) else old_val
                    new_display = json.dumps(new_val) if not isinstance(new_val, str) else new_val
                    # Truncate long values
                    if isinstance(old_display, str) and len(old_display) > 80:
                        old_display = old_display[:80] + "..."
                    if isinstance(new_display, str) and len(new_display) > 80:
                        new_display = new_display[:80] + "..."
                    print(f"           {field_path}: {old_display} → {new_display}")

                if log_file:
                    log_entry = {
                        "timestamp": now_iso,
                        "event": "changed",
                        "task": task_num,
                        "subject": subject,
                        "changes": [{"field": p, "old": o, "new": n} for p, o, n in changes],
                        "full_data": current_data
                    }
                    log_file.write(json.dumps(log_entry, default=str) + "\n")
                    log_file.flush()

                snapshots[fname] = {"data": deepcopy(current_data), "mtime": current_mtime}

            # Heartbeat every 60s
            if check_count % 30 == 0:
                print(f"[{now_str}] heartbeat — {len(snapshots)} files, {change_count} changes detected so far")

            time.sleep(2)

    except KeyboardInterrupt:
        elapsed = check_count * 2
        mins = elapsed // 60
        secs = elapsed % 60
        print(f"\nStopped after {mins}m {secs}s ({check_count} checks, {change_count} changes detected)")
        if log_file:
            log_file.close()
            print(f"Log saved to: {sys.argv[sys.argv.index('--log') + 1]}")

if __name__ == "__main__":
    main()
