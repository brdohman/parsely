#!/bin/bash
set -euo pipefail

# ConfigChange hook — log configuration changes for audit trail
# Non-blocking (exit 0 always)

INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
LOG_FILE="$LOG_DIR/config-changes.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

echo "$TIMESTAMP | source=$SOURCE | file=$FILE_PATH" >> "$LOG_FILE"

exit 0
