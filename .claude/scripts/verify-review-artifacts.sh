#!/bin/bash
set -euo pipefail

# verify-review-artifacts.sh — Verify review output files exist for the current branch
#
# Usage:
#   verify-review-artifacts.sh                        # Story-level check (aikido + coderabbit)
#   verify-review-artifacts.sh --level epic            # Epic-level check (adds trivy)
#   verify-review-artifacts.sh --branch epic-100-foo   # Explicit branch name
#
# Exit 0 = all required reviews present
# Exit 1 = missing or empty reviews (details on stdout)
#
# Required at story level: aikido, coderabbit
# Required at epic level:  aikido, coderabbit, trivy
# Required after product review (UI stories): peekaboo screenshots + manifest

LEVEL="story"
BRANCH=""
CHECK_PEEKABOO=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --level) LEVEL="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --peekaboo) CHECK_PEEKABOO=true; shift ;;
        -h|--help)
            echo "Usage: verify-review-artifacts.sh [--level story|epic] [--branch <name>] [--peekaboo]"
            echo "  --peekaboo  Also check for Peekaboo screenshots (after product review)"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Determine branch (sanitized for directory name)
if [ -z "$BRANCH" ]; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
fi
BRANCH_SAFE=$(echo "$BRANCH" | tr '/' '-' | tr ' ' '-')

REVIEW_DIR="tools/third-party-reviews/${BRANCH_SAFE}"

# Check directory exists
if [ ! -d "$REVIEW_DIR" ]; then
    echo "REVIEW ARTIFACTS MISSING"
    echo "  Directory does not exist: $REVIEW_DIR"
    echo "  No review output has been saved for this branch."
    echo "  Ensure review agents pipe output through .claude/scripts/save-review.sh"
    exit 1
fi

MISSING=()
EMPTY=()
COUNTS=()

# Check for aikido files
AIKIDO_COUNT=$(find "$REVIEW_DIR" -name "aikido-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$AIKIDO_COUNT" -eq 0 ]; then
    MISSING+=("aikido")
else
    COUNTS+=("aikido=$AIKIDO_COUNT")
fi

# Check for coderabbit files
CR_COUNT=$(find "$REVIEW_DIR" -name "coderabbit-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$CR_COUNT" -eq 0 ]; then
    MISSING+=("coderabbit")
else
    COUNTS+=("coderabbit=$CR_COUNT")
fi

# Epic level: also check for trivy
if [ "$LEVEL" = "epic" ]; then
    TRIVY_COUNT=$(find "$REVIEW_DIR" -name "trivy-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TRIVY_COUNT" -eq 0 ]; then
        MISSING+=("trivy")
    else
        COUNTS+=("trivy=$TRIVY_COUNT")
    fi
fi

# Check for Peekaboo screenshots (when --peekaboo flag is set)
if $CHECK_PEEKABOO; then
    PEEKABOO_DIR="$REVIEW_DIR/peekaboo"
    if [ ! -d "$PEEKABOO_DIR" ]; then
        MISSING+=("peekaboo screenshots (directory missing)")
    else
        SCREENSHOT_COUNT=$(find "$PEEKABOO_DIR" -name "*.png" -o -name "*.jpg" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$SCREENSHOT_COUNT" -eq 0 ]; then
            MISSING+=("peekaboo screenshots (0 images)")
        else
            COUNTS+=("screenshots=$SCREENSHOT_COUNT")
            # Check for manifest
            if [ ! -f "$PEEKABOO_DIR/manifest.md" ]; then
                MISSING+=("peekaboo manifest (screenshots exist but no manifest.md)")
            fi
        fi
    fi
fi

# Check for empty files (written but no content)
for f in "$REVIEW_DIR"/*.md; do
    [ -f "$f" ] || continue
    if [ ! -s "$f" ]; then
        EMPTY+=("$(basename "$f")")
    fi
done

# Report results
if [ ${#MISSING[@]} -gt 0 ] || [ ${#EMPTY[@]} -gt 0 ]; then
    echo "REVIEW ARTIFACTS INCOMPLETE"
    if [ ${#MISSING[@]} -gt 0 ]; then
        echo "  Missing: ${MISSING[*]}"
    fi
    if [ ${#EMPTY[@]} -gt 0 ]; then
        echo "  Empty files: ${EMPTY[*]}"
    fi
    echo "  Directory: $REVIEW_DIR"
    echo "  Level: $LEVEL"
    exit 1
fi

# All checks passed
COUNTS_STR=$(IFS=', '; echo "${COUNTS[*]}")
echo "REVIEW ARTIFACTS VERIFIED ($COUNTS_STR)"
exit 0
