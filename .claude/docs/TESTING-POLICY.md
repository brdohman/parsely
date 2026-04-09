# Testing Policy

Canonical testing reference for all agents. Individual agents should reference this document rather than duplicating testing rules.

**Related:** `.claude/rules/global/testing-requirements.md` (auto-loaded rule with patterns and code examples).

---

## Test Execution Model

Tests run at specific points in the workflow — not everywhere.

| Who | When | What Runs |
|-----|------|-----------|
| **macOS Developer** | Task implementation | `xcodebuild build` only. No tests. |
| **Build Engineer** | `/commit` | `swiftlint` + `xcodebuild build`. No tests. |
| **QA Agent** | Story-level review | Targeted tests for changed files via `test-scope.sh`. |
| **QA Agent** | Epic-level review | Full test suite. |
| **Any** | `/checkpoint`, `/pr` | Full test suite. |

---

## Coverage Thresholds

| Code Type | Threshold | Enforcement |
|-----------|-----------|-------------|
| ViewModels | 100% of public behavior | Blocks merge |
| Services | 80% | Blocks merge |
| General code | 80% | Warning |

"100% of public behavior" = every public method's observable outcomes are tested. NOT every code path or default value.

---

## What to Test

1. **ViewModels** — All public methods that produce observable state changes
2. **Services** — API calls (mocked), data transformations, error paths
3. **Database operations** — CRUD, migrations, cascade deletes
4. **Business logic** — Calculations, validations, rules

---

## What NOT to Test

- Compiler-generated conformances (`Equatable`, `Hashable`, `Codable`, `CaseIterable`, `Identifiable`)
- Constant values (`XCTAssertEqual(Config.maxRetries, 3)` catches zero bugs)
- Trivial default values (consolidate into one `testInitialState`)
- Language semantics (`+= 1` increments an Int)
- Mock interaction counts (unless the count IS the behavior)

---

## Deduplication Principle

**A behavior should be tested at exactly one layer.**

- If a ViewModel test exercises a service through a real backend → that service path is covered
- If conformance tests verify CRUD → separate `DatabaseService*Tests` must NOT re-test the same operations
- Integration tests verify wiring/lifecycle, not business logic already covered by unit tests

---

## Test Credentials

Never hardcode passwords, tokens, or secrets — even in tests. SAST tools (Aikido) flag these as real findings.

Use `TestPasswordFactory` for credentials, `TestFixtures` for other test data. See `testing-requirements.md` for patterns and code examples.

---

## Pre-Existing Test Failures

⛔ **Every test failure MUST have a tracking item. No exceptions.**

When any agent encounters a test failure that is NOT caused by the current work:

1. **Immediately create a Bug or TechDebt task** via `TaskCreate`:
   - Title: `Bug: Pre-existing test failure — [TestClass/testMethod]`
   - Description: test name, error message, stack trace, and note: "Pre-existing — not introduced by [epic-id/story-id]"
   - Priority: P2 (or P1 if the failure is in critical business logic)
   - `approval: "pending"` (human reviews and prioritizes later)
2. **Log the filed task ID** in the current QA/review comment
3. **Continue with the review** — the filed task does not block current work

**Never** dismiss a failure with "pre-existing, not caused by this epic" without creating a task. Untracked failures accumulate silently and become normalized. The task exists so the failure has accountability and visibility.

This applies at ALL test execution points: story-level QA, epic-level QA, `/checkpoint`, `/complete-epic`, and `/test`.

---

## QA-Specific: When NOT to Reject for Missing Tests

QA should NOT reject a story for missing tests when:
- The behavior is compiler-generated
- Default values are trivially correct
- The behavior is already covered at another layer
- The story was rejected for style/architecture issues (not bugs)

QA SHOULD still require tests for:
- Every public behavior that could regress
- Edge cases with real bug potential
- Bug fixes (regression tests)

---

## Parameterized Tests

When 3+ tests follow the same pattern with different inputs, use a loop over `(input, expected)` tuples instead of N separate test methods. See `testing-requirements.md` for examples.
