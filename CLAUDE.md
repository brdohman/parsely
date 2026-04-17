# Parsely

A macOS app for viewing and exploring JSONL (JSON Lines) and Markdown files. Line-by-line parsing with collapsible JSON trees, markdown rendering with header navigation, multi-file tabs, search, and pretty-print export.

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
      ParselyApp.swift          # App entry point + AppDelegate (NSAppleEventManager
                                # intercept for file opens, per-Space window creation),
                                # menu commands, keyboard shortcuts
    Models/
      JSONLDocument.swift        # File parsing, line collection
      JSONLLine.swift            # Individual line with parsed JSON
      JSONValue.swift            # Recursive JSON value enum
      MarkdownDocument.swift     # Markdown file parsing, heading extraction, block parser
      MarkdownHeading.swift      # Heading tree model (level, title, children)
    ViewModels/
      ParselyViewModel.swift     # Per-tab state: document, selection, search, export
      TabManager.swift           # Tab collection management (one instance per window)
    Views/
      Screens/
        TabbedRootView.swift     # Root view: NavigationSplitView + tabs + toolbar +
                                 # zoom; inlined WindowAccessor for NSWindow tracking
        SidebarView.swift        # Line list with inline search (JSONL)
        DetailView.swift         # JSON detail renderer
        MarkdownSidebarView.swift # Collapsible heading tree (Markdown)
        MarkdownDetailView.swift  # Rendered markdown with scroll-to-heading
        ContentView.swift        # UTType extension only
      Components/
        JSONValueView.swift      # Recursive JSON tree with collapse/expand
        SidebarRowView.swift     # Line preview row
        TabStripView.swift       # Tab bar component
        JumpToLineView.swift     # Jump-to-line modal
```

**Note:** This Xcode project uses the legacy (non-synchronized) group model. New `.swift` files are NOT auto-picked up — they must be added to `project.pbxproj` via Xcode. When an automated edit can't do that safely, INLINE small helper types (e.g., `WindowAccessor`) into an existing file in the same module.

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
- **File-open events via `NSAppleEventManager`, not `.onOpenURL`** — `CFBundleDocumentTypes` is declared in Info.plist (so the app registers as a viewer for `.jsonl`/`.md` in Finder). On macOS 26 SDK, AppKit's `NSDocumentController` routes those file-open Apple Events and spawns empty "ghost" windows when the SwiftUI scene count doesn't match. `AppDelegate.applicationWillFinishLaunching` registers a custom `kAEOpenDocuments` handler that runs BEFORE `NSDocumentController`, extracts URLs, and posts them via `.openFileURL` notification. SwiftUI's `.onOpenURL` is NOT used.
- **Per-Space windows via programmatic `NSHostingController<TabbedRootView>`** — The first window is a SwiftUI `Window(id: "main")` scene. Subsequent windows (one per macOS Space) are created in AppKit when a file is opened on a Space that has no existing Parsely window. Each window owns its own `TabManager`.
- **Serialize file-open routing** — `AppDelegate.route(urls:)` posts ONE `.openFileURL` notification with a `[URL]` payload; `TabbedRootView` processes them in a single `Task` with sequential `await manager.openFile(from:)` to avoid races on `TabManager.tabs` / `activeTabID`.

## Bundle Identifiers

- **App:** `com.brandondohman.parsely`
- **UTType:** `com.brandondohman.parsely.jsonl`
- **Supported extensions:** `.jsonl`, `.ndjson`, `.md`, `.markdown`, `.mdown`, `.mkd`
