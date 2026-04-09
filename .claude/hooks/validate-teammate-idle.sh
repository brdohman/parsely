#!/bin/bash
# validate-teammate-idle.sh
# TeammateIdle hook — checks teammate state before allowing idle
# Exit code 0 = allow idle
# Exit code 2 = block idle (feedback sent to teammate)

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

TEAMMATE_NAME=$(echo "$INPUT" | jq -r '.teammate_name // empty')
TEAM_NAME=$(echo "$INPUT" | jq -r '.team_name // empty')

if [ -z "$TEAMMATE_NAME" ] || [ -z "$TEAM_NAME" ]; then
  exit 0
fi

# Resolve task list
TASK_LIST_ID="${CLAUDE_CODE_TASK_LIST_ID:-$TEAM_NAME}"
TASKS_DIR="$HOME/.claude/tasks/$TASK_LIST_ID"

if [ ! -d "$TASKS_DIR" ]; then
  exit 0
fi

# Check for tasks claimed by this teammate that are still in_progress
IN_PROGRESS_TASKS=""
for task_file in "$TASKS_DIR"/*.json; do
  [ -f "$task_file" ] || continue

  STATUS=$(jq -r '.status // empty' "$task_file")
  CLAIMED_BY=$(jq -r '.metadata.claimed_by // empty' "$task_file")
  TASK_TYPE=$(jq -r '.metadata.type // empty' "$task_file")
  SUBJECT=$(jq -r '.subject // empty' "$task_file")

  # Only check tasks (not stories/epics)
  if [ "$TASK_TYPE" != "task" ]; then
    continue
  fi

  # Check if this teammate owns an in_progress task without completion comments
  if [ "$STATUS" = "in_progress" ] && echo "$CLAIMED_BY" | grep -qi "$TEAMMATE_NAME"; then
    COMMENTS=$(jq -r '.metadata.comments // []' "$task_file")
    HAS_IMPLEMENTATION=$(echo "$COMMENTS" | jq '[.[] | select(.type == "implementation")] | length')

    if [ "$HAS_IMPLEMENTATION" -eq 0 ]; then
      IN_PROGRESS_TASKS="$IN_PROGRESS_TASKS\n- $SUBJECT"
    fi
  fi
done

if [ -n "$IN_PROGRESS_TASKS" ]; then
  echo "BLOCKED: You have in-progress tasks without implementation comments:" >&2
  echo -e "$IN_PROGRESS_TASKS" >&2
  echo "" >&2
  echo "Either complete these tasks (add implementation + testing comments and mark completed) or add a status note explaining why you're stopping." >&2
  exit 2
fi

exit 0
