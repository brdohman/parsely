---
name: submit-for-review
description: "Pre-submission validation for stories before code review. Verifies all child tasks complete, tests pass, build succeeds. Required before setting review_stage to code-review."
disable-model-invocation: true
allowed-tools: [TaskGet, TaskList, TaskUpdate, Bash]
---

# Submission Validation Rule

## When This Applies

Before setting `review_stage: "code-review"` on a Story. This gate ensures all work is complete, tested, and verified before entering the review cycle.

**Schema Version:** 2.0

---

## Pre-Submission Checklist

**ALL items must be checked before submission. No exceptions.**

### a. All Tasks Completed

- [ ] Every child Task has `status: completed`
- [ ] Every child Task has a completion comment documenting what was done
- [ ] Every child Task has all `local_checks` verified (v2.0 field name)
- [ ] Every child Task has `completion_signal` met
- [ ] Every child Task has a test documentation comment listing tests added

**Verification:**
```
TaskList → filter where parent = [story-id]
All tasks must show status: completed
Each task's local_checks should be verified in completion comment
```

### b. Tests Written and Documented

- [ ] Test files exist for all new ViewModels, Services, and business logic
- [ ] Test documentation comment added to each Task (format below)
- [ ] All tests pass locally

**Test Documentation Comment Format:**
```json
{
  "id": "T1",
  "timestamp": "2026-01-30T10:00:00Z",
  "author": "macos-developer-agent",
  "type": "testing",
  "content": "Tests added: [TestClassName]. Test methods: testX, testY, testZ. Coverage: [files covered]. All tests passing. Local checks verified: [list from task.local_checks]."
}
```

### c. Build Succeeds

- [ ] `xcodebuild build` passes with zero errors
- [ ] No compiler warnings (treat warnings as errors)

### d. Lint Passes

- [ ] `swiftlint` returns no errors
- [ ] No unresolved SwiftLint warnings

### e. Story Acceptance Criteria Addressed

- [ ] Each `acceptance_criteria` from the Story has corresponding implementation
- [ ] Each AC has at least one test verifying it
- [ ] Tests cover all edge cases mentioned in AC

**Note:** Stories use `acceptance_criteria` (Given/When/Then/Verify format). Tasks use `local_checks` (simple string array). Do not confuse these fields.

---

## Automated Checks

Run these commands and verify ALL pass before submission:

```bash
# 1. Build verification
xcodebuild build -scheme [AppName] -destination 'platform=macOS'

# 2. Lint verification
swiftlint

# 3. Test verification
xcodebuild test -scheme [AppName] -destination 'platform=macOS'
```

**Expected Results:**
- Build: `** BUILD SUCCEEDED **`
- Lint: No errors (warnings acceptable if justified)
- Tests: `** TEST SUCCEEDED **` with all tests passing

---

## Submission Comment Requirements

When setting `review_stage: "code-review"` and `review_result: "awaiting"` on a Story, include a structured submission comment:

```json
{
  "id": "SUB1",
  "timestamp": "2026-01-30T12:00:00Z",
  "author": "macos-developer-agent",
  "type": "submission",
  "content": "READY FOR CODE REVIEW. Summary: [brief description of work completed]. Tasks completed: T1 (Create ViewModel): completed, T2 (Create View): completed, T3 (Add tests): completed. Files modified: [list key files]. Tests added: [list test classes]. Test results: X tests, all passing. Build: SUCCESS. Lint: PASS (0 errors). Coverage: [percentage if available]. All task local_checks verified. All story acceptance_criteria addressed."
}
```

### Required Sections in Submission Comment:

1. **Summary** - Brief description of the work completed
2. **Tasks completed** - List each child Task with ID and status
3. **Files modified** - Key files that were added or changed
4. **Tests added** - List of test classes/methods added
5. **Test results** - Number of tests, pass/fail status
6. **Build status** - SUCCESS or details of any issues
7. **Lint status** - PASS or number of errors/warnings
8. **Coverage** - Percentage if available, or "N/A" if not measured
9. **Local checks** - Confirmation that all task `local_checks` are verified
10. **Story AC** - Confirmation that story `acceptance_criteria` are addressed

---

## Validation Workflow

