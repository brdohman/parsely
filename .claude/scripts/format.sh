#!/bin/bash
set -e

# Format Swift source code
# Usage: .claude/scripts/format.sh [--check]
# Options:
#   --check    Verify formatting without modifying (for CI)

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

APP_NAME=$(basename "$PROJECT_ROOT/app/"*.xcodeproj .xcodeproj 2>/dev/null | head -1)
if [ -z "$APP_NAME" ] || [ "$APP_NAME" = "*" ]; then
    echo "ERROR: No .xcodeproj found in app/."
    exit 1
fi

SOURCE_DIR="$PROJECT_ROOT/app/$APP_NAME"
CONFIG_PATH="$SOURCE_DIR/.swiftformat"

if [ ! -f "$CONFIG_PATH" ]; then
    CONFIG_PATH="$PROJECT_ROOT/.claude/templates/swiftformat"
fi

echo "=== Running SwiftFormat ==="
echo "Source: $SOURCE_DIR"
echo "Config: $CONFIG_PATH"
echo ""

if ! command -v swiftformat &> /dev/null; then
    echo "ERROR: swiftformat not found. Install with: brew install swiftformat"
    exit 1
fi

if [ "$1" = "--check" ]; then
    echo "Mode: Check (read-only)"
    swiftformat "$SOURCE_DIR" --config "$CONFIG_PATH" --lint 2>&1
else
    echo "Mode: Format"
    swiftformat "$SOURCE_DIR" --config "$CONFIG_PATH" 2>&1
fi

FMT_EXIT=$?

if [ $FMT_EXIT -eq 0 ]; then
    echo ""
    echo "=== Format PASSED ==="
else
    echo ""
    echo "=== Format FAILED (exit code: $FMT_EXIT) ==="
    exit $FMT_EXIT
fi
