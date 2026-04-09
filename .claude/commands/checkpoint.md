---
description: Complete validation gate. Runs all tests, checks coverage, records QA sign-off. Delegates to QA agent.
---

# /checkpoint

Full validation gate with QA sign-off.

## Delegation

**IMMEDIATELY delegate to QA agent.**

## Flow

1. **Pre-flight**:
   - Check for uncommitted changes
   - Use `TaskList` to check for in-progress tasks

2. **Test Suite**:
   - Run ALL unit tests
   - Run ALL integration tests
   - Run E2E for critical paths

3. **Coverage Check**:
   - Business rules coverage report
   - If coverage dropped → WARN
   - If critical rules uncovered → BLOCK

4. **Auto-triggered Reviews**:
   - If API/auth/RLS changed → Security review
   - If components changed → Design review

5. **Task State Verification**:
   - Use `TaskList` to find tasks with `review_result == "rejected"`:
     - Check `review_stage` to identify which stage rejected (code-review, qa, security, product-review)
   - If any rejected tasks exist → WARN
   - Create bug tasks for test failures using `TaskCreate`
   - Update blocking tasks with `TaskUpdate`

6. **Gate Result**:
   - PASS → Record sign-off, "Run /commit"
   - FAIL → "Blocked: [reasons]"

## Output Format

### Pass
```
Checkpoint

Tests:
  Unit: 67/67 passed
  Integration: 23/23 passed
  E2E: 12/12 passed

Coverage:
  Business Rules: 18/20 (90%)
  Uncovered: BR-EDGE-003, BR-EDGE-004 (non-critical)

Auto-Reviews:
  Security: No issues (API changes reviewed)
  Design: Compliant (component changes reviewed)

Task State:
  In Progress: 2
  Awaiting Review: 3
  Rejected: 0

Checkpoint PASSED

QA Sign-off recorded: 2024-01-15T14:30:00Z

Run `/commit` to save changes.
```

### Fail
```
Checkpoint FAILED

Blockers:
- 2 tests failing (bugs created)
- Critical rule BR-SYNC-001 uncovered
- Security issue found: task-sec-1
- 1 task rejected and unresolved

Cannot proceed until blockers resolved.

Fix issues and run `/checkpoint` again.
```

## Task Tool Usage

```typescript
// Check for in-progress tasks
TaskList({ status: "in_progress" })

// Find rejected tasks (check metadata.review_result field)
TaskList()
// Then filter for tasks with review_result == "rejected"
// Check review_stage to see which stage rejected (code-review, qa, security, product-review)

// Create bug task for test failure
TaskCreate({
  subject: "Bug: [test failure description]",
  description: "Test failure details...",
  metadata: {
    type: "bug",
    priority: 1,
    approval: "pending",
    blocked: false,
    labels: []
  }
})

// Update task with blocking relationship
TaskUpdate({
  task_id: "bug-task-id",
  metadata: {
    blocks: ["task-id"]
  }
})
```

## Coverage Thresholds

- **Critical business rules**: 100% required
- **Other code**: 80% required
