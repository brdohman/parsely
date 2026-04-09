#!/bin/bash
set -e

# Build the macOS app
# Usage: .claude/scripts/build.sh [AppName]
# If no AppName provided, auto-detects from app/*.xcodeproj

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Auto-detect app name from xcodeproj
if [ -n "$1" ]; then
    APP_NAME="$1"
else
    APP_NAME=$(basename "$PROJECT_ROOT/app/"*.xcodeproj .xcodeproj 2>/dev/null | head -1)
    if [ -z "$APP_NAME" ] || [ "$APP_NAME" = "*" ]; then
        echo "ERROR: No .xcodeproj found in app/. Provide app name as argument."
        exit 1
    fi
fi

PROJECT_PATH="$PROJECT_ROOT/app/$APP_NAME.xcodeproj"
SCHEME="${2:-$APP_NAME}"
DESTINATION="platform=macOS"

echo "=== Building $APP_NAME ($SCHEME scheme) ==="
echo "Project: $PROJECT_PATH"
echo "DEVELOPER_DIR: $DEVELOPER_DIR"
echo ""

xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration Debug \
    build \
    2>&1

BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
    echo ""
    echo "=== Build SUCCEEDED ==="
else
    echo ""
    echo "=== Build FAILED (exit code: $BUILD_EXIT) ==="
    exit $BUILD_EXIT
fi
