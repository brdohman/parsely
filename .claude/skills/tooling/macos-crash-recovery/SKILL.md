---
name: macos-crash-recovery
description: "macOS app crash recovery, state restoration, and autosave patterns. Use when implementing data persistence, app lifecycle, or any feature where data loss on crash is a concern."
allowed-tools: [Read, Glob, Grep]
---

# Crash Recovery & State Restoration

## App Lifecycle: Graceful Termination

Handle `NSApplicationDelegate.applicationShouldTerminate(_:)` to prompt for unsaved changes:

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard hasUnsavedChanges else { return .terminateNow }

        let alert = NSAlert()
        alert.messageText = "You have unsaved changes"
        alert.informativeText = "Do you want to save before quitting?"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            saveAll()
            return .terminateNow
        case .alertSecondButtonReturn:
            return .terminateNow
        default:
            return .terminateCancel
        }
    }
}
```

Register in your App struct:
```swift
@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

## State Restoration with SceneStorage

Restore the user's position after relaunch:

```swift
struct ContentView: View {
    @SceneStorage("selectedTab") private var selectedTab = "accounts"
    @SceneStorage("selectedAccountID") private var selectedAccountID: String?
    @SceneStorage("sidebarExpanded") private var sidebarExpanded = true

    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selectedAccountID)
        } detail: {
            if let accountID = selectedAccountID {
                AccountDetail(id: accountID)
            }
        }
    }
}
```

`@SceneStorage` survives app restart. Not suitable for sensitive data.

## Core Data Autosave

Save periodically and on key events, not just on quit:

```swift
actor PersistenceController {
    static let shared = PersistenceController()

    private let container: NSPersistentContainer

    /// Save if there are unsaved changes
    func saveIfNeeded() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            Logger.persistence.error("Autosave failed: \(error)")
        }
    }
}
```

**When to autosave:**
- After every user-initiated data change (create, edit, delete)
- On `NSApplication.willResignActiveNotification` (user switches away)
- On `NSApplication.willTerminateNotification` (app quitting)
- On a timer for long-running edits (every 30 seconds during active editing)

```swift
// In your App or ViewModel
NotificationCenter.default.addObserver(
    forName: NSApplication.willResignActiveNotification,
    object: nil, queue: .main
) { _ in
    Task { await PersistenceController.shared.saveIfNeeded() }
}
```

## Core Data Save Points for Multi-Step Operations

For operations that modify multiple objects (e.g., importing transactions):

```swift
func importTransactions(_ data: [TransactionData]) async throws {
    let context = container.newBackgroundContext()
    try await context.perform {
        for item in data {
            let transaction = Transaction(context: context)
            transaction.configure(from: item)
        }
        // Single save at the end — if it fails, nothing is partially committed
        try context.save()
    }
}
```

For very large imports, batch saves:
```swift
func importLargeDataset(_ items: [ItemData]) async throws {
    let context = container.newBackgroundContext()
    let batchSize = 100
    try await context.perform {
        for (index, item) in items.enumerated() {
            let entity = Item(context: context)
            entity.configure(from: item)
            if (index + 1) % batchSize == 0 {
                try context.save()
                context.reset() // Release memory
            }
        }
        if context.hasChanges { try context.save() }
    }
}
```

## QA Edge Case

Add this to QA testing checklist for any feature that modifies persistent data:

> Force-quit the app during the operation (Cmd+Q or kill from Activity Monitor). Relaunch. Verify no data loss and the UI recovers to a valid state.

## Never

- Rely solely on `applicationWillTerminate` for saving (not called on force-quit or crash)
- Store unsaved state only in memory with no periodic flush
- Leave Core Data contexts with pending changes for extended periods
- Skip `@SceneStorage` for navigation state that users expect to persist
