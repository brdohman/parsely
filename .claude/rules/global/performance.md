---
paths:
  - "app/**/*.swift"
---

# Performance Standards (macOS)

## Lazy Loading

- Use `LazyVStack`/`LazyHStack` for lists with >20 items
- Use `LazyVGrid` for grid layouts
- Never load all data at once for paginated content
- Prefer `@Query` with `fetchLimit` over loading entire Core Data tables

```swift
// Good — lazy loading with fetch limit
@Query(sort: \Item.date, order: .reverse)
var items: [Item]  // SwiftData handles lazy fetching

// Bad — loading everything into memory
let allItems = try context.fetch(FetchDescriptor<Item>())
```

## Background Processing

- Use `Task { }` for async work, never block the main thread
- Heavy computation goes to background: `Task.detached(priority: .background)`
- File I/O, network calls, Core Data writes: always async
- Use `@MainActor` only for UI updates

```swift
// Good — background processing with main actor UI update
func processLargeDataSet() async {
    let result = await Task.detached(priority: .background) {
        return heavyComputation()
    }.value
    await MainActor.run {
        self.state = .loaded(result)
    }
}
```

## Memory Management

- Use `weak` references in closures that capture `self` from non-`@Observable` types
- `@Observable` classes use `withObservationTracking` — no retain cycle risk from SwiftUI views
- Release large objects (images, data buffers) when views disappear
- Profile with Instruments > Leaks before shipping

## Core Data Performance

- Use `NSFetchRequest` with `fetchBatchSize` for large result sets
- Add indexes on frequently queried attributes
- Use `NSAsynchronousFetchRequest` for background fetches
- Batch delete with `NSBatchDeleteRequest` instead of looping

## SwiftUI Performance

- Extract subviews to prevent unnecessary redraws
- Use `EquatableView` for views with expensive body computation
- Avoid computed properties in `body` that trigger re-evaluation
- Use `.task` modifier for async loading, not `.onAppear` with `Task { }`

## Never

- Block the main thread with synchronous network calls or heavy computation
- Load unbounded data sets without pagination or fetch limits
- Ignore Instruments profiling for release builds
- Use `Timer.publish` for polling — use async `Task.sleep` patterns instead
