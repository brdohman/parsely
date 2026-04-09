---
paths:
  - "app/**/*App.swift"
---

# macOS Menu Bar Requirements

Every macOS app must define its menu bar commands in the App struct's `.commands {}` modifier.

## What SwiftUI Provides Automatically

- **App menu:** About, Settings (if Settings scene exists), Services, Hide, Quit
- **File menu:** New Window (Cmd+N), Close (Cmd+W)
- **Edit menu:** Undo/Redo, Cut/Copy/Paste, Select All
- **Window menu:** Minimize, Zoom, window list
- **Help menu:** Search field

## What You Must Add

### 1. SidebarCommands (if using NavigationSplitView)

```swift
.commands {
    SidebarCommands()  // Adds sidebar toggle to View menu
}
```

### 2. App-Specific Menus

```swift
.commands {
    CommandMenu("Transactions") {
        Button("New Transaction") { newTransaction() }
            .keyboardShortcut("T")
        Button("Import...") { importTransactions() }
            .keyboardShortcut("I", modifiers: [.command, .shift])
        Divider()
        Button("Refresh") { refresh() }
            .keyboardShortcut("R")
    }
}
```

### 3. Standard Menu Additions

```swift
.commands {
    // Add to File menu
    CommandGroup(after: .newItem) {
        Button("New from Template...") { newFromTemplate() }
            .keyboardShortcut("N", modifiers: [.command, .shift])
    }
}
```

## Keyboard Shortcut Conventions

Do NOT reassign these standard shortcuts:

| Shortcut | Action | Provided By |
|---|---|---|
| Cmd+Q | Quit | System |
| Cmd+H | Hide | System |
| Cmd+, | Settings | Settings scene |
| Cmd+N | New Window | WindowGroup |
| Cmd+W | Close | System |
| Cmd+M | Minimize | System |
| Cmd+Z | Undo | Edit menu |
| Cmd+C/X/V | Copy/Cut/Paste | Edit menu |

## Context Menus

```swift
.contextMenu {
    Button("Edit") { edit() }
    Button("Delete", role: .destructive) { delete() }
    Divider()
    Menu("Share") {
        Button("Email") { share(.email) }
        Button("Messages") { share(.messages) }
    }
}
```

## FocusedValue for Dynamic Menus

Use `@FocusedValue` when menu items depend on the active view's state:

```swift
struct MyCommands: Commands {
    @FocusedValue(DataModel.self) private var model: DataModel?

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Duplicate") { model?.duplicateSelected() }
                .disabled(model == nil)
                .keyboardShortcut("D")
        }
    }
}
```
