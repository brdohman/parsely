#!/bin/bash
set -euo pipefail

# ensure-epic-branch.sh — Ensure the correct epic branch is checked out
# Usage: .claude/scripts/ensure-epic-branch.sh <branch-name>
# Example: .claude/scripts/ensure-epic-branch.sh epic/MYAPP-100-foundation
#
# Exit 0 = on correct branch (or switched/created successfully)
# Exit 1 = error (no branch name provided, git failure)

BRANCH_NAME="${1:-}"

if [ -z "$BRANCH_NAME" ]; then
    echo "ERROR: Branch name required." >&2
    echo "Usage: .claude/scripts/ensure-epic-branch.sh <branch-name>" >&2
    exit 1
fi

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

if [ "$CURRENT_BRANCH" = "$BRANCH_NAME" ]; then
    echo "Already on branch: $BRANCH_NAME"
    exit 0
fi

# Check if branch exists locally
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
    echo "Switching to existing branch: $BRANCH_NAME"
    git checkout "$BRANCH_NAME"
# Check if branch exists on remote
elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME" 2>/dev/null; then
    echo "Checking out remote branch: $BRANCH_NAME"
    git checkout -b "$BRANCH_NAME" "origin/$BRANCH_NAME"
else
    # Create new branch from main (or current HEAD if main doesn't exist)
    if git show-ref --verify --quiet "refs/heads/main" 2>/dev/null; then
        echo "Creating new branch from main: $BRANCH_NAME"
        git checkout -b "$BRANCH_NAME" main
    else
        echo "Creating new branch from HEAD: $BRANCH_NAME"
        git checkout -b "$BRANCH_NAME"
    fi
fi

echo "On branch: $(git branch --show-current)"
exit 0
