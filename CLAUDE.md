# Parsely

A macOS app for viewing and exploring JSONL (JSON Lines) files. Line-by-line parsing with collapsible JSON trees, multi-file tabs, search, and pretty-print export.

## Tech Stack

- **UI:** SwiftUI with MVVM architecture
- **Language:** Swift 5.0+
- **Patterns:** @Observable macro, async/await (no Combine)
- **Target:** macOS 14.0+
- **Testing:** XCTest (unit + UI tests)
- **Distribution:** Direct download (DMG), not App Store

## Project Structure

```
app/Parsely/
  Parsely.xcodeproj/
  Parsely/
    App/
      ParselyApp.swift          # App entry point, menu commands, keyboard shortcuts
    Models/
      JSONLDocument.swift        # File parsing, line collection
      JSONLLine.swift            # Individual line with parsed JSON
      JSONValue.swift            # Recursive JSON value enum
    ViewModels/
      ParselyViewModel.swift     # Per-tab state: document, selection, search, export
      TabManager.swift           # Tab collection management
    Views/
      Screens/
        TabbedRootView.swift     # Root view: NavigationSplitView + tabs + toolbar
        SidebarView.swift        # Line list with inline search
        DetailView.swift         # JSON detail renderer
        ContentView.swift        # UTType extension only
      Components/
        JSONValueView.swift      # Recursive JSON tree with collapse/expand
        SidebarRowView.swift     # Line preview row
        TabStripView.swift       # Tab bar component
        JumpToLineView.swift     # Jump-to-line modal
```

## Building

```bash
cd app/Parsely
xcodebuild -project Parsely.xcodeproj -scheme Parsely -configuration Debug build
```

Release build:
```bash
xcodebuild -project Parsely.xcodeproj -scheme Parsely -configuration Release build \
  CONFIGURATION_BUILD_DIR=/tmp/Parsely-release
```

## Quality Gates

| Gate | Requirement |
|-|-|
| **Build** | `xcodebuild` succeeds |
| **No Force Unwraps** | No `!` in production code |
| **No Print Statements** | Use `os.Logger`, not `print()` |
| **Accessibility** | Interactive elements have labels |

## Code Conventions

- **Naming:** PascalCase for types, camelCase for functions/variables
- **Files:** One primary type per file, named to match the type
- **ViewModels:** Use `@Observable` macro, not `@StateObject`/`@ObservedObject`
- **Async:** Use async/await, not Combine or completion handlers
- **Errors:** Typed errors with `LocalizedError`, no `try!` or `fatalError()` in production
- **Strings:** All user-visible strings use SwiftUI's automatic localization or `String(localized:)`

## Key Architecture Decisions

- **No `.searchable` modifier** — Replaced with inline `TextField` in sidebar to avoid a known AppKit layout recursion bug (FB13541783) with `NavigationSplitView`
- **No `DisclosureGroup`** — Replaced with custom chevron toggle to avoid recursive layout in `ScrollView` and to control indentation precisely
- **No `.animation()` on toolbar items** — Triggers AppKit layout recursion; use `withAnimation` in action handlers instead
- **`.toolbar(removing: .sidebarToggle)`** — Sidebar is always visible, no collapse
- **Tab strip inside detail column** — Not above `NavigationSplitView`, to keep sidebar rendering consistent regardless of tab count
- **`@State` intermediary for search binding** — Direct `@Observable` binding to `.searchable` causes crashes on macOS 14.x

## Bundle Identifiers

- **App:** `com.brandondohman.parsely`
- **UTType:** `com.brandondohman.parsely.jsonl`
- **Supported extensions:** `.jsonl`, `.ndjson`
