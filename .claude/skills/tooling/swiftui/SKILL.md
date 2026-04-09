---
name: swiftui-patterns
description: macOS Tahoe (26.0+) SwiftUI conventions and project layout standards. Not a tutorial — covers Tahoe-specific patterns and project deviations only.
user-invocable: false
allowed-tools: [Read, Glob, Grep]
---

# SwiftUI macOS Tahoe Conventions

## @Observable + @State Pattern (Project Standard)

```swift
// View owns ViewModel
@State private var viewModel = ItemListViewModel()

// Shared dependency via @Environment
@Environment(SessionViewModel.self) private var session
```

Never use `@StateObject`, `@ObservedObject`, or `@EnvironmentObject`.

## Liquid Glass (Tahoe 26.0+)

Use `.glassEffect()` for floating panels and overlay cards. Prefer `.regularMaterial` for sidebars and `.ultraThinMaterial` for popovers.

```swift
// Floating inspector panel
VStack { ... }
    .glassEffect()
    .padding(16)
```

## NavigationSplitView Column Widths (Project Standard)

```swift
NavigationSplitView {
    SidebarView()
        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
} detail: {
    DetailView()
}
.navigationSplitViewStyle(.balanced)
```

## Toolbar Placement

```swift
.toolbar {
    ToolbarItem(placement: .navigation) { /* back/breadcrumb */ }
    ToolbarItem(placement: .primaryAction) { /* main CTA */ }
    ToolbarItemGroup(placement: .automatic) { /* secondary actions */ }
}
.windowToolbarStyle(.unified)
```

## Tahoe Gotchas

**Animation in NSHostingView:** Use explicit timing; `.animation(.default)` may not fire.
```swift
.animation(.easeInOut(duration: 0.2), value: isExpanded)
```

**Transparency:** Test `.background(Color.white.opacity(0.5))` on device — system materials are safer.

**VStack layout:** Wrap in `.fixedSize(horizontal: false, vertical: true)` when height is unpredictable inside split views.

## Window Configuration (Project Standard)

```swift
WindowGroup {
    ContentView()
}
.defaultSize(width: 1100, height: 700)
.windowStyle(.hiddenTitleBar)
.windowToolbarStyle(.unified)
```

Auxiliary windows (inspector, settings) use `.windowResizability(.contentSize)`.

## View Lifecycle & Identity (DEV-4)

**When `body` recomputes:** Any `@State`, `@Binding`, `@Observable` property change triggers body recomputation for views that read that property. SwiftUI uses structural identity (position in the view tree) to determine which views to update.

**@State persistence:** `@State` survives body recomputation but is destroyed when the view's structural identity changes (e.g., moved to a different branch of an `if/else`).

```swift
// BAD — identity changes on toggle, destroying @State in ChildView
if showAlternate {
    ChildView()  // This is a NEW ChildView each toggle
} else {
    ChildView()  // Different structural identity
}

// GOOD — stable identity
ChildView()
    .opacity(showAlternate ? 0.5 : 1.0)
```

**EquatableView for expensive bodies:**
```swift
struct ExpensiveView: View, Equatable {
    let data: LargeDataSet

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data.id == rhs.data.id  // Only recompute body if ID changes
    }

    var body: some View { /* expensive layout */ }
}
```

## Memory Management with @Observable (DEV-6)

`@Observable` classes do NOT have the retain cycle risks of `ObservableObject` + `@Published` closures. SwiftUI observation tracking is automatic and non-retaining.

**When to use `weak`:**
- Closures in non-Observable classes that capture `self`
- `NotificationCenter` observers
- Delegate patterns

**When `weak` is NOT needed:**
- `@Observable` ViewModels referenced by `@State` in Views (SwiftUI manages lifecycle)
- `Task { }` closures in `@Observable` classes (tasks are structured)

```swift
// NotificationCenter — still needs weak
NotificationCenter.default.addObserver(
    forName: .NSManagedObjectContextObjectsDidChange,
    object: context, queue: .main
) { [weak self] _ in
    Task { @MainActor in self?.refresh() }
}
```
