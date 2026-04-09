---
name: test-generator
description: Generate XCTest templates for unit tests, integration tests, and UI tests. Use when adding test coverage to ViewModels, services, or repositories.
disable-model-invocation: true
context: fork
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Test Generator

Generate test templates for unit tests, integration tests, and UI tests in iOS/macOS apps.

## When to Use

- User wants to add tests to their app
- User asks about unit testing, UI testing, or XCTest
- User wants to test ViewModels, services, or repositories
- User mentions TDD or test-driven development

## Pre-Generation Checks

Before generating, verify:

1. **Existing Test Targets**
   ```bash
   # Check for test targets
   find . -name "*Tests" -type d | head -5
   grep -r "testTarget" Package.swift 2>/dev/null
   ```

2. **Testing Frameworks**
   ```bash
   # Check for Swift Testing or XCTest usage
   grep -r "import XCTest\|import Testing" --include="*.swift" | head -5
   ```

3. **Project Architecture**
   ```bash
   # Identify patterns (MVVM, TCA, etc.)
   grep -r "ViewModel\|Reducer\|UseCase" --include="*.swift" | head -5
   ```

## Configuration Questions

### 1. Testing Framework
- **Swift Testing** (Recommended, iOS 16+) - Modern, expressive syntax
- **XCTest** - Traditional framework, all iOS versions
- **Both** - Mix of frameworks

### 2. Test Types to Generate
- **Unit Tests** - Test individual components in isolation
- **Integration Tests** - Test component interactions
- **UI Tests** - Test user interface and flows
- **All** - Complete test coverage

### Deduplication Check

Before generating tests, verify the behavior is not already covered:
- If a ViewModel test uses a real service backend and asserts the result, do NOT generate a separate service test for the same operation
- Do NOT generate tests for `Equatable`, `Hashable`, `CaseIterable`, or `Codable` conformances synthesized by the compiler
- If 3+ tests follow identical structure, generate a parameterized test (loop over `[(input, expected)]`) instead of N separate methods
- See `.claude/rules/global/testing-requirements.md` "When NOT to Write Tests" for the full list

### 3. Architecture Pattern
- **MVVM** - ViewModel tests
- **TCA** - Reducer tests
- **Repository** - Data layer tests
- **Custom** - Based on project structure

## Generated Files

### Unit Tests
```
Tests/UnitTests/
├── ViewModelTests/
│   └── ItemViewModelTests.swift
├── ServiceTests/
│   └── APIClientTests.swift
└── RepositoryTests/
    └── ItemRepositoryTests.swift
```

### UI Tests
```
Tests/UITests/
├── Screens/
│   └── HomeScreenTests.swift
├── Flows/
│   └── OnboardingFlowTests.swift
└── Helpers/
    └── TestHelpers.swift
```

## Swift Testing (Modern)

### Basic Test Structure

```swift
import Testing
@testable import YourApp

@Suite("Item ViewModel Tests")
struct ItemViewModelTests {

    @Test("loads items successfully")
    func loadsItems() async throws {
        let mockRepository = MockItemRepository()
        let viewModel = ItemViewModel(repository: mockRepository)

        await viewModel.loadItems()

        #expect(viewModel.items.count == 3)
        #expect(viewModel.isLoading == false)
    }

    @Test("handles empty state")
    func handlesEmptyState() async {
        let mockRepository = MockItemRepository(items: [])
        let viewModel = ItemViewModel(repository: mockRepository)

        await viewModel.loadItems()

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.showEmptyState)
    }
}
```

### Parameterized Tests

```swift
@Test("validates email format", arguments: [
    ("valid@email.com", true),
    ("invalid", false),
    ("no@tld", false),
    ("test@domain.co.uk", true)
])
func validatesEmail(email: String, isValid: Bool) {
    #expect(EmailValidator.isValid(email) == isValid)
}
```

## XCTest (Traditional)

### Basic Test Structure

