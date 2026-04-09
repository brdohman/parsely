---
paths:
  - "app/**/*.swift"
---

# Error Handling Standards

## Typed Errors

Define domain-specific error types. Never throw raw `Error`.

```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case invalidResponse(statusCode: Int)
    case decodingFailed(underlying: DecodingError)
    case persistenceFailed(operation: String, underlying: Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "No internet connection"
        case .invalidResponse(let code): return "Server error (\(code))"
        case .decodingFailed: return "Unable to read server response"
        case .persistenceFailed(let op, _): return "Failed to \(op)"
        case .unauthorized: return "Please sign in again"
        }
    }
}
```

## Error Propagation

- Services throw typed errors
- ViewModels catch and map to user-facing state
- Views display error state from ViewModel

```swift
// Service — throws typed error
func fetchItems() async throws -> [Item] {
    do {
        return try await apiClient.fetch(.items)
    } catch let afError as AFError {
        throw AppError.networkUnavailable
    }
}

// ViewModel — catches and sets state
func load() async {
    state = .loading
    do {
        let items = try await service.fetchItems()
        state = .loaded(items)
    } catch {
        state = .error(error)
    }
}
```

## User-Facing Error Messages

- Use `LocalizedError.errorDescription` for display text
- Never show raw error types, stack traces, or technical details to users
- Provide actionable guidance: "Check your connection and try again"
- Use `alert()` modifier for recoverable errors, `ContentUnavailableView` for load failures

## Never

- Use `try!` or `fatalError()` in production code
- Catch errors silently (swallow without logging or state update)
- Show raw `error.localizedDescription` without mapping to user-friendly text
- Throw `NSError` directly — use Swift typed errors
