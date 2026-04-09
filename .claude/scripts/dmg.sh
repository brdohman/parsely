#!/bin/bash
set -e

# Create a DMG installer from the exported app
# Usage: .claude/scripts/dmg.sh [app-path] [output-dir]
# Requires: create-dmg (brew install create-dmg)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

APP_NAME=$(basename "$PROJECT_ROOT/app/"*.xcodeproj .xcodeproj 2>/dev/null | head -1)
if [ -z "$APP_NAME" ] || [ "$APP_NAME" = "*" ]; then
    echo "ERROR: No .xcodeproj found in app/."
    exit 1
fi

APP_PATH="${1:-$PROJECT_ROOT/build/export/$APP_NAME.app}"
OUTPUT_DIR="${2:-$PROJECT_ROOT/build}"
DMG_PATH="$OUTPUT_DIR/$APP_NAME.dmg"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: App not found at $APP_PATH"
    echo "Run .claude/scripts/archive.sh first to create the .app"
    exit 1
fi

if ! command -v create-dmg &> /dev/null; then
    echo "ERROR: create-dmg not found. Install with: brew install create-dmg"
    exit 1
fi

echo "=== Creating DMG ==="
echo "App: $APP_PATH"
echo "Output: $DMG_PATH"
echo ""

# Remove existing DMG if present
rm -f "$DMG_PATH"

create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 150 190 \
    --app-drop-link 450 190 \
    "$DMG_PATH" \
    "$APP_PATH"

DMG_EXIT=$?

if [ $DMG_EXIT -eq 0 ]; then
    echo ""
    echo "=== DMG Created ==="
    echo "Output: $DMG_PATH"
    echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
else
    echo ""
    echo "=== DMG Creation FAILED (exit code: $DMG_EXIT) ==="
    exit $DMG_EXIT
fi
