#!/bin/bash
set -e

# Archive the macOS app for distribution
# Usage: .claude/scripts/archive.sh [output-dir]
# Default output: PROJECT_ROOT/build/

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

OUTPUT_DIR="${1:-$PROJECT_ROOT/build}"
ARCHIVE_PATH="$OUTPUT_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$OUTPUT_DIR/export"

echo "=== Archiving $APP_NAME ($SCHEME scheme) ==="
echo "Project: $PROJECT_PATH"
echo "Output: $OUTPUT_DIR"
echo "DEVELOPER_DIR: $DEVELOPER_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 0: Increment build number
echo "--- Step 0: Incrementing build number ---"
cd "$PROJECT_ROOT/app"
if command -v agvtool &> /dev/null; then
    agvtool next-version -all 2>/dev/null || echo "agvtool increment skipped (no versioning configured)"
fi
cd "$PROJECT_ROOT"
echo ""

# Step 1: Archive
echo "--- Step 1: Creating archive ---"
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    2>&1

ARCHIVE_EXIT=$?

if [ $ARCHIVE_EXIT -ne 0 ]; then
    echo ""
    echo "=== Archive FAILED (exit code: $ARCHIVE_EXIT) ==="
    exit $ARCHIVE_EXIT
fi

# Step 2: Export (for direct distribution, no App Store)
echo ""
echo "--- Step 2: Exporting application ---"

# Create export options plist for direct distribution
EXPORT_OPTIONS="$OUTPUT_DIR/ExportOptions.plist"
cat > "$EXPORT_OPTIONS" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
PLIST

xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_PATH" \
    2>&1

EXPORT_EXIT=$?

if [ $EXPORT_EXIT -eq 0 ]; then
    echo ""
    echo "=== Archive SUCCEEDED ==="
    echo "Archive: $ARCHIVE_PATH"
    echo "Export: $EXPORT_PATH"

    # Tag the release
    VERSION=$(cd "$PROJECT_ROOT/app" && agvtool what-marketing-version -terse1 2>/dev/null || echo "0.0.0")
    BUILD=$(cd "$PROJECT_ROOT/app" && agvtool what-version -terse 2>/dev/null || echo "0")
    TAG="v${VERSION}-${BUILD}"

    echo ""
    echo "--- Step 3: Tagging release ---"
    if git rev-parse --git-dir &>/dev/null; then
        git tag -a "$TAG" -m "Release $TAG" 2>/dev/null && echo "Tagged: $TAG" || echo "Tag skipped (already exists or not in git repo)"
    fi

    # Generate changelog if git-cliff available
    if command -v git-cliff &> /dev/null; then
        echo ""
        echo "--- Step 4: Generating changelog ---"
        git-cliff --output "$PROJECT_ROOT/CHANGELOG.md" 2>/dev/null && echo "Changelog updated" || echo "Changelog generation skipped"
    fi

    # Step 5: Notarization (optional — requires keychain profile setup)
    # Setup: xcrun notarytool store-credentials "notarization-profile" --apple-id YOUR_EMAIL --team-id YOUR_TEAM_ID
    NOTARY_PROFILE="${NOTARY_PROFILE:-notarization-profile}"
    APP_PATH="$EXPORT_PATH/$APP_NAME.app"

    if xcrun notarytool --help &>/dev/null; then
        echo ""
        echo "--- Step 5: Notarization ---"
        if xcrun notarytool submit "$APP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait 2>/dev/null; then
            echo "Notarization succeeded"
            xcrun stapler staple "$APP_PATH" 2>/dev/null && echo "Stapled successfully" || echo "Staple failed (app still notarized)"
        else
            echo "WARNING: Notarization failed or keychain profile '$NOTARY_PROFILE' not found."
            echo "Setup: xcrun notarytool store-credentials \"$NOTARY_PROFILE\" --apple-id YOUR_EMAIL --team-id YOUR_TEAM_ID"
            echo "Skipping notarization — archive is still usable for local testing."
        fi
    fi
else
    echo ""
    echo "=== Export FAILED (exit code: $EXPORT_EXIT) ==="
    echo "Archive was created at: $ARCHIVE_PATH"
    echo "Export failed -- you may need to configure signing settings."
    exit $EXPORT_EXIT
fi
