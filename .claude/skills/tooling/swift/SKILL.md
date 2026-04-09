---
name: swift-patterns
description: Project-specific Swift conventions for this macOS app. Not a language tutorial — covers only deviations from standard Swift.
user-invocable: false
allowed-tools: [Read, Glob, Grep]
---

# Project Swift Conventions

## Services Must Be Actors

All service types use `actor`, not `class`. This is the project standard for thread safety.

```swift
actor ItemService: ItemServiceProtocol {
    static let shared = ItemService()
    // ...
}
```

## Typed Throws (Swift 6+)

Use domain-specific typed throws in services. Avoids catching `any Error` at call sites.

```swift
func fetchItems() throws(AppError) -> [Item]
```

## Strict Concurrency

Project targets Swift 6 strict concurrency. All types crossing async boundaries must be `Sendable`. Use `@unchecked Sendable` only on mock types in tests.

## @Observable Over ObservableObject

ViewModels use `@Observable` macro (macOS 14+). Never use `ObservableObject`/`@Published`. Views own ViewModels with `@State private var viewModel = MyViewModel()`.

## No Combine

Use async/await exclusively. No `Publisher`, `sink`, or `@Published` in production code.

## Migration Checklist (when touching legacy code)

- Replace `ObservableObject` + `@Published` with `@Observable`
- Replace completion handlers with `async throws`
- Add `Sendable` conformance to value types used across tasks
- Replace `class` services with `actor`
