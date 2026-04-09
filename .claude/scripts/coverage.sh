#!/bin/bash
set -e

# Measure code coverage and compare against thresholds
# Usage: .claude/scripts/coverage.sh
# Thresholds: 100% ViewModels, 80% Services (from CLAUDE.md)

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

APP_NAME=$(basename "$PROJECT_ROOT/app/"*.xcodeproj .xcodeproj 2>/dev/null | head -1)
if [ -z "$APP_NAME" ] || [ "$APP_NAME" = "*" ]; then
    echo "ERROR: No .xcodeproj found in app/."
    exit 1
fi

PROJECT_PATH="$PROJECT_ROOT/app/$APP_NAME.xcodeproj"
SCHEME="$APP_NAME"
RESULT_PATH="$PROJECT_ROOT/build/coverage.xcresult"

echo "=== Running Tests with Coverage ==="
echo "Project: $PROJECT_PATH"
echo ""

rm -rf "$RESULT_PATH"

xcodebuild test \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "platform=macOS" \
    -enableCodeCoverage YES \
    -resultBundlePath "$RESULT_PATH" \
    2>&1

if [ ! -d "$RESULT_PATH" ]; then
    echo "ERROR: No result bundle generated"
    exit 1
fi

echo ""
echo "=== Code Coverage Report ==="
echo ""

xcrun xccov view --report "$RESULT_PATH" 2>&1

echo ""
echo "=== Coverage Summary ==="
echo ""
echo "Thresholds (from CLAUDE.md):"
echo "  ViewModels: 100%"
echo "  Services:   80%"
echo "  General:    80%"
echo ""
echo "Review the report above against these thresholds."
echo "Result bundle: $RESULT_PATH"
