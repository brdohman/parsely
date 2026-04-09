#!/bin/bash
set -euo pipefail

# review-gate.sh
# PreToolUse hook (TaskUpdate matcher) — blocks QA transition if review artifacts missing
#
# Triggers when: TaskUpdate sets metadata.review_stage to "qa"
# Checks: tools/third-party-reviews/<branch>/ has aikido + coderabbit files
# Exit 0 = allow, Exit 2 = block with feedback

# Read hook input from stdin
INPUT=$(cat)

# Extract review_stage from the TaskUpdate metadata
# Handle both direct object and stringified metadata
REVIEW_STAGE=$(echo "$INPUT" | jq -r '.tool_input.metadata.review_stage // empty' 2>/dev/null || echo "")

# Only gate QA transitions
if [ "$REVIEW_STAGE" != "qa" ]; then
    exit 0
fi

# Determine review level from task type (epic vs story)
TASK_TYPE=$(echo "$INPUT" | jq -r '.tool_input.metadata.type // empty' 2>/dev/null || echo "")
LEVEL="story"
if [ "$TASK_TYPE" = "epic" ]; then
    LEVEL="epic"
fi

# Run verification script
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
VERIFY_SCRIPT="$PROJECT_DIR/.claude/scripts/verify-review-artifacts.sh"

if [ ! -x "$VERIFY_SCRIPT" ]; then
    echo "WARNING: verify-review-artifacts.sh not found or not executable. Allowing transition." >&2
    exit 0
fi

VERIFY_OUTPUT=$("$VERIFY_SCRIPT" --level "$LEVEL" 2>&1) || {
    echo "BLOCKED: Cannot advance to QA — review artifacts are missing." >&2
    echo "" >&2
    echo "$VERIFY_OUTPUT" >&2
    echo "" >&2
    echo "Before advancing to QA, ensure review agents saved output via:" >&2
    echo "  echo \"\$OUTPUT\" | .claude/scripts/save-review.sh aikido" >&2
    echo "  echo \"\$OUTPUT\" | .claude/scripts/save-review.sh coderabbit" >&2
    exit 2
}

exit 0
