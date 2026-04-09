---
name: macos-dnd
description: "macOS drag-and-drop patterns using Transferable, onDrag/onDrop, and dropDestination. Use when implementing list reordering, cross-app drops, or file drops."
allowed-tools: [Read, Glob, Grep]
---

# Drag and Drop (macOS)

## Transferable Protocol (macOS 13+, Preferred)

The modern approach. Conform your types to `Transferable`:

```swift
struct Account: Identifiable, Codable, Transferable {
    let id: UUID
    var name: String
    var balance: Decimal

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .account)
    }
}

// Define custom UTType
extension UTType {
    static var account = UTType(exportedAs: "com.myapp.account")
}
```

## List Reordering

```swift
struct AccountListView: View {
    @State private var accounts: [Account] = []

    var body: some View {
        List {
            ForEach(accounts) { account in
                AccountRow(account: account)
            }
            .onMove { source, destination in
                accounts.move(fromOffsets: source, toOffset: destination)
            }
        }
    }
}
```

`.onMove` gives you drag-to-reorder for free in `List` with `ForEach`.

## Drag from Your App

```swift
AccountRow(account: account)
    .draggable(account) // Requires Transferable conformance
```

Or with a custom preview:
```swift
.draggable(account) {
    Label(account.name, systemImage: "building.columns")
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
}
```

## Drop into Your App

### dropDestination (macOS 13+, simpler)

```swift
List {
    ForEach(categories) { category in
        CategoryRow(category: category)
            .dropDestination(for: Account.self) { accounts, _ in
                moveAccounts(accounts, to: category)
                return true
            }
    }
}
```

### onDrop (macOS 11+, more control)

```swift
.onDrop(of: [.account, .fileURL], isTargeted: $isTargeted) { providers in
    for provider in providers {
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in
                    importFile(at: url)
                }
            }
        }
    }
    return true
}
```

## File Drops from Finder

Accept files dragged from Finder:

```swift
struct ImportDropZone: View {
    @State private var isTargeted = false

    var body: some View {
        ContentUnavailableView("Drop Files Here", systemImage: "arrow.down.doc")
            .dropDestination(for: URL.self) { urls, _ in
                let csvFiles = urls.filter { $0.pathExtension == "csv" }
                guard !csvFiles.isEmpty else { return false }
                importCSVFiles(csvFiles)
                return true
            } isTargeted: { targeted in
                isTargeted = targeted
            }
            .border(isTargeted ? Color.accentColor : .clear, width: 2)
    }
}
```

## Cross-App Drag (Export)

For dragging data out of your app to other apps:

```swift
struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack { /* ... */ }
            .draggable(transaction.csvLine) // String is Transferable by default
    }
}
```

Built-in `Transferable` types: `String`, `Data`, `URL`, `Image`, `Color`, `AttributedString`.

## Multiple Representations

Offer multiple formats so different drop targets can pick what they support:

```swift
struct Transaction: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .transaction)
        ProxyRepresentation(exporting: \.csvLine)        // Plain text fallback
        FileRepresentation(exportedContentType: .commaSeparatedText) { transaction in
            let data = transaction.csvLine.data(using: .utf8)!
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("export.csv")
            try data.write(to: url)
            return SentTransferredFile(url)
        }
    }
}
```

## Accessibility

Drag-and-drop must have keyboard alternatives:
- List reordering: `.onMove` + Edit mode (system provides Move Up/Down in accessibility)
- Drop zones: provide a button/menu alternative for the same action
- Never make drag-and-drop the ONLY way to perform an operation

## Pitfalls

- `Transferable` requires macOS 13+. For older targets, use `NSItemProvider` directly.
- `.onMove` only works inside `ForEach` within a `List`. Not in `LazyVStack` or `ScrollView`.
- `dropDestination` replaces content by default. Use `onDrop` if you need append behavior.
- File drops from Finder give you sandbox-scoped URLs. Access with `url.startAccessingSecurityScopedResource()` if needed.
- Always provide `isTargeted` feedback so users know where they can drop.
