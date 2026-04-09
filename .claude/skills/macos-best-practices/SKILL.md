---
name: macos-best-practices
description: macOS development best practices for code organization, data persistence, concurrency, and Swift language usage. Use when planning project structure or reviewing code patterns.
allowed-tools: [Read, Glob, Grep]
---

# macOS Development Best Practices

Reference material for macOS-specific development patterns and conventions.

## Modules

- [code-organization.md](code-organization.md) - Project structure, feature-based organization
- [data-persistence.md](data-persistence.md) - Core Data, UserDefaults, file system patterns
- [modern-concurrency.md](modern-concurrency.md) - Swift concurrency for macOS
- [swift-language.md](swift-language.md) - Swift idioms, optionals, error handling

## Performance Profiling (DEV-5)

### Instruments Templates to Use

| Template | When | What to Look For |
|----------|------|-----------------|
| **Time Profiler** | UI feels slow, scrolling janky | Main thread time > 16ms per frame |
| **Allocations** | Memory growing over time | Objects not deallocated, retain cycles |
| **Leaks** | Suspected retain cycles | Leaked objects with retain count > 0 |
| **Core Data** | Slow fetches, high fault count | Unoptimized predicates, excessive faulting |
| **SwiftUI** | Body recomputation storm | Views recomputing when they shouldn't |
| **Network** | Slow API calls | Response times, connection reuse |

### Quick Diagnosis Without Instruments

```swift
// Measure a block of code
let start = CFAbsoluteTimeGetCurrent()
let result = try await expensiveOperation()
let elapsed = CFAbsoluteTimeGetCurrent() - start
Logger.performance.debug("Operation took \(elapsed)s")
```

### Thresholds

| Metric | Target | Investigate If |
|--------|--------|---------------|
| App launch | < 1s | > 2s |
| List scroll | 60 fps | < 45 fps |
| Search response | < 100ms | > 300ms |
| Memory (idle) | < 100MB | > 200MB |

## Advanced Task Cancellation (DEV-8)

Beyond basic `Task.checkCancellation()`:

```swift
// withTaskCancellationHandler for cleanup
func downloadFile(url: URL) async throws -> Data {
    let handle = FileHandle(forWritingAtPath: tempPath)
    return try await withTaskCancellationHandler {
        try await performDownload(url: url)
    } onCancel: {
        handle?.closeFile()  // Cleanup runs even on cancellation
        try? FileManager.default.removeItem(atPath: tempPath)
    }
}

// Cancellation-aware loops
func processAllItems(_ items: [Item]) async throws -> [Result] {
    var results: [Result] = []
    for item in items {
        try Task.checkCancellation()  // Exit early if cancelled
        results.append(try await process(item))
    }
    return results
}
```

### When Tasks Get Cancelled
- `.task` modifier cancels when the view disappears
- `async let` cancels siblings when one throws
- `TaskGroup` cancels remaining children when one throws
- Manual `task.cancel()` sets the cancellation flag

## Instruments Integration (DEV-7)

### Launch From Xcode
Product > Profile (Cmd+I) > Choose template

### Launch From Terminal
```bash
# Open Instruments with Time Profiler
xcrun instruments -t "Time Profiler" -D trace.trace MyApp.app

# Open Instruments with specific PID
xcrun instruments -t "Allocations" -p $(pgrep MyApp)
```

### What to Profile and When
- **Before code review:** Run Time Profiler on any new screen with >50 items
- **After Core Data changes:** Run Core Data template to check fault counts
- **Memory concerns:** Run Leaks after implementing any observation pattern
