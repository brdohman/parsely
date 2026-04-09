---
name: xcode-build-patterns
description: Xcode build system knowledge for macOS apps. Build settings, configurations, schemes, signing, distribution, and optimization.
user-invocable: false
allowed-tools: [Read, Glob, Grep, Bash]
---

# Xcode Build Patterns

> **MCP Alternative:** When Xcode is running with the project loaded, prefer Xcode MCP tools (`BuildProject`, `GetBuildLog`, `XcodeListNavigatorIssues`) over direct `xcodebuild` commands. See `.claude/skills/tooling/xcode-mcp/SKILL.md` for the full reference. The patterns below remain the authoritative fallback for headless/CI environments.

## Build Settings (BE-4)

Key build settings for macOS apps:

| Setting | Debug | Release | Purpose |
|---------|-------|---------|---------|
| `SWIFT_ACTIVE_COMPILATION_CONDITIONS` | `DEBUG` | (empty) | Conditional compilation |
| `SWIFT_OPTIMIZATION_LEVEL` | `-Onone` | `-O` | Compiler optimization |
| `DEBUG_INFORMATION_FORMAT` | `dwarf` | `dwarf-with-dsym` | Debug symbols |
| `ENABLE_TESTABILITY` | `YES` | `NO` | @testable import support |
| `GCC_PREPROCESSOR_DEFINITIONS` | `DEBUG=1` | (empty) | C/ObjC conditional compilation |

Important settings to verify:
- `PRODUCT_BUNDLE_IDENTIFIER` — must be unique for signing
- `INFOPLIST_FILE` — path to Info.plist (or `GENERATE_INFOPLIST_FILE = YES`)
- `MACOSX_DEPLOYMENT_TARGET` — should match CLAUDE.md (26.0)
- `SWIFT_STRICT_CONCURRENCY` — should be `complete` for strict checking

## Configuration Management (BE-5)

Standard configurations: **Debug** (development) and **Release** (distribution).

Custom configurations (if needed):
- **Staging** — release optimizations but pointing to test servers
- Create in Xcode: Project > Info > Configurations > (+)

Each configuration can override any build setting. Use `#if DEBUG` in code to branch behavior:

```swift
#if DEBUG
let baseURL = "https://staging.api.example.com"
#else
let baseURL = "https://api.example.com"
#endif
```

## xcconfig Files (BE-6)

Use `.xcconfig` files for shared build settings across targets:

```
// Shared.xcconfig
MACOSX_DEPLOYMENT_TARGET = 26.0
SWIFT_VERSION = 6.0
SWIFT_STRICT_CONCURRENCY = complete

// Debug.xcconfig
#include "Shared.xcconfig"
SWIFT_OPTIMIZATION_LEVEL = -Onone
ENABLE_TESTABILITY = YES

// Release.xcconfig
#include "Shared.xcconfig"
SWIFT_OPTIMIZATION_LEVEL = -O
ENABLE_TESTABILITY = NO
```

Set in Xcode: Project > Info > Configurations > set xcconfig file for each configuration.

## Scheme Management (BE-7)

### Shared Schemes
Mark schemes as "Shared" to include in version control: Manage Schemes > check "Shared" column.

### Test Plans
Create test plans for organized test execution:
- **Unit Tests** plan — all `*Tests` targets
- **UI Tests** plan — all `*UITests` targets
- **Full Suite** plan — both

### Scheme Environment Variables
Set in Edit Scheme > Run > Arguments > Environment Variables:

| Variable | Value | Purpose |
|----------|-------|---------|
| `SQLITE_ENABLE_THREAD_ASSERTIONS` | `1` | Catch SQLite threading issues |
| `CFNETWORK_DIAGNOSTICS` | `3` | Network debugging |
| `CG_CONTEXT_SHOW_BACKTRACE` | `YES` | Graphics debugging |

## Build Performance (BE-8)

### Speed Up Builds
- **Parallel builds:** Build Settings > `SWIFT_COMPILATION_MODE = wholemodule` (release only)
- **Incremental builds:** Keep `singlefile` for Debug
- **Build timing:** Product > Perform Action > Build With Timing Summary
- **Module stability:** `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` only when creating frameworks

### Derived Data Management
```bash
# Clear derived data (fixes phantom build errors)
rm -rf ~/Library/Developer/Xcode/DerivedData/AppName-*

# Check derived data size
du -sh ~/Library/Developer/Xcode/DerivedData/
```

### When to Clean Build
- After changing build settings or xcconfig
- After resolving SPM packages
- After Xcode updates
- When getting phantom "file not found" errors

## Distribution Methods (BE-9)

| Method | Signing | Notarization | Use When |
|--------|---------|-------------|----------|
| **Developer ID** | Developer ID cert | Required | Direct distribution (website, GitHub) |
| **App Store** | Distribution cert | Automatic | App Store distribution |
| **TestFlight** | Distribution cert | Automatic | Beta testing |
| **Development** | Development cert | Not needed | Local testing only |

For this project (personal use, no App Store): **Developer ID** with notarization.

### ExportOptions.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

## Dependency Caching (BE-10)

### SPM Package Resolution
```bash
# Resolve packages (downloads + caches)
swift package resolve

# Clean package cache
swift package purge-cache

# Update all packages to latest compatible versions
swift package update
```

### Package.resolved
- **Always commit** `Package.resolved` to version control
- This ensures all team members/CI use identical dependency versions
- `swift package resolve` uses the lock file; `swift package update` regenerates it

### CI Caching
Cache `~/Library/Caches/org.swift.swiftpm/` and `DerivedData/SourcePackages/` between CI runs to speed up builds.
