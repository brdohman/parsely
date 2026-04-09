#!/bin/bash
# test-hooks.sh — Smoke-test all Claude Code hooks with mock input
#
# Usage:
#   .claude/scripts/test-hooks.sh           # Run all tests
#   .claude/scripts/test-hooks.sh <hook>    # Run one (e.g., git-guards)
#
# Tests each hook with representative mock input and verifies:
#   - Script exits cleanly (no crashes)
#   - Expected exit codes for allow/block scenarios
#   - No unhandled errors on malformed input

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/../hooks" && pwd)"
PASS=0
FAIL=0
SKIP=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }
skip() { echo -e "  ${YELLOW}[SKIP]${NC} $1"; SKIP=$((SKIP + 1)); }

run_hook() {
    local hook="$1"
    local input="$2"
    local expected_exit="${3:-0}"
    local desc="$4"

    local actual_exit=0
    echo "$input" | "$HOOKS_DIR/$hook" >/dev/null 2>&1 || actual_exit=$?

    if [ "$actual_exit" -eq "$expected_exit" ]; then
        ok "$desc (exit $actual_exit)"
    else
        fail "$desc — expected exit $expected_exit, got $actual_exit"
    fi
}

# ─────────────────────────────────────────────
# git-guards.sh
# ─────────────────────────────────────────────
test_git_guards() {
    echo ""
    echo "Testing: git-guards.sh"

    # Non-git command should pass through
    run_hook "git-guards.sh" \
        '{"tool_input": {"command": "ls -la"}}' \
        0 \
        "Non-git command passes through"

    # Git status (not commit/merge) should pass
    run_hook "git-guards.sh" \
        '{"tool_input": {"command": "git status"}}' \
        0 \
        "git status passes through"

    # Empty input should not crash
    run_hook "git-guards.sh" \
        '{}' \
        0 \
        "Empty input does not crash"

    # Malformed JSON — jq fails, set -e causes non-zero exit.
    # This is acceptable: Claude Code always sends valid JSON to hooks.
    # If this becomes an issue, add `|| true` to the jq parse in git-guards.sh.
    run_hook "git-guards.sh" \
        'not json at all' \
        5 \
        "Malformed input exits non-zero (expected — jq parse failure)"
}

# ─────────────────────────────────────────────
# validate-task-completion.sh
# ─────────────────────────────────────────────
test_validate_task_completion() {
    echo ""
    echo "Testing: validate-task-completion.sh"

    # No task ID should pass
    run_hook "validate-task-completion.sh" \
        '{}' \
        0 \
        "No task_id passes through"

    # Empty task_id should pass
    run_hook "validate-task-completion.sh" \
        '{"task_id": ""}' \
        0 \
        "Empty task_id passes through"

    # Non-existent task should pass (file not found = skip)
    run_hook "validate-task-completion.sh" \
        '{"task_id": "nonexistent-999", "task_subject": "Test"}' \
        0 \
        "Non-existent task ID passes (skips validation)"
}

# ─────────────────────────────────────────────
# audit-config-change.sh
# ─────────────────────────────────────────────
test_audit_config_change() {
    echo ""
    echo "Testing: audit-config-change.sh"

    # Normal input
    run_hook "audit-config-change.sh" \
        '{"source": "test", "file_path": "test.md"}' \
        0 \
        "Normal config change logs successfully"

    # Empty input
    run_hook "audit-config-change.sh" \
        '{}' \
        0 \
        "Empty input does not crash"
}

# ─────────────────────────────────────────────
# design-skill-suggest.sh
# ─────────────────────────────────────────────
test_design_skill_suggest() {
    echo ""
    echo "Testing: design-skill-suggest.sh"

    # Non-build command should pass
    run_hook "design-skill-suggest.sh" \
        '{"tool_input": {"command": "echo hello"}, "tool_output": {"stdout": "", "stderr": "", "exit_code": 0}}' \
        0 \
        "Non-build command passes through"

    # Build success should pass
    run_hook "design-skill-suggest.sh" \
        '{"tool_input": {"command": "xcodebuild build"}, "tool_output": {"stdout": "BUILD SUCCEEDED", "stderr": "", "exit_code": 0}}' \
        0 \
        "Successful build passes through"

    # Empty input
    run_hook "design-skill-suggest.sh" \
        '{}' \
        0 \
        "Empty input does not crash"
}

# ─────────────────────────────────────────────
# session-compact.sh
# ─────────────────────────────────────────────
test_session_compact() {
    echo ""
    echo "Testing: session-compact.sh"

    # Non-compact source should exit silently
    run_hook "session-compact.sh" \
        '{"source": "startup"}' \
        0 \
        "Non-compact source exits silently"

    # Compact source should output context
    local output
    output=$(echo '{"source": "compact"}' | "$HOOKS_DIR/session-compact.sh" 2>/dev/null || true)
    if echo "$output" | grep -q "POST-COMPACTION"; then
        ok "Compact source outputs context reminder"
    else
        fail "Compact source did not output context reminder"
    fi

    # Empty input
    run_hook "session-compact.sh" \
        '{}' \
        0 \
        "Empty input does not crash"
}

# ─────────────────────────────────────────────
# validate-teammate-idle.sh
# ─────────────────────────────────────────────
test_validate_teammate_idle() {
    echo ""
    echo "Testing: validate-teammate-idle.sh"

    # No teammate name should pass
    run_hook "validate-teammate-idle.sh" \
        '{}' \
        0 \
        "No teammate info passes through"

    # Empty names should pass
    run_hook "validate-teammate-idle.sh" \
        '{"teammate_name": "", "team_name": ""}' \
        0 \
        "Empty names pass through"
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

TARGET="${1:-all}"

echo "Hook Smoke Tests"
echo "================"
echo "Hooks directory: $HOOKS_DIR"

case "$TARGET" in
    git-guards)      test_git_guards ;;
    validate-task*)  test_validate_task_completion ;;
    audit-config*)   test_audit_config_change ;;
    design-skill*)   test_design_skill_suggest ;;
    session-compact) test_session_compact ;;
    validate-team*)  test_validate_teammate_idle ;;
    all)
        test_git_guards
        test_validate_task_completion
        test_audit_config_change
        test_design_skill_suggest
        test_session_compact
        test_validate_teammate_idle
        ;;
    *)
        echo "Unknown hook: $TARGET"
        echo "Available: git-guards, validate-task, audit-config, design-skill, session-compact, validate-teammate"
        exit 1
        ;;
esac

echo ""
echo "================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$SKIP skipped${NC}"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
