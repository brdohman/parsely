---
name: core-data-patterns
description: Core Data persistence patterns for macOS apps. Stack setup, CRUD operations, relationships, migrations.
user-invocable: false
allowed-tools: [Read, Glob, Grep]
---

# Core Data Skill

## Overview

Core Data persistence patterns for macOS apps.

## Stack Setup

```swift
actor PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AppModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data failed: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
```

## Entity Pattern

```swift
@objc(Item)
public class Item: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

extension Item {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        NSFetchRequest<Item>(entityName: "Item")
    }

    static func create(in context: NSManagedObjectContext, title: String) -> Item {
        let item = Item(context: context)
        item.id = UUID()
        item.title = title
        item.createdAt = Date()
        item.updatedAt = Date()
        return item
    }
}
```

## Fetch Requests

```swift
// Basic fetch
let request = Item.fetchRequest()
request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: false)]
request.fetchLimit = 50
request.fetchBatchSize = 20

let items = try context.fetch(request)
```

## SwiftUI Integration

```swift
struct ItemListView: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)],
        animation: .default
    )
    private var items: FetchedResults<Item>

    var body: some View {
        List(items) { item in
            Text(item.title)
        }
    }
}
```

## Background Operations

```swift
func importData(_ data: [ImportItem]) async throws {
    let context = PersistenceController.shared.newBackgroundContext()

    try await context.perform {
        for item in data {
            let entity = Item(context: context)
            entity.id = UUID()
            entity.title = item.title
        }
        try context.save()
    }
}
```

## Migrations

1. Create new model version in Xcode
2. Set as current version
3. Enable automatic migration:

```swift
description.shouldMigrateStoreAutomatically = true
description.shouldInferMappingModelAutomatically = true
```

## Testing

```swift
final class CoreDataTests: XCTestCase {
    var controller: PersistenceController!

    override func setUp() {
        controller = PersistenceController(inMemory: true)
    }
}
```

## CloudKit Container (DA-4)

For iCloud sync, use `NSPersistentCloudKitContainer` instead of `NSPersistentContainer`:

```swift
let container = NSPersistentCloudKitContainer(name: "AppModel")
// CloudKit sync is automatic after setup
// Conflict resolution uses NSMergeByPropertyObjectTrumpMergePolicy (local wins)
```

**CloudKit schema migration:** CloudKit schemas are additive only — you can add fields/entities but never remove or rename them. Plan schema carefully.

## Derived Attributes (DA-5)

Use derived attributes for denormalized counts/aggregates to avoid expensive fetch requests:

In the Xcode model editor: select attribute > Data Model Inspector > Derived > set derivation expression.

```
// Count of children: "children.@count"
// Latest date: "children.@max.createdAt"
```

Derived attributes are computed by Core Data automatically on save. They avoid N+1 query problems.

## Abstract Entity Patterns (DA-6)

Use abstract entities for shared attributes across entity types:

```
AbstractBaseEntity (abstract)
  ├── id: UUID
  ├── createdAt: Date
  ├── updatedAt: Date
  │
  ├── TaskEntity (concrete)
  │   └── title: String
  │
  └── NoteEntity (concrete)
      └── body: String
```

**When to use:** Multiple entities share 3+ identical attributes. **Avoid when:** Only `id`/`createdAt`/`updatedAt` are shared (just add them to each entity directly — the inheritance complexity isn't worth it for 3 fields).

## Core Data Debugging (DA-7)

Launch arguments for diagnostics:

| Argument | What It Shows |
|----------|--------------|
| `-com.apple.CoreData.SQLDebug 1` | SQL queries executed |
| `-com.apple.CoreData.SQLDebug 3` | SQL + bind variables |
| `-com.apple.CoreData.MigrationDebug 1` | Migration steps |
| `-com.apple.CoreData.ConcurrencyDebug 1` | Thread violations |
| `-com.apple.CoreData.CloudKitDebug 1` | CloudKit sync activity |

Add in Xcode: Edit Scheme > Run > Arguments > Arguments Passed On Launch.

**Instruments Core Data template:** Shows fetch counts, fault counts, save durations. Use when debugging performance. High fault count = objects being accessed that weren't prefetched.

## Data Integrity Constraints (DA-8)

### Unique Constraints
Set in Xcode model editor: select entity > Data Model Inspector > Constraints. Prevents duplicate entries on the constrained fields.

```
// Entity: Tag
// Unique constraints: name
// → Two Tags with the same name will merge instead of creating duplicates
```

### Validation Rules
Add in model editor per attribute: Min Value, Max Value, Regex for strings.

```swift
// Programmatic validation (for complex rules)
override func validateForInsert() throws {
    try super.validateForInsert()
    guard title.count >= 1 else {
        throw ValidationError.titleRequired
    }
}
```

### Fetch Request Validation
Always validate predicates against the model at development time:
```swift
// Use typed key paths instead of string-based predicates where possible
request.predicate = NSPredicate(format: "%K == %@", #keyPath(Item.status), "active")
```
