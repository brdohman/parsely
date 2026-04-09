---
paths: ["**/*.swift"]
description: Test coverage thresholds and XCTest patterns
---

# Testing Requirements

## Coverage Thresholds

| Rule Type | Threshold | Enforcement |
|-----------|-----------|-------------|
| ViewModels | **100% of public behavior** | Blocks merge |
| Services | 80% | Blocks merge |
| General code | 80% | Warning |

**"100% of public behavior"** means: every public method's observable outcomes are tested. It does NOT mean a separate test for every code path, every default value, or every trivial getter. A single test that exercises a method's happy path and verifies 3 assertions counts as coverage for all 3 behaviors.

## What Must Be Tested

1. **ViewModels** - All public methods that produce observable state changes
2. **Services** - API calls (mocked), data transformations, error paths
3. **Database operations** - CRUD, migrations, cascade deletes
4. **Business logic** - Calculations, validations, rules

## Test Deduplication Principle

**A behavior should be tested at exactly one layer.** If a ViewModel test exercises a service method through a real (non-mock) backend, that service method does NOT also need a separate unit test unless the service has edge cases not reachable through the ViewModel.

Cross-layer deduplication rules:
- If conformance tests verify CRUD for both backends, dedicated `DatabaseService*Tests` files must NOT re-test the same CRUD operations against the same backend.
- If a ViewModel test uses `InMemoryDatabaseService` and asserts the result, that service path is covered. A separate `InMemoryDatabaseServiceTests` method testing the same operation is redundant.
- Integration tests that re-verify the same logic as unit tests should be limited to verifying the *integration* (wiring, lifecycle), not re-asserting the same business logic.

## When NOT to Write Tests

Do NOT write tests for:
- **Compiler-generated behavior**: `Equatable`, `Hashable`, `Codable`, `CaseIterable`, `Identifiable`, `RawRepresentable` conformances synthesized by the compiler.
- **Constant values**: A test that asserts `SomeType.maxCount == 5` catches zero bugs. If the constant changes, the test must change too.
- **Trivial default values**: Seven separate tests asserting each ViewModel property starts at nil/zero/empty should be ONE test with multiple assertions.
- **Language semantics**: Testing that `+= 1` increments an Int, that an invalid raw value returns nil for an enum, or that `id == rawValue` for an `Identifiable` enum.
- **Mock interaction counts** (unless the count IS the behavior): Prefer asserting observable outcomes (`sut.state == .loaded`) over asserting `mockService.fetchCallCount == 1`.

## Parameterized Tests

When multiple tests follow the same pattern with different inputs, use a **parameterized test** (loop over an array of `(input, expected)` tuples) instead of N separate test methods.

Good candidates for parameterization:
- Error type -> user message mapping (N error cases)
- Error type -> isRetryable flag
- Filter type -> isFiltered result
- Enum case -> display label / system image

```swift
// GOOD: 1 parameterized test replaces 13 separate tests
func testIsRetryableError() {
    let cases: [(SyncError, Bool)] = [
        (.networkUnavailable, true),
        (.serverError(500), true),
        (.unauthorized, false),
        // ... all cases
    ]
    for (error, expected) in cases {
        XCTAssertEqual(error.isRetryable, expected, "\(error)")
    }
}

// BAD: 13 separate tests with identical structure
func testIsRetryableError_NetworkUnavailable() { ... }
func testIsRetryableError_ServerError() { ... }
func testIsRetryableError_Unauthorized() { ... }
// ... 10 more
```

## Test Credentials — No Hardcoded Secrets

**Never hardcode passwords, tokens, API keys, or secrets in test code.** SAST tools (Aikido) flag hardcoded credentials in tests as real findings — these are not false positives.

Use dedicated helpers: `TestPasswordFactory` for credentials, `TestFixtures` for other test data. Before creating new ones, check if the project already has these helpers — reuse them.

```swift
// BAD — hardcoded password string in test
sut.password = "Test123!"
sut.password = "mySecretPassword"

// GOOD — use TestPasswordFactory for credentials
sut.password = TestPasswordFactory.validPassword()
sut.password = TestPasswordFactory.weakPassword()
sut.password = TestPasswordFactory.exceeding(maxLength: 128)

// GOOD — use TestFixtures for other test data
let user = TestFixtures.user()
let token = TestFixtures.validToken()
```

**Pattern: TestPasswordFactory** (dedicated credential helper)
```swift
enum TestPasswordFactory {
    static func validPassword() -> String {
        String(repeating: "Aa1!", count: 3)
    }
    static func weakPassword() -> String {
        String(repeating: "a", count: 3)
    }
    static func exceeding(maxLength: Int) -> String {
        String(repeating: "x", count: maxLength + 1)
    }
    static func empty() -> String { "" }
}
```

**Pattern: TestFixtures** (general test data)
```swift
enum TestFixtures {
    static func validToken() -> String { String(repeating: "t", count: 32) }
    static func validEmail() -> String { "test@example.com" }
    static func invalidEmail() -> String { "not-an-email" }
}
```

**Rules:**
- Check existing helpers first — reuse `TestPasswordFactory`, `TestFixtures`, etc.
- Generate credential values programmatically (`String(repeating:)`, `UUID().uuidString`)
- Never use real-looking passwords, tokens, or keys — even "fake" ones trigger SAST scanners
- Place helpers in `[Target]Tests/Helpers/` (e.g., `CashflowTests/Helpers/TestPasswordFactory.swift`)

## Test Structure

```swift
final class MyViewModelTests: XCTestCase {
    var sut: MyViewModel!  // System Under Test
    var mockService: MockService!

    override func setUp() {
        super.setUp()
        mockService = MockService()
        sut = MyViewModel(service: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    func testLoadSuccess() async throws {
        // Given
        mockService.result = .success(testData)

        // When
        await sut.load()

        // Then
        XCTAssertEqual(sut.state, .loaded(testData))
    }
}
```

## Mocking Pattern

```swift
protocol ServiceProtocol {
    func fetch() async throws -> Data
}

final class MockService: ServiceProtocol {
    var result: Result<Data, Error> = .success(Data())

    func fetch() async throws -> Data {
        try result.get()
    }
}
```

## UI Tests (Optional)

For critical user flows:
```swift
final class AppUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testMainFlow() {
        // Test critical path
    }
}
```

## Changed Files

Every PR must include tests for:
- New functions
- Modified logic
- Bug fixes (regression test)

## Never

- Skip ViewModel tests
- Test implementation details
- Use real network in unit tests
- Leave flaky tests unfixed
- Duplicate coverage across layers without justification
- Write separate tests for compiler-generated conformances
- Test hardcoded constant values
- Write N separate tests when a parameterized test would suffice
- Write separate initial-state tests for each property (consolidate into one)
- Hardcode passwords, tokens, or secrets in test code — use `TestFixtures`
