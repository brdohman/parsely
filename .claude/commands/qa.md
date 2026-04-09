---
description: QA agent tests Stories/Epics that passed code review. Tests ALL acceptance_criteria from Story (Given/When/Then) AND local_checks from Tasks together. Pass or reject.
argument-hint: [story-id|epic-id] (optional - test specific Story/Epic, or omit to see queue)
---

# /qa

QA agent tests functionality against acceptance criteria (Stories/Epics) and local checks (Tasks) at the Story or Epic level.

> For workflow state fields and comment format: see `.claude/docs/WORKFLOW-STATE.md`

## Scope

- **Story Testing:** Test ALL `acceptance_criteria` from the Story AND ALL `local_checks` from child Tasks together
- **Epic Testing:** Run full integration testing across ALL Stories, verify feature works end-to-end

## Schema Distinction (v2.0)

| Type | Field | Format |
|------|-------|--------|
| **Story/Epic** | `acceptance_criteria` | Given/When/Then/Verify objects |
| **Task** | `local_checks` | Simple string array |

## Arguments

- `[id]` (optional) — If provided: test that Story/Epic. If omitted: show QA queue.

## Focus Areas

- [ ] All Story-level `acceptance_criteria` met (Given/When/Then/Verify format)
- [ ] All Task-level `local_checks` met (simple string checks)
- [ ] Components integrate correctly
- [ ] Edge cases handled across all tasks
- [ ] Error states work correctly
- [ ] No regressions introduced
- [ ] Performance acceptable
- [ ] UI/UX matches requirements (if applicable)

## Test Commands

### Xcode MCP (Preferred When Xcode Open)

```
# Discover available tests
mcp__xcode__GetTestList(tabIdentifier: "...")

# Run all tests (structured JSON results)
mcp__xcode__RunAllTests(tabIdentifier: "...")

# Run story-specific tests
mcp__xcode__RunSomeTests(tabIdentifier: "...", tests: ["AppNameTests/TestClassName"])
```

### Visual QA (MCP-Only, UI Stories)

For stories involving UI changes, capture SwiftUI preview screenshots:
```
mcp__xcode__RenderPreview(tabIdentifier: "...", file: "app/AppName/AppName/Views/SomeView.swift")
```
Verify layout, view states, and accessibility. Include evidence in QA comments.

### Shell Fallback

```bash
# Run all tests
xcodebuild test -scheme YourScheme -destination 'platform=macOS' -resultBundlePath TestResults.xcresult

# Run specific test class
xcodebuild test -scheme YourScheme -destination 'platform=macOS' -only-testing:YourTests/TestClassName

# Generate coverage report
xcrun xccov view --report TestResults.xcresult
```

### UX Flows Test Oracle

When the epic/story references a UX Flows document (`planning/notes/[epic-name]/ux-flows.md`), use it as the authoritative test oracle:

**State Machine-Driven Testing:**
- For each screen's state machine table (SM-*) in UX Flows, generate a test per transition. Use Peekaboo to screenshot each state after triggering the event. Verify guard conditions prevent invalid transitions.

**Journey-Level Testing:**
- Walk each Gherkin journey (J1, J2...) end-to-end via Peekaboo (`app launch`, `click`, `type`, `hotkey`, `see` to verify state). Screenshot at each Given/When/Then step.

**Error Catalog Verification:**
- For each entry in the error catalog, trigger the error condition and verify the user message matches and recovery action works.

**Coverage Metrics:**
- In QA comment, include: "State transitions tested: X/Y, Journeys walked: X/Y, Error scenarios: X/Y"

**Screenshot Evidence (Peekaboo):**
- Attach Peekaboo screenshots for visual acceptance criteria. Use `image --app [name] --mode window` for consistent captures.
- If Peekaboo unavailable, skip visual checks and note "Peekaboo unavailable — visual verification deferred to Human UAT" in QA comment.

## Flow

### If no id provided

```
TaskList -> filter: metadata.type in ["story","epic"]
                    metadata.review_stage == "qa"
                    metadata.review_result == "awaiting"
```

Display queue and prompt to run `/qa [id]`.

### If id provided

1. `TaskGet [id]` — get Story/Epic details
2. **Gather criteria:**
   - Story `acceptance_criteria` (Given/When/Then/Verify)
   - All child Task `local_checks` via `TaskList -> filter metadata.parent = [id]`
3. Read "CODE REVIEW PASSED" comment for context
4. Execute test suite:
   - **Story QA:** Run `.claude/scripts/test-scope.sh` with changed files from task implementation comments → use `RunSomeTests` or `-only-testing:` with the output classes
   - **Epic QA:** Always `RunAllTests` (full suite)
   - Verify all criteria, check integration and edge cases
5. Decide: PASS or FAIL

### PASS

Determine next stage based on item type:

```
TaskGet [id]   # read before write — check metadata.type

IF metadata.type == "epic":
  next_stage = "security"
  handoff_target = "Security Audit"
ELSE:  # story, bug, techdebt
  next_stage = "product-review"
  handoff_target = "Product Review"

TaskUpdate [id]
  metadata.review_stage: next_stage
  metadata.review_result: "awaiting"
  metadata.last_updated_at: "[ISO8601]"
  metadata.comments: [...existing, {
    "id": "C[N]", "timestamp": "[ISO8601]", "author": "qa-agent", "type": "review",
    "content": "QA PASSED\n\n**Story AC (Given/When/Then):**\n- [x] AC1: ...\n\n**Task local_checks:**\n- [x] [check]: [how verified]\n\n**Integration:** [x] Components work together\n\n**Tests:** XCTest [X/X] passed, Coverage [Z]%\n\nRouting to [handoff_target]."
  }]
```

Output:
```
QA PASSED for [id] "[Title]"
Tasks tested: N | Story AC verified: N | Task local_checks verified: N
Moved to [handoff_target] queue.
```

### FAIL

```
TaskGet [id]   # read before write

TaskUpdate [id]
  metadata.review_stage: "qa"
  metadata.review_result: "rejected"
  metadata.last_updated_at: "[ISO8601]"
  metadata.comments: [...existing, {
    "id": "C[N]", "timestamp": "[ISO8601]", "author": "qa-agent", "type": "rejection",
    "content": "REJECTED - QA\n\n**Issues found:**\n1. [Issue title]\n   - Task: [task-id]\n   - Expected: [...] Actual: [...]\n   - Severity: Blocker|Major|Minor\n\n**Failed AC:** [ ] AC[X]: ...\n**Failed local_checks:** [task-id] [check]: [why]\n\n**Next action:** macOS Developer Agent to fix and resubmit.",
    "resolved": false, "resolved_by": null, "resolved_at": null
  }]
```

Output:
```
QA FAILED for [id] "[Title]"
Returned to Dev (review_stage: qa, review_result: rejected)
Issues: [list]
Next: macOS Developer Agent will fix via /fix
```
