#!/bin/bash
set -e

# Run unit tests for the macOS app
# Usage: .claude/scripts/test.sh [TestClass/testMethod]
# Examples:
#   .claude/scripts/test.sh                                    # Run all tests
#   .claude/scripts/test.sh AppNameTests/SomeTestClass          # Run specific test class
#   .claude/scripts/test.sh AppNameTests/SomeTestClass/testX    # Run specific test method

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Auto-detect app name from xcodeproj
APP_NAME=$(basename "$PROJECT_ROOT/app/"*.xcodeproj .xcodeproj 2>/dev/null | head -1)
if [ -z "$APP_NAME" ] || [ "$APP_NAME" = "*" ]; then
    echo "ERROR: No .xcodeproj found in app/. Cannot auto-detect app name."
    exit 1
fi

PROJECT_PATH="$PROJECT_ROOT/app/$APP_NAME.xcodeproj"
SCHEME="$APP_NAME"
DESTINATION="platform=macOS"

echo "=== Running $APP_NAME Tests ($SCHEME scheme) ==="
echo "Project: $PROJECT_PATH"
echo "DEVELOPER_DIR: $DEVELOPER_DIR"
echo ""

ONLY_TESTING=""
if [ -n "$1" ]; then
    ONLY_TESTING="-only-testing:$1"
    echo "Running specific test: $1"
    echo ""
fi

xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration Debug \
    test \
    $ONLY_TESTING \
    2>&1

TEST_EXIT=$?

if [ $TEST_EXIT -eq 0 ]; then
    echo ""
    echo "=== Tests PASSED ==="
else
    echo ""
    echo "=== Tests FAILED (exit code: $TEST_EXIT) ==="
    exit $TEST_EXIT
fi
