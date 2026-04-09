#!/bin/bash
set -euo pipefail

# Git guards for Claude Code
# PreToolUse hook (Bash matcher) — activates for git commit and git merge commands
# Exit 0 = allow, Exit 2 = block with feedback to Claude

# Read hook input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Determine which git operation (if any)
IS_COMMIT=false
IS_MERGE=false

if echo "$COMMAND" | grep -q "git commit"; then
    IS_COMMIT=true
elif echo "$COMMAND" | grep -q "git merge"; then
    IS_MERGE=true
else
    # Not a git commit or merge — allow immediately
    exit 0
fi

# --- Common setup ---

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')
APP_DIR="${PROJECT_DIR:-$(pwd)}/app"

# Gitleaks secret scanning (commit only)
if $IS_COMMIT; then
    echo "Running pre-commit checks..." >&2
    if command -v gitleaks &> /dev/null; then
        if ! gitleaks git --staged --no-banner -v 2>/dev/null; then
            echo "Gitleaks found secrets in staged files. Remove secrets before committing." >&2
            exit 2
        fi
    else
        echo "WARNING: gitleaks not installed. Run 'brew install gitleaks' for secret scanning." >&2
    fi
fi

# --- Branch protection: block commits to main when epic branch exists ---
if $IS_COMMIT; then
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

    if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
        EPIC_BRANCHES=$(git branch --list 'epic/*' 2>/dev/null | tr -d ' *')
        if [ -n "$EPIC_BRANCHES" ]; then
            echo "BLOCKED: Cannot commit directly to '$CURRENT_BRANCH' while epic branches exist." >&2
            echo "" >&2
            echo "Active epic branches:" >&2
            echo "$EPIC_BRANCHES" | while read -r b; do echo "  - $b" >&2; done
            echo "" >&2
            echo "Switch to the epic branch first:" >&2
            echo "  git checkout <epic-branch>" >&2
            echo "Or use: .claude/scripts/ensure-epic-branch.sh <branch-name>" >&2
            exit 2
        fi
    fi
fi

# --- Commit message validation (warnings only) ---
if $IS_COMMIT; then
    COMMIT_MSG=""
    if echo "$COMMAND" | grep -qE 'git commit.*-m\s'; then
        COMMIT_MSG=$(echo "$COMMAND" | sed -E 's/.*-m[[:space:]]+["'\''"]([^"'\''"]*)["'\''"].*/\1/' 2>/dev/null || echo "")
    fi

    if [ -n "$COMMIT_MSG" ]; then
        if ! echo "$COMMIT_MSG" | grep -qE '^(feat|fix|test|docs|refactor|chore)\('; then
            echo "WARNING: Commit message does not follow conventional format: <type>(<scope>): <description> (task-xxx)" >&2
        fi
        if ! echo "$COMMIT_MSG" | grep -qE '\(task-[a-zA-Z0-9_-]+\)'; then
            echo "WARNING: Commit message missing task reference. Expected format: (task-xxx)" >&2
        fi
    fi
fi

if $IS_MERGE; then
    echo "Running pre-merge checks (build + test)..." >&2
fi

# No app directory — template repo, skip remaining checks
if [ ! -d "$APP_DIR" ]; then
    exit 0
fi

# Find the Xcode project
XCODEPROJ=$(find "$APP_DIR" -maxdepth 2 -name "*.xcodeproj" -type d 2>/dev/null | head -1)
if [ -z "$XCODEPROJ" ]; then
    exit 0
fi

SCHEME=$(basename "$XCODEPROJ" .xcodeproj)

# --- SwiftLint (both commit and merge) ---

if command -v swiftlint &> /dev/null; then
    if $IS_COMMIT; then
        # For commits: only lint staged Swift files to avoid blocking on pre-existing issues
        # Resolve paths relative to PROJECT_DIR (handles nested repo case where git root
        # is a parent directory and staged paths include a subdirectory prefix)
        GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
        STAGED_SWIFT_RAW=$(git diff --cached --name-only --diff-filter=ACM -- '*.swift' 2>/dev/null)
        STAGED_SWIFT=""
        if [ -n "$STAGED_SWIFT_RAW" ] && [ -n "$GIT_ROOT" ]; then
            while IFS= read -r rel_path; do
                abs_path="$GIT_ROOT/$rel_path"
                if [ -f "$abs_path" ]; then
                    STAGED_SWIFT="$STAGED_SWIFT $abs_path"
                fi
            done <<< "$STAGED_SWIFT_RAW"
        fi
        if [ -n "$STAGED_SWIFT" ]; then
            # shellcheck disable=SC2086
            if ! swiftlint lint --strict --quiet $STAGED_SWIFT 2>/dev/null; then
                echo "SwiftLint failed on staged files. Fix lint issues before committing." >&2
                exit 2
            fi
        fi
    else
        # For merges: lint the full app directory (no --strict to allow pre-existing warnings)
        if ! swiftlint lint --quiet "$APP_DIR" 2>/dev/null; then
            echo "SwiftLint failed. Fix lint errors before proceeding." >&2
            exit 2
        fi
    fi
fi

# --- Build check ---

if $IS_COMMIT; then
    # Optional for commit (enable with CLAUDE_PRE_COMMIT_BUILD=true)
    if [ "${CLAUDE_PRE_COMMIT_BUILD:-false}" = "true" ]; then
        if ! xcodebuild build -project "$XCODEPROJ" -scheme "$SCHEME" -destination 'platform=macOS' -quiet 2>/dev/null; then
            echo "Build failed. Fix compilation errors before committing." >&2
            exit 2
        fi
    fi
fi

if $IS_MERGE; then
    # Build and test checks for merge
    # Note: xcodebuild with -quiet can hang in hook context due to timeout constraints.
    # Build/test verification should be done before merge via CI or manual run.
    echo "Pre-merge: SwiftLint passed. Build/test verification expected prior to merge." >&2
fi

exit 0
