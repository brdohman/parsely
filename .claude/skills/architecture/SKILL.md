---
name: architecture-patterns
description: SOLID principles, DRY, Clean Architecture, and design patterns for macOS development. Use when making architectural decisions or reviewing code structure.
allowed-tools: [Read, Glob, Grep]
---

# Architecture & Design Patterns

Reference material for architectural decisions in macOS Swift/SwiftUI applications.

## Modules

- [architecture-principles.md](architecture-principles.md) - SOLID, DRY, Clean Architecture
- [modern-concurrency.md](../macos-best-practices/modern-concurrency.md) - Swift concurrency patterns (async/await, actors, structured concurrency)

## Code Smell Detection (SE-4)

During code review, watch for these patterns:

| Smell | Signal | Fix |
|-------|--------|-----|
| **God Object** | Class > 300 lines or > 10 methods | Split into focused types |
| **Feature Envy** | Method uses more properties from another class than its own | Move method to the other class |
| **Primitive Obsession** | Strings/ints used for domain concepts (status as String) | Create enum or value type |
| **Long Parameter List** | Function with > 4 parameters | Group into config struct |
| **Shotgun Surgery** | One change requires edits in 5+ files | Consolidate related logic |
| **Message Chain** | `a.b.c.d.doThing()` | Introduce delegation or facade |

## API Design Quality (SE-5)

Review function signatures for:
- **Naming clarity:** Does the name describe the action and return type? (`fetchItems()` not `getData()`)
- **Parameter ordering:** Most important first, optional last, closures at the end (trailing closure syntax)
- **Return type choice:** `Result<T, Error>` for operations that commonly fail, `throws` for exceptional failures, `Optional` for absent values
- **Protocol design:** Does the protocol have a single responsibility? Can it be implemented by a mock?

```swift
// BAD — vague name, unclear return
func process(_ data: Any) -> Any

// GOOD — clear name, typed, documented intent
func importTransactions(from csv: CSVFile) throws -> [Transaction]
```

## Coupling & Cohesion (SE-6)

**High cohesion (good):** All methods in a class relate to the same concept. A `TransactionService` only deals with transactions.

**Low coupling (good):** Classes depend on protocols, not concrete types. Changes to one module don't cascade.

Review checks:
- Count `import` statements — more than 3 internal imports suggests high coupling
- Check if removing a class requires changes in >2 other files
- Verify protocols have 1-3 methods (interface segregation)
- Ensure view models don't import service internals

## Concurrency Correctness (SE-7)

Beyond `@MainActor`, verify during code review:

- **Data race potential:** Mutable state accessed from multiple tasks without actor isolation
- **Sendable compliance:** Types crossing actor boundaries must be `Sendable`
- **Actor isolation boundaries:** Verify `nonisolated` is intentional, not accidental
- **Task lifetime:** Long-running tasks should be cancellable (`Task.checkCancellation()`)

```swift
// REVIEW FLAG — mutable state without isolation
class SharedCache {
    var items: [String: Item] = [:]  // NOT thread-safe
}

// CORRECT — actor-isolated
actor SharedCache {
    var items: [String: Item] = [:]  // Thread-safe by actor isolation
}
```