```
1. TaskList to get all child Tasks
   |
2. Verify ALL Tasks are status: completed
   |
3. Verify ALL Tasks have completion + test comments
   |
4. Verify ALL task local_checks documented as verified
   |
5. Run: xcodebuild build
   |
6. Run: swiftlint
   |
7. Run: xcodebuild test
   |
8. Verify repo-level quality gates pass (see CLAUDE.md#quality-gates)
   |
9. ALL PASS?
   |
   YES → Add submission comment + set review_stage:"code-review", review_result:"awaiting"
   NO  → Fix issues, do NOT submit
```

**Note:** Definition of Done is now a repo-level quality gate, not a per-task field. Refer to `CLAUDE.md#quality-gates` or CI configuration for quality requirements.

---

## If ANY Check Fails

**DO NOT SUBMIT.** Instead:

1. Identify the failing check
2. Fix the underlying issue
3. Re-run all automated checks
4. Only proceed when ALL checks pass

**Partial submissions are never acceptable.** A Story with incomplete Tasks, failing tests, or build errors will be immediately rejected in code review, wasting reviewer time.

---

## Anti-Patterns (DO NOT)

| Anti-Pattern | Why It's Wrong | Do Instead |
|--------------|----------------|------------|
| Submit before all Tasks complete | Incomplete work cannot be reviewed | Wait for all Tasks to reach completed status |
| Submit without test documentation | Reviewer cannot verify test coverage | Add test documentation comment to each Task |
| Submit with failing tests | Broken code wastes reviewer time | Fix all tests before submission |
| Submit without build verification | May not compile for reviewer | Always run full build before submission |
| Submit with lint errors | Code quality issues will be rejected | Run swiftlint and fix all errors |
| Skip the submission comment | Reviewer lacks context | Always include full submission comment |
| Submit with "will fix later" items | Technical debt accumulates | Fix everything before submission |
| Submit one Task at a time | Fragments the review | Wait for complete Story |

---

## Reviewer Expectations

When a Story has `review_stage: "code-review"` and `review_result: "awaiting"`, the Staff Engineer expects:

1. **Complete work** - All child Tasks done
2. **Working build** - Code compiles without errors
3. **Passing tests** - All tests green
4. **Clean code** - No lint errors
5. **Documentation** - Clear comments on what was done
6. **Task local_checks verified** - Each task's `local_checks` documented as passing
7. **Story AC coverage** - Every story `acceptance_criteria` addressed
8. **Repo quality gates met** - CI/quality gates from CLAUDE.md#quality-gates pass

If ANY of these are missing, the Story will be immediately rejected with `review_result: "rejected"` (stage stays `"code-review"`), and the developer must fix and resubmit through the full cycle again.

---

## v2.0 Field Reference

### Task Fields (v2.0)

| Old Field Name (v1.0) | New Field Name (v2.0) | Notes |
|-----------------------|-----------------------|-------|
| `acceptance_criteria` | `local_checks` | Simple string array for tasks |
| `subtasks` | `checklist` | Granular steps within task |
| `verify` | `validation_hint` | Quick verification summary |
| `definition_of_done` | REMOVED | Now repo-level quality gate |

### New Task Fields (v2.0)

| Field | Purpose |
|-------|---------|
| `completion_signal` | When is this task done? |
| `validation_hint` | Quick verification summary |
| `ai_execution_hints` | Hints for AI agents (recommended) |

### Story vs Task Terminology

| Concept | Story Field | Task Field |
|---------|-------------|------------|
| Success criteria | `acceptance_criteria` (Given/When/Then/Verify) | `local_checks` (simple strings) |
| Completion checklist | `definition_of_done.completion_gates` | `checklist` |
| How to verify | `acceptance_criteria[].verify` | `validation_hint` |

---

## Quick Reference

Before setting `review_stage: "code-review"`:

```
[ ] All Tasks completed?
[ ] All Tasks have completion comments?
[ ] All Tasks have test documentation comments?
[ ] All task local_checks verified?
[ ] All task completion_signals met?
[ ] xcodebuild build passes?
[ ] swiftlint passes?
[ ] xcodebuild test passes?
[ ] Repo-level quality gates pass?
[ ] Story acceptance_criteria addressed?
[ ] Submission comment written?
```

**All checked? Proceed with submission.**
**Any unchecked? Stop and fix first.**

---

## Quality Gates Reference

Definition of Done is no longer a per-task field in v2.0. Quality gates are enforced at the repo level:

- **Location:** `CLAUDE.md#quality-gates` or CI configuration
- **Enforcement:** Automated via CI, not manual per-task tracking
- **Examples:** Lint passing, test coverage thresholds, accessibility checks

Tasks have `local_checks` (what must be true for this task) while quality gates apply to all submissions.
