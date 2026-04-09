---
name: xctest-patterns
description: XCTest patterns for macOS Swift apps. Unit tests, async tests, Core Data tests, mock patterns, and assertion reference. Use when writing or reviewing tests.
user-invocable: false
---

# XCTest Patterns

## Unit Test Structure

```swift
import XCTest
@testable import AppName

final class SomeViewModelTests: XCTestCase {
    var sut: SomeViewModel!
    var mockService: MockService!

    override func setUp() {
        super.setUp()
        mockService = MockService()
        sut = SomeViewModel(service: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    func testLoadSuccess() async {
        // Given
        mockService.result = .success(testData)
        // When
        await sut.load()
        // Then
        guard case .loaded(let items) = sut.state else { return XCTFail("Expected loaded") }
        XCTAssertEqual(items.count, 2)
    }
}
```

## Async Test Structure

```swift
@MainActor
func testAsyncStateUpdate() async {
    // Given
    XCTAssertFalse(sut.isLoading)
    // When
    await sut.loadData()
    // Then
    XCTAssertFalse(sut.isLoading)
    XCTAssertNotNil(sut.data)
}
```

## Core Data Test Structure

```swift
final class CoreDataTests: XCTestCase {
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        container = NSPersistentContainer(name: "AppName")
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [desc]
        container.loadPersistentStores { _, error in XCTAssertNil(error) }
        context = container.viewContext
    }

    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }
}
```

## Mock Pattern

```swift
protocol ServiceProtocol: Sendable {
    func fetch() async throws -> [Item]
}

final class MockService: ServiceProtocol, @unchecked Sendable {
    var result: Result<[Item], Error> = .success([])
    func fetch() async throws -> [Item] { try result.get() }
}
```

## Test Data

All test data must use `TestFixtures` helpers. Never hardcode passwords, tokens, or secrets — SAST scanners flag these as real findings.

```swift
// In setUp or test methods:
sut.password = TestFixtures.validPassword()
sut.email = TestFixtures.validEmail()
mockService.result = .success(TestFixtures.item())
```

Check for existing `TestFixtures.swift` in the test target before creating new helpers.

## Key Assertions

| Assertion | Use For |
|-----------|---------|
| `XCTAssertEqual(a, b)` | Value equality |
| `XCTAssertTrue/False` | Boolean checks |
| `XCTAssertNil/NotNil` | Optional checks |
| `XCTAssertThrowsError` | Error throwing |
| `XCTFail("message")` | Explicit failure |

## Rules
- Use Given/When/Then structure
- Mark async ViewModel tests with `@MainActor`
- Use `@unchecked Sendable` on mocks only
- Use in-memory Core Data store for tests
- Always nil out sut and mocks in tearDown

## MCP Test Execution (When Xcode Open)

When Xcode MCP is available, prefer these over `xcodebuild test`:

```
# Discover available test targets and classes
mcp__xcode__GetTestList(tabIdentifier: "...")

# Run all tests (structured JSON results)
mcp__xcode__RunAllTests(tabIdentifier: "...")

# Run specific tests for story-level QA
mcp__xcode__RunSomeTests(tabIdentifier: "...", tests: ["AppNameTests/ItemListViewModelTests"])
```

Returns structured results (test name, pass/fail, duration) vs parsing xcodebuild stdout.
See `.claude/skills/tooling/xcode-mcp/SKILL.md` for full reference.
