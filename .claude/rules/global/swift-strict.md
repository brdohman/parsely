---
paths:
  - "app/**/*.swift"
---

# Swift Strict Standards

## Required

- Strict concurrency checking enabled
- No force unwrapping (!) except in tests
- No `Any` types - use generics or protocols
- `let` over `var`
- async/await over completion handlers
- Functions under 50 lines
- No Combine (use async/await instead)

## Patterns

```swift
// Good - optional binding
guard let value = optional else { return }

// Bad - force unwrap
let value = optional!

// Good - typed
func process(data: UserData) -> Result<Output, AppError>

// Bad - Any
func process(data: Any) -> Any

// Good - async/await
func fetchData() async throws -> Data

// Bad - completion handler
func fetchData(completion: @escaping (Result<Data, Error>) -> Void)
```

## Naming

- Files: `PascalCase.swift` (matches type name)
- Types/Protocols: `PascalCase`
- Functions/variables: `camelCase`
- Constants: `camelCase` (Swift convention, not UPPER_SNAKE)

## Structure

- One primary type per file
- Extensions in same file or `TypeName+Extension.swift`
- Group by feature, not by type

## App Directory

All Swift source code lives in `app/[AppName]/`:
- Views, ViewModels, Models, Services are under `app/[AppName]/[AppName]/`
- Tests are under `app/[AppName]/[AppName]Tests/`
- The Xcode project file is `app/[AppName].xcodeproj`

## ViewModels

- Use `@Observable` macro (macOS 14+)
- State enum for view states (idle, loading, success, error)
- No Combine publishers

## No Hardcoded Secrets — Anywhere

No hardcoded passwords, tokens, API keys, or secrets in ANY code — production or test. This is enforced by SAST scanning (Aikido MCP) and violations block merge.

```swift
// BAD — hardcoded password (even in tests)
sut.password = "Test123!"
let password = "mySecretPassword"

// BAD — hardcoded token
let token = "sk-live-abc123def456"

// GOOD — production: load from Keychain
let password = try KeychainHelper.get("user_password")

// GOOD — tests: use TestPasswordFactory / TestFixtures
sut.password = TestPasswordFactory.validPassword()
sut.password = TestPasswordFactory.weakPassword()
let token = TestFixtures.validToken()
```

**Test credentials pattern:** Use `TestPasswordFactory` for passwords/credentials, `TestFixtures` for other test data. Check if these helpers already exist before creating new ones. Never inline credential strings. See `testing-requirements.md` for the full pattern.

## Comments

- Brief comments for complex logic
- No commented-out code
- No TODO without task reference
