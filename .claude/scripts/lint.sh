#!/bin/bash
set -e

# Run SwiftLint on source code
# Usage: .claude/scripts/lint.sh [--fix]
# Options:
#   --fix    Auto-correct fixable violations

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Auto-detect app name from xcodeproj
APP_NAME=$(basename "$PROJECT_ROOT/app/"*.xcodeproj .xcodeproj 2>/dev/null | head -1)
if [ -z "$APP_NAME" ] || [ "$APP_NAME" = "*" ]; then
    echo "ERROR: No .xcodeproj found in app/. Cannot auto-detect app name."
    exit 1
fi

SOURCE_DIR="$PROJECT_ROOT/app/$APP_NAME"
CONFIG_PATH="$SOURCE_DIR/.swiftlint.yml"

echo "=== Running SwiftLint ==="
echo "Source: $SOURCE_DIR"
echo "Config: $CONFIG_PATH"
echo "DEVELOPER_DIR: $DEVELOPER_DIR"
echo ""

SWIFTLINT_CMD="swiftlint"

# Check if swiftlint is available
if ! command -v $SWIFTLINT_CMD &> /dev/null; then
    echo "ERROR: SwiftLint not found. Install with: brew install swiftlint"
    exit 1
fi

if [ "$1" = "--fix" ]; then
    echo "Mode: Auto-correct"
    echo ""
    $SWIFTLINT_CMD lint \
        --config "$CONFIG_PATH" \
        --fix \
        "$SOURCE_DIR" \
        2>&1
else
    echo "Mode: Lint (read-only)"
    echo ""
    $SWIFTLINT_CMD lint \
        --config "$CONFIG_PATH" \
        --strict \
        "$SOURCE_DIR" \
        2>&1
fi

LINT_EXIT=$?

if [ $LINT_EXIT -eq 0 ]; then
    echo ""
    echo "=== Lint PASSED ==="
else
    echo ""
    echo "=== Lint FAILED (exit code: $LINT_EXIT) ==="
    exit $LINT_EXIT
fi
