---
paths:
  - "app/**/Views/**/*.swift"
  - "app/**/Components/**/*.swift"
---

# SwiftUI View Standards

## View Structure

```swift
struct MyView: View {
    // 1. Environment
    @Environment(\.dismiss) private var dismiss

    // 2. State
    @State private var localState: String = ""

    // 3. Bindings
    @Binding var externalState: Bool

    // 4. Dependencies
    let viewModel: MyViewModel

    // 5. Body
    var body: some View {
        content
            .onAppear { viewModel.onAppear() }
    }

    // 6. Computed views (private)
    @ViewBuilder
    private var content: some View {
        // ...
    }
}
```

## State Management

| Property Wrapper | Use For |
|-----------------|---------|
| `@State` | View-local simple state |
| `@Binding` | Two-way binding from parent |
| `@Environment` | System values, dismiss, colorScheme |
| `let viewModel` | ViewModel reference (no wrapper needed with @Observable) |

## ViewModels

Use `@Observable` macro (macOS 14+):

```swift
@Observable
final class MyViewModel {
    enum State {
        case idle
        case loading
        case loaded(Data)
        case error(Error)
    }

    private(set) var state: State = .idle

    func load() async {
        state = .loading
        do {
            let data = try await service.fetch()
            state = .loaded(data)
        } catch {
            state = .error(error)
        }
    }
}
```

## Layout Guidelines

- Use semantic spacing: `.padding()` over hardcoded values
- Prefer built-in components over custom
- Use SF Symbols for icons
- Support Dark Mode (use system colors)

## Accessibility

Every interactive element needs:
```swift
Button("Save") { ... }
    .accessibilityLabel("Save document")
    .accessibilityHint("Saves current changes")
```

## Never

- Use `@StateObject` or `@ObservedObject` (use @Observable instead)
- Put business logic in views
- Use hardcoded colors (use system colors)
- Skip accessibility labels on buttons/controls
- Create massive view bodies (extract subviews)
