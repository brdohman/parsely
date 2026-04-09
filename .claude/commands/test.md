---
description: Run XCTest suite for current changes. Creates bug tasks for failures. Delegates to QA agent.
argument-hint: scope (unit, ui, ClassName, --coverage) - default: all
---

# /test

Runs the XCTest test suite.

## Usage

```
/test              # Run all tests
/test unit         # Unit tests only
/test ui           # UI tests only
/test MyViewModelTests  # Specific test class
/test --coverage   # With coverage report
```

## Delegation

**IMMEDIATELY delegate to QA agent.**

## Flow

1. Identify changed files
2. Run appropriate tests:
   - `unit` → Unit test target only
   - `ui` → UI test target only
   - `ClassName` → Specific test class
   - `--coverage` → All tests with coverage
   - Default → All tests
3. If failures, use `TaskCreate` to create bug tasks
4. Report results with coverage metrics

## Commands

### Xcode MCP (Preferred When Xcode Open)

```
# Discover available tests
mcp__xcode__GetTestList(tabIdentifier: "...")

# All tests (structured JSON results)
mcp__xcode__RunAllTests(tabIdentifier: "...")

# Specific test class
mcp__xcode__RunSomeTests(tabIdentifier: "...", tests: ["AppNameTests/MyViewModelTests"])
```

### Shell Fallback

```bash
# All tests
xcodebuild test -scheme AppName -destination 'platform=macOS'

# Unit tests only
xcodebuild test -scheme AppNameTests -destination 'platform=macOS'

# UI tests only
xcodebuild test -scheme AppNameUITests -destination 'platform=macOS'

# Specific test class
xcodebuild test -scheme AppName -only-testing:AppNameTests/MyViewModelTests -destination 'platform=macOS'

# With coverage
xcodebuild test -scheme AppName -destination 'platform=macOS' -enableCodeCoverage YES

# View coverage report
xcrun xccov view --report Build/Logs/Test/*.xcresult
```

## Coverage Requirements

- ViewModels: 100%
- Services: 80%
- General: 80%

## Output Format

### Pass
```
Tests passing

Unit: 34/34 passed
UI: 8/8 passed

Coverage:
- ViewModels: 100% (meets requirement)
- Services: 85% (meets requirement)
- Overall: 82%

Run `/commit` to save changes.
```

### Fail
```
Tests failing

Unit: 32/34 (2 failed)
UI: 7/8 (1 failed)

Bugs created:
- [task-bug-1] Bug: UserViewModel throws on empty email
  Blocks: [task-42]
- [task-bug-2] Bug: LoginView UI test fails on button tap
  Blocks: [task-42]

Fix bugs and run `/test` again.
```

## Task Tool Usage

```typescript
// Get current task being worked on
TaskList({ status: "in_progress" })

// Create bug task for test failure
TaskCreate({
  subject: "Bug: UserViewModel throws on empty email",
  description: `
## Failure Details
- Test file: app/AppName/AppNameTests/ViewModels/UserViewModelTests.swift
- Test name: testHandleEmptyEmailGracefully
- Error: Unexpectedly found nil while unwrapping an Optional value

## Stack Trace
[stack trace here]

## Expected Behavior
Should return validation error for empty email

## Actual Behavior
Force unwrap causes crash
`,
  metadata: {
    type: "bug",
    priority: 1,
    approval: "pending",
    blocked: false,
    review_stage: null,
    review_result: null,
    labels: [],
    blocks: ["task-42"],
    test_file: "app/AppName/AppNameTests/ViewModels/UserViewModelTests.swift"
  }
})

// After bugs are fixed and tests pass, update original task
TaskUpdate({
  task_id: "task-42",
  metadata: {
    tests_passing: true,
    last_test_run: "2024-01-15T14:30:00Z"
  }
})
```

## Bug Task Template

When creating bug tasks for test failures:

```typescript
TaskCreate({
  subject: "Bug: [concise failure description]",
  description: `
## Test Information
- File: [test file path]
- Test: [test method name]
- Class: [XCTestCase class name]

## Error
[Error message]

## Stack Trace
[Relevant stack trace]

## Steps to Reproduce
1. Run: xcodebuild test -scheme AppName -only-testing:AppNameTests/[TestClass]/[testMethod] -destination 'platform=macOS'
2. Observe failure

## Expected vs Actual
- Expected: [what should happen]
- Actual: [what happens]
`,
  metadata: {
    type: "bug",
    priority: 1,  // Test failures are high priority
    approval: "pending",
    blocked: false,
    review_stage: null,
    review_result: null,
    labels: [],
    blocks: ["parent-task-id"],
    category: "test-failure"
  }
})
```

## Common Issues

- **Tests not found**: Ensure test target is included in scheme (Product > Scheme > Edit Scheme > Test)
- **UI tests fail**: Check app is built for testing, ensure `ENABLE_TESTING_SEARCH_PATHS = YES`
- **Async tests timeout**: Use `XCTestExpectation` with appropriate timeout:
  ```swift
  let expectation = expectation(description: "Async operation")
  // async code...
  wait(for: [expectation], timeout: 5.0)
  ```
- **Simulator not found**: Check available destinations with `xcodebuild -showdestinations -scheme AppName`
- **Code signing errors**: Use `-allowProvisioningUpdates` or set `CODE_SIGN_IDENTITY=""` for CI

## Agent

Delegates to QA agent for full test verification.
