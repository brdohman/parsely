---
description: Create a release archive of the macOS app
agent: build-engineer
disable-model-invocation: true
---

# /archive

Creates a release build archive of the application.

## Usage

```
/archive
/archive --export
```

## What It Does

1. Runs all pre-archive checks (see Pre-Archive Gate below)
2. Cleans build folder
3. Builds in Release configuration
4. Creates .xcarchive
5. Optionally exports .app for distribution

## Pre-Archive Gate

Before creating a release archive, ALL must pass:

**Required Checks:**
1. All pre-merge checks pass
2. All unit tests pass
3. All UI tests pass
4. No SwiftLint errors
5. Version number updated (if releasing)

**Version Check:** Verify `CFBundleShortVersionString` and `CFBundleVersion` are updated.

**If ANY Fails:** ARCHIVE BLOCKED. Fix issues, re-run checks, re-attempt.

## Commands

```bash
# Clean
xcodebuild clean -scheme AppName

# Build release
xcodebuild build -scheme AppName -configuration Release -destination 'platform=macOS'

# Create archive
xcodebuild archive -scheme AppName -archivePath ./build/AppName.xcarchive

# Export app (optional)
xcodebuild -exportArchive \
  -archivePath ./build/AppName.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

## Output

- `./build/AppName.xcarchive` - Xcode archive
- `./build/AppName.app` - Distributable app (if exported)

## Prerequisites

- All tests passing
- SwiftLint clean
- Version numbers updated

## Code Signing

For personal use:
- Development certificate (automatic)
- No notarization required

For sharing:
- Developer ID certificate
- Consider notarization

## Agent

Delegates to Build Engineer agent.