```swift
import XCTest
@testable import YourApp

final class ItemViewModelTests: XCTestCase {

    var sut: ItemViewModel!
    var mockRepository: MockItemRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockItemRepository()
        sut = ItemViewModel(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func testLoadsItems() async throws {
        await sut.loadItems()

        XCTAssertEqual(sut.items.count, 3)
        XCTAssertFalse(sut.isLoading)
    }
}
```

## Test Patterns

### Testing ViewModels

```swift
@Suite("ViewModel Tests")
struct ViewModelTests {

    @Test("state transitions correctly")
    func stateTransitions() async {
        let vm = ItemViewModel(repository: MockItemRepository())

        #expect(vm.state == .idle)

        await vm.loadItems()

        #expect(vm.state == .loaded)
    }

    @Test("error handling")
    func errorHandling() async {
        let failingRepo = MockItemRepository(shouldFail: true)
        let vm = ItemViewModel(repository: failingRepo)

        await vm.loadItems()

        #expect(vm.state == .error)
        #expect(vm.errorMessage != nil)
    }
}
```

### Testing Async Code

```swift
@Test("fetches data asynchronously")
func fetchesData() async throws {
    let service = APIService()

    let result = try await service.fetchItems()

    #expect(result.count > 0)
}

@Test("times out appropriately")
func timesOut() async {
    await #expect(throws: TimeoutError.self) {
        try await withTimeout(seconds: 1) {
            try await Task.sleep(for: .seconds(5))
        }
    }
}
```

## Mock Creation

### Protocol-Based Mocks

```swift
protocol ItemRepository {
    func fetchItems() async throws -> [Item]
    func saveItem(_ item: Item) async throws
}

final class MockItemRepository: ItemRepository {
    var items: [Item] = []
    var shouldFail = false
    var saveCallCount = 0

    func fetchItems() async throws -> [Item] {
        if shouldFail {
            throw TestError.mockFailure
        }
        return items
    }

    func saveItem(_ item: Item) async throws {
        saveCallCount += 1
        items.append(item)
    }
}
```

## UI Testing

### Screen Object Pattern

```swift
import XCTest

final class HomeScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    var itemList: XCUIElement {
        app.collectionViews["itemList"]
    }

    var addButton: XCUIElement {
        app.buttons["addItem"]
    }

    func tapItem(at index: Int) {
        itemList.cells.element(boundBy: index).tap()
    }

    func addNewItem(title: String) {
        addButton.tap()
        app.textFields["itemTitle"].tap()
        app.textFields["itemTitle"].typeText(title)
        app.buttons["save"].tap()
    }
}
```

## Integration Steps

### 1. Add Test Target

In Xcode:
1. File > New > Target
2. Choose "Unit Testing Bundle" or "UI Testing Bundle"
3. Name appropriately (e.g., `YourAppTests`)

### 2. Configure Test Scheme

1. Edit Scheme > Test
2. Add test targets
3. Configure code coverage

### 3. Run Tests

```bash
# Command line
xcodebuild test -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 16'

# With coverage
xcodebuild test -scheme YourApp -enableCodeCoverage YES
```

## Test Data Management (QA-4)

### Test Fixtures

**REQUIRED:** All test data must use `TestFixtures` helpers. Never hardcode passwords, tokens, or secrets inline. SAST tools (Aikido) flag hardcoded credentials as real findings even in tests.

Create reusable test data factories instead of inline construction:

```swift
enum TestFixtures {
    // Credentials — generate programmatically, never use real-looking strings
    static func validPassword() -> String { String(repeating: "Aa1!", count: 3) }
    static func weakPassword() -> String { String(repeating: "a", count: 3) }
    static func validToken() -> String { String(repeating: "t", count: 32) }
    static func validEmail() -> String { "test@example.com" }

    // Domain objects
    static func item(title: String = "Test Item", status: String = "active") -> Item {
        Item(id: UUID(), title: title, status: status, createdAt: Date())
    }

    static func items(count: Int = 5) -> [Item] {
        (0..<count).map { item(title: "Item \($0)") }
    }
}
```

