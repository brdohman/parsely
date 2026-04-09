#!/bin/bash
# validate-task-completion.sh
# TaskCompleted hook — blocks task completion if required comments are missing
# Exit code 0 = allow completion
# Exit code 2 = block completion (feedback sent to agent)

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

TASK_ID=$(echo "$INPUT" | jq -r '.task_id // empty')
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty')

if [ -z "$TASK_ID" ]; then
  exit 0
fi

# Resolve task file path
TASK_LIST_ID="${CLAUDE_CODE_TASK_LIST_ID:-}"
if [ -z "$TASK_LIST_ID" ]; then
  exit 0  # No task list configured, skip validation
fi

TASK_FILE="$HOME/.claude/tasks/$TASK_LIST_ID/$TASK_ID.json"
if [ ! -f "$TASK_FILE" ]; then
  exit 0  # Task file not found, skip
fi

# Read task metadata
TASK_TYPE=$(jq -r '.metadata.type // empty' "$TASK_FILE")
COMMENTS=$(jq -r '.metadata.comments // []' "$TASK_FILE")

# Only validate tasks (not stories/epics which have different completion paths)
if [ "$TASK_TYPE" != "task" ]; then
  exit 0
fi

# Check for implementation comment
HAS_IMPLEMENTATION=$(echo "$COMMENTS" | jq '[.[] | select(.type == "implementation")] | length')
if [ "$HAS_IMPLEMENTATION" -eq 0 ]; then
  echo "BLOCKED: Task '$TASK_SUBJECT' is missing an implementation comment." >&2
  echo "Add a comment with type: 'implementation' describing what was built and which files were changed." >&2
  exit 2
fi

# Check for testing comment (unless marked as not testable)
TESTABLE=$(jq -r '.metadata.testable // "true"' "$TASK_FILE")
if [ "$TESTABLE" != "false" ]; then
  HAS_TESTING=$(echo "$COMMENTS" | jq '[.[] | select(.type == "testing")] | length')
  if [ "$HAS_TESTING" -eq 0 ]; then
    echo "BLOCKED: Task '$TASK_SUBJECT' is missing a testing comment." >&2
    echo "Add a comment with type: 'testing' describing what was tested and how." >&2
    exit 2
  fi
fi

# --- Git state check: block completion if uncommitted Swift changes exist ---
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

  # Only enforce on epic branches (not on main during setup, etc.)
  if echo "$CURRENT_BRANCH" | grep -q "^epic/"; then
    DIRTY_SWIFT=$(git diff --name-only HEAD -- '*.swift' 2>/dev/null || echo "")
    STAGED_UNCOMMITTED=$(git diff --cached --name-only -- '*.swift' 2>/dev/null || echo "")

    if [ -n "$DIRTY_SWIFT" ] || [ -n "$STAGED_UNCOMMITTED" ]; then
      echo "BLOCKED: Task '$TASK_SUBJECT' has uncommitted Swift changes." >&2
      echo "" >&2
      if [ -n "$STAGED_UNCOMMITTED" ]; then
        echo "Staged but uncommitted:" >&2
        echo "$STAGED_UNCOMMITTED" | while read -r f; do echo "  - $f" >&2; done
      fi
      if [ -n "$DIRTY_SWIFT" ]; then
        echo "Modified but not staged:" >&2
        echo "$DIRTY_SWIFT" | while read -r f; do echo "  - $f" >&2; done
      fi
      echo "" >&2
      echo "Stage and commit your changes before marking the task complete:" >&2
      echo "  git add <files> && git commit -m \"feat(scope): description (task-$TASK_ID)\"" >&2
      exit 2
    fi
  fi
fi

exit 0
