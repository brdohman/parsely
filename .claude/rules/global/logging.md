---
paths:
  - "app/**/*.swift"
---

# Logging Standards (os.Logger)

## Required Framework

Use Apple's `os.Logger` for all logging. Never use `print()` — it is banned by quality gates.

## Setup

```swift
import os

extension Logger {
    /// Subsystem should be the app's bundle identifier
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.app"

    /// Create loggers with category matching the Swift type name
    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")
    static let service = Logger(subsystem: subsystem, category: "Service")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let security = Logger(subsystem: subsystem, category: "Security")
}
```

## Log Levels

| Level | Use For | Example |
|-------|---------|---------|
| `debug` | Development-only detail, stripped from release | `Logger.viewModel.debug("Loading items: \(ids)")` |
| `info` | General flow, useful for diagnostics | `Logger.service.info("Sync completed: \(count) items")` |
| `notice` | Notable events that merit attention | `Logger.persistence.notice("Migration applied: v\(version)")` |
| `error` | Recoverable errors | `Logger.network.error("Request failed: \(error)")` |
| `fault` | Unrecoverable errors, likely bugs | `Logger.security.fault("Keychain corrupted")` |

## Rules

- Category = Swift type name: `Logger(subsystem: subsystem, category: "ItemListViewModel")`
- Mark sensitive data with `privacy: .private`: `logger.info("User: \(username, privacy: .private)")`
- Use string interpolation, not format strings
- Never log credentials, tokens, or passwords at any level

## Viewing Logs

```bash
# Stream logs in Terminal
log stream --predicate 'subsystem == "com.yourapp"' --level debug

# Search past logs
log show --predicate 'subsystem == "com.yourapp"' --last 1h
```