Check if the project already has test helpers (e.g., `TestFixtures.swift`) before creating new ones — reuse and extend existing helpers.

### Test State Isolation
Each test must start with clean state. Never depend on execution order:
- Use `setUp()` to create fresh instances
- Use `tearDown()` to nil out all properties
- Core Data tests: always use `NSInMemoryStoreType`
- UserDefaults tests: use a unique suite name per test

## Performance Testing (QA-5)

```swift
func testListLoadPerformance() {
    let options = XCTMeasureOptions()
    options.iterationCount = 5

    measure(options: options) {
        // Operation to measure
        sut.loadItems()
    }
}

// Set baselines in Xcode: Edit Scheme > Test > Options > Performance
```

Use `XCTMetric` for specific measurements:
- `XCTClockMetric` — wall clock time
- `XCTMemoryMetric` — memory usage
- `XCTCPUMetric` — CPU time

## Flaky Test Management (QA-6)

Signs of a flaky test:
- Uses `Task.sleep` or `DispatchQueue.asyncAfter` for timing
- Depends on network or file system state
- Depends on test execution order
- Uses shared mutable state between tests

Fixes:
- Replace timing with `XCTestExpectation` or async/await
- Mock all external dependencies
- Reset state in `setUp`/`tearDown`
- Use `@MainActor` for UI state tests

## Coverage Interpretation (QA-7)

Coverage thresholds: **100% ViewModels/business logic, 80% Services**.

What coverage numbers actually mean:
- A covered line means execution reached it — NOT that the output was verified
- Branch coverage matters more than line coverage (both paths of an `if` tested?)
- 80% coverage with good assertions > 95% coverage with no assertions

```bash
# Extract coverage after test run
xcrun xccov view --report --json DerivedData/Logs/Test/*.xcresult
```

## Regression Test Strategy (QA-8)

After a bug fix:
1. Write a test that would have caught the bug BEFORE fixing it
2. Verify the test fails against the old code (mentally or via git stash)
3. Fix the bug
4. Verify the test passes

When to run the full suite vs. targeted:
- **Full suite:** Before code review handoff, after any Core Data migration, after dependency updates
- **Targeted:** During development, after single-file fixes

## Test Isolation Patterns (QA-9)

```swift
// BAD — shared state between tests
static var sharedViewModel = ViewModel()

// GOOD — fresh instance per test
var sut: ViewModel!
override func setUp() { sut = ViewModel(service: MockService()) }
override func tearDown() { sut = nil }
```

Core Data isolation:
```swift
// Each test gets its own in-memory container
override func setUp() {
    let container = NSPersistentContainer(name: "Model")
    let desc = NSPersistentStoreDescription()
    desc.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [desc]
    container.loadPersistentStores { _, _ in }
    context = container.viewContext
}
```

## Parameterized Testing (QA-10)

Test multiple inputs without duplicating test methods:

```swift
// Swift Testing (preferred)
@Test("validates email", arguments: [
    ("user@example.com", true),
    ("invalid", false),
    ("", false),
    ("user@.com", false)
])
func validatesEmail(email: String, expected: Bool) {
    #expect(Validator.isValidEmail(email) == expected)
}

// XCTest fallback — loop with context
func testEmailValidation() {
    let cases: [(input: String, valid: Bool)] = [
        ("user@example.com", true), ("invalid", false), ("", false)
    ]
    for testCase in cases {
        XCTAssertEqual(Validator.isValidEmail(testCase.input), testCase.valid,
                       "Failed for input: \(testCase.input)")
    }
}
```

## Best Practices

1. **Test one thing per test** - Clear, focused tests
2. **Use descriptive names** - Tests as documentation
3. **Arrange-Act-Assert** - Clear test structure
4. **Mock external dependencies** - Isolate units
5. **Test edge cases** - Empty, nil, error states
6. **Keep tests fast** - No real network/disk

## References

- [Swift Testing](https://developer.apple.com/documentation/testing)
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
