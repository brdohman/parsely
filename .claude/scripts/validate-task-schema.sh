#!/bin/bash
# validate-task-schema.sh — Validate task JSON files against v2.0 schema
#
# Usage:
#   .claude/scripts/validate-task-schema.sh                    # Validate all tasks
#   .claude/scripts/validate-task-schema.sh <task-id>          # Validate one task
#   .claude/scripts/validate-task-schema.sh --summary          # Count pass/fail only
#
# Checks:
#   - schema_version is "2.0"
#   - Required fields exist for type (epic/story/task/bug/techdebt)
#   - Workflow fields are valid combinations
#   - Comments array is well-formed
#   - Prohibited fields are absent

set -euo pipefail

TASK_LIST_ID="${CLAUDE_CODE_TASK_LIST_ID:-}"
if [ -z "$TASK_LIST_ID" ]; then
    echo "ERROR: CLAUDE_CODE_TASK_LIST_ID not set" >&2
    exit 1
fi

TASKS_DIR="$HOME/.claude/tasks/$TASK_LIST_ID"
if [ ! -d "$TASKS_DIR" ]; then
    echo "ERROR: Task directory not found: $TASKS_DIR" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "ERROR: jq required. Install: brew install jq" >&2
    exit 1
fi

MODE="full"
TARGET_ID=""
PASS=0
FAIL=0
WARNINGS=0

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --summary) MODE="summary"; shift ;;
        *) TARGET_ID="$1"; shift ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { [ "$MODE" = "full" ] && echo -e "  ${GREEN}[OK]${NC} $1"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { [ "$MODE" = "full" ] && echo -e "  ${YELLOW}[WARN]${NC} $1"; WARNINGS=$((WARNINGS + 1)); }

validate_task() {
    local file="$1"
    local id
    id=$(jq -r '.id // "unknown"' "$file")
    local subject
    subject=$(jq -r '.subject // "untitled"' "$file")
    local type
    type=$(jq -r '.metadata.type // "unknown"' "$file")

    [ "$MODE" = "full" ] && echo ""
    [ "$MODE" = "full" ] && echo -e "Validating: ${subject} (${id}, type: ${type})"

    # 1. Schema version
    local sv
    sv=$(jq -r '.metadata.schema_version // "missing"' "$file")
    if [ "$sv" = "2.0" ]; then
        ok "schema_version: 2.0"
    else
        fail "$id: schema_version is '$sv' (expected '2.0')"
    fi

    # 2. Required fields for all types
    local approval
    approval=$(jq -r '.metadata.approval // "missing"' "$file")
    if [ "$approval" = "missing" ]; then
        fail "$id: missing 'approval' field"
    else
        ok "approval: $approval"
    fi

    local blocked
    blocked=$(jq -r '.metadata.blocked // "missing"' "$file")
    if [ "$blocked" = "missing" ]; then
        fail "$id: missing 'blocked' field"
    else
        ok "blocked: $blocked"
    fi

    # 3. Type-specific checks
    case "$type" in
        epic|story|bug|techdebt)
            # Must have review fields
            local rs
            rs=$(jq '.metadata | has("review_stage")' "$file")
            if [ "$rs" = "false" ]; then
                fail "$id: missing 'review_stage' (required for $type)"
            else
                ok "review_stage present"
            fi
            local rr
            rr=$(jq '.metadata | has("review_result")' "$file")
            if [ "$rr" = "false" ]; then
                fail "$id: missing 'review_result' (required for $type)"
            else
                ok "review_result present"
            fi
            # Validate pairing
            local stage_val result_val
            stage_val=$(jq -r '.metadata.review_stage // "null"' "$file")
            result_val=$(jq -r '.metadata.review_result // "null"' "$file")
            if [ "$stage_val" = "null" ] && [ "$result_val" != "null" ]; then
                fail "$id: review_stage is null but review_result is '$result_val' (must be paired)"
            elif [ "$stage_val" != "null" ] && [ "$result_val" = "null" ]; then
                fail "$id: review_stage is '$stage_val' but review_result is null (must be paired)"
            fi
            ;;
        task)
            # Must have local_checks
            local lc_count
            lc_count=$(jq '.metadata.local_checks // [] | length' "$file")
            if [ "$lc_count" -eq 0 ]; then
                warn "$id: no local_checks (recommended min 3)"
            elif [ "$lc_count" -lt 3 ]; then
                warn "$id: only $lc_count local_checks (recommended min 3)"
            else
                ok "local_checks: $lc_count items"
            fi
            # Must have completion_signal
            local cs
            cs=$(jq -r '.metadata.completion_signal // "missing"' "$file")
            if [ "$cs" = "missing" ]; then
                warn "$id: no completion_signal"
            else
                ok "completion_signal present"
            fi
            # Should NOT have review fields
            local has_rs
            has_rs=$(jq '.metadata | has("review_stage")' "$file")
            if [ "$has_rs" = "true" ]; then
                local rs_val
                rs_val=$(jq -r '.metadata.review_stage // "null"' "$file")
                if [ "$rs_val" != "null" ]; then
                    fail "$id: task has review_stage='$rs_val' (tasks should not have review fields)"
                fi
            fi
            ;;
    esac

    # 4. Prohibited fields
    local has_status_meta
    has_status_meta=$(jq '.metadata | has("status")' "$file")
    if [ "$has_status_meta" = "true" ]; then
        fail "$id: metadata.status exists (prohibited — use top-level status)"
    fi

    # 5. Comments well-formed
    local comments_count
    comments_count=$(jq '.metadata.comments // [] | length' "$file")
    if [ "$comments_count" -gt 0 ]; then
        local bad_comments
        bad_comments=$(jq '[.metadata.comments[] | select(.id == null or .type == null or .author == null)] | length' "$file" 2>/dev/null || echo "0")
        if [ "$bad_comments" -gt 0 ]; then
            fail "$id: $bad_comments comments missing required fields (id, type, or author)"
        else
            ok "comments: $comments_count well-formed"
        fi
    fi

    # 6. Subject prefix
    case "$type" in
        epic)  echo "$subject" | grep -q "^Epic: " || warn "$id: subject missing 'Epic: ' prefix" ;;
        story) echo "$subject" | grep -q "^Story: " || warn "$id: subject missing 'Story: ' prefix" ;;
        task)  echo "$subject" | grep -q "^Task: " || warn "$id: subject missing 'Task: ' prefix" ;;
        bug)   echo "$subject" | grep -q "^Bug: " || warn "$id: subject missing 'Bug: ' prefix" ;;
        techdebt) echo "$subject" | grep -q "^TechDebt: " || warn "$id: subject missing 'TechDebt: ' prefix" ;;
    esac

    PASS=$((PASS + 1))
}

# Main
if [ -n "$TARGET_ID" ]; then
    TARGET_FILE="$TASKS_DIR/$TARGET_ID.json"
    if [ ! -f "$TARGET_FILE" ]; then
        echo "ERROR: Task not found: $TARGET_FILE" >&2
        exit 1
    fi
    validate_task "$TARGET_FILE"
else
    for task_file in "$TASKS_DIR"/*.json; do
        [ -f "$task_file" ] || continue
        validate_task "$task_file"
    done
fi

echo ""
echo -e "Results: ${GREEN}$PASS validated${NC}, ${RED}$FAIL errors${NC}, ${YELLOW}$WARNINGS warnings${NC}"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
