---
description: Staff Engineer reviews code for Stories/Epics awaiting code review. Reviews ALL code from child tasks together. Pass or reject with structured feedback.
argument-hint: [story-id|epic-id] (optional - review specific Story/Epic, or omit to see queue)
---

# /code-review

Staff Engineer agent reviews code quality, architecture, and standards at the Story or Epic level.

**Schema Version:** 2.0

## Scope

- **Story Review:** Review ALL code from ALL child Tasks together as a cohesive unit
- **Epic Review:** Review architecture and patterns across ALL Stories for consistency

## Understanding the Hierarchy

Stories and Tasks have different metadata structures in v2.0:

| Item Type | Acceptance Field | What to Verify |
|-----------|------------------|----------------|
| **Story** | `acceptance_criteria` (Given/When/Then/Verify format) | Business-level requirements achievable with implementation |
| **Task** | `local_checks` (string array) | Task-specific technical requirements met |

**Important Distinctions:**
- **Story AC** = "What business behavior must the user experience?" (Given/When/Then/Verify)
- **Task local_checks** = "What technical conditions must be true for this code to be correct?"
- **Tasks do NOT have `definition_of_done`** - this is a repo-level quality gate, not per-task
- **Tasks use `checklist`** (was `subtasks` in v1.0) for granular implementation steps
- **Tasks use `validation_hint`** and `completion_signal` for verification

## Arguments

- `[id]` (optional) - Specific Story or Epic to review
  - If provided: Review that Story/Epic
  - If omitted: Show queue of Stories/Epics needing code review

## Focus Areas

When reviewing, check for:

### Architecture & Patterns
- [ ] MVVM architecture properly implemented across all components
- [ ] ViewModels use @Observable macro (not ObservableObject)
- [ ] Views are passive and delegate logic to ViewModels
- [ ] Clear separation between View, ViewModel, and Model layers
- [ ] Consistent patterns across all tasks in the Story/Epic

### Swift Concurrency
- [ ] async/await used for asynchronous code (not Combine)
- [ ] @MainActor applied appropriately for UI updates
- [ ] Task cancellation handled correctly
- [ ] No data races or concurrency warnings

### Core Data
- [ ] Managed object contexts used on correct threads
- [ ] Fetch requests are efficient (predicates, batch sizes)
- [ ] Relationships and cascading deletes configured properly
- [ ] Background contexts used for heavy operations

### Code Quality
- [ ] SwiftLint rules pass with no violations
- [ ] No force unwraps (!) unless explicitly justified
- [ ] Error handling uses Swift's Result or throwing functions
- [ ] Code is readable and maintainable

### Security & Performance
- [ ] Sensitive data handled securely (Keychain, not UserDefaults)
- [ ] No memory leaks (retain cycles, missing [weak self])
- [ ] Efficient use of resources (lazy loading, caching)

### Story/Epic Level
- [ ] All tasks integrate correctly together
- [ ] No duplicate code across tasks
- [ ] Shared components properly abstracted
- [ ] Story `acceptance_criteria` (Given/When/Then/Verify) achievable with this code
- [ ] Each Task's `local_checks` are satisfied by the implementation
- [ ] Task `checklist` items are all completed
- [ ] Task `validation_hint` and `completion_signal` criteria met

### UX Flows Compliance

If the epic/story references a UX Flows document (`planning/notes/[epic-name]/ux-flows.md`), verify:
- [ ] ViewModel states match state machine table entries (all states defined in SM-* have corresponding enum cases)
- [ ] All transitions in state machine table are handled (events trigger correct state changes)
- [ ] Guard conditions implemented as documented
- [ ] Interaction specs (IS-*) implemented as specified (keyboard shortcuts, drag-drop, hover states)
- [ ] macOS platform conventions checklist from UX Flows Section 7 satisfied
- [ ] Modal/sheet flows match Section 5 specifications (trigger, type, size, fields, confirm/cancel)

If no UX Flows doc referenced by epic/story: skip this section, note "No UX Flows reference — compliance check skipped" in review comment.

## Flow

### If no id provided:

Use `TaskList` to find Stories/Epics awaiting code review:

```
TaskList -> filter where:
  - metadata.type is "story" OR metadata.type is "epic"
  - metadata.review_stage == "code-review" AND metadata.review_result == "awaiting"
```

Display:
```
Code Review Queue (3 items):

1. [story-abc] Phase 1: Core Data Model Setup
   Type: story | Priority: P1 | Tasks: 5/5 complete | Submitted: 2024-01-15

2. [story-def] Phase 2: API Integration
   Type: story | Priority: P1 | Tasks: 3/3 complete | Submitted: 2024-01-15

3. [epic-ghi] User Authentication Feature
   Type: epic | Priority: P0 | Stories: 3/3 complete | Submitted: 2024-01-14

Run /code-review [id] to review a specific Story or Epic.
```

### If id provided:

1. **Get Story/Epic details**
   ```
   TaskGet [id]
   ```

2. **Identify all child items**
   - For Story: Find all Tasks with `metadata.parent = [story-id]`
   - For Epic: Find all Stories with `metadata.parent = [epic-id]`, then all their Tasks

3. **Spawn BOTH review agents in parallel (same message)**

   The coordinator spawns both agents concurrently. Both run in FOREGROUND and return directly.

   **Agent 1: Staff Engineer** (code review + Aikido scan):
   ```
   subagent_type: "staff-engineer"
   model: "sonnet", mode: "bypassPermissions"
   prompt: "CODE REVIEW [id]
     1. TaskGet [id] — read story/epic details
     2. TaskList — find all child tasks, read implementation comments
     3. Read ALL changed .swift files and review against checklist:
        MVVM, @Observable, async/await, no Combine, no force unwraps, error handling,
        performance, accessibility, architectural boundaries
        For test files: verify proper assertions, mock patterns, teardown, edge case coverage
     4. Run Aikido scan: collect all changed .swift files, run aikido_full_scan MCP.
        CRITICAL/HIGH findings are blockers. MEDIUM/LOW are noted.
        If Aikido MCP unavailable, note 'Aikido scan skipped — MCP unavailable'.
        ⛔ SAVE OUTPUT: echo '<full aikido output>' | .claude/scripts/save-review.sh aikido
     5. Do NOT run any tests — only read and review the code
     6. Decision:
        If PASS: TaskUpdate — set review_stage: 'qa', review_result: 'awaiting',
          append CODE REVIEW PASSED comment (include Aikido results + 'CodeRabbit: reviewed by parallel agent')
        If FAIL: TaskUpdate — set review_result: 'rejected',
          append rejection comment with specific issues per file
     ⛔ VERIFY WRITE: After TaskUpdate, call TaskGet to confirm fields persisted. Retry up to 3x.
     Return only: PASS or FAIL"
   ```

   **Agent 2: CodeRabbit** (AI-powered review):
   ```
   subagent_type: "coderabbit:code-reviewer"
   model: "sonnet", mode: "bypassPermissions"
   prompt: "CODERABBIT REVIEW for [id]
     Review ALL code changes on the current branch vs main.
     Focus on: security issues, logic errors, concurrency bugs, architecture problems.
     ⛔ SAVE OUTPUT: echo '<full coderabbit output>' | .claude/scripts/save-review.sh coderabbit
     After review, add a comment to the task [id] with your findings:
       TaskGet [id] first, then TaskUpdate with appended comment:
       {type: 'review', author: 'coderabbit-agent', content: 'CODERABBIT REVIEW\n\n[findings summary]\n\nCritical: [N]\nHigh: [N]\nMedium: [N]\nLow: [N]'}
     Return only: CLEAN, or FINDINGS ([N] critical, [N] high)"
   ```

   → Both agents return directly. No polling.
   → If staff-engineer says FAIL → story/epic is rejected (staff-engineer already updated state).
   → If CodeRabbit reports ANY findings (not just critical):
     Apply the **CodeRabbit Findings Triage Protocol** (`.claude/rules/global/coderabbit-triage.md`):
     1. Triage all findings — assign recommendation (FIX, TECHDEBT, VERIFIED FIXED, RESEARCHED)
     2. For uncertain findings — spawn research agent to verify
     3. For outside-diff findings — verify if fixed, or create TechDebt task
     4. Present batch table to user with all findings + recommendations + effort estimates
     5. User decides: fix all, pick specific ones, or fix everything
     6. Execute user's decision before advancing
   → If staff-engineer PASS and user approves CodeRabbit triage → verify review artifacts → advance to QA.

4. **Verify review artifacts before advancing to QA**
   ```bash
   .claude/scripts/verify-review-artifacts.sh --level story
   ```
   If INCOMPLETE → report what's missing and stop. The review-gate hook also enforces this on the TaskUpdate call itself.

5. **Final decision: PASS or FAIL**

### PASS - Code Review Approved

Update Story/Epic metadata:
- Set `review_stage` to `"qa"` (next stage)
- Keep `review_result` as `"awaiting"`
- Add review comment to metadata.comments

```
TaskUpdate [id]
  metadata.schema_version: "2.0"
  metadata.last_updated_at: "[ISO 8601 timestamp]"
  metadata.review_stage: "qa"
  metadata.review_result: "awaiting"
  metadata.comments: [...existing comments, {
    "id": "[uuid]",
    "timestamp": "[ISO 8601 timestamp]",
    "author": "staff-engineer-agent",
    "type": "code-review-passed",
    "content": "CODE REVIEW PASSED\n\n**Scope reviewed:** [Story/Epic] with [N] tasks\n\n**Tasks reviewed:**\n- [task-1]: [brief description]\n- [task-2]: [brief description]\n- [task-N]: [brief description]\n\n**What was checked:**\n- [x] MVVM architecture followed across all components\n- [x] @Observable used correctly\n- [x] async/await patterns (no Combine)\n- [x] Core Data best practices\n- [x] SwiftLint compliance\n- [x] No memory leaks or retain cycles\n- [x] Error handling adequate\n- [x] Components integrate correctly\n- [x] No code duplication across tasks\n- [x] Story acceptance_criteria achievable\n- [x] Task local_checks verified\n- [x] Task checklist items completed\n- [x] Aikido scan: [clean / N findings (details)]\n- [x] CodeRabbit review: [clean / N findings (details)]\n\n**Notes:**\n[Any observations or suggestions for future]",
  }]
```

Output:
```
Code review PASSED for [story-abc] "Phase 1: Core Data Model Setup"
Tasks reviewed: 5
Moved to QA queue (review_stage: qa, review_result: awaiting)

Next: QA Agent will test all acceptance criteria across the Story.
```

### FAIL - Code Review Rejected

Update Story/Epic metadata:
- Set `review_result` to `"rejected"` (review_stage stays `"code-review"`)
- Add rejection comment to metadata.comments

```
TaskUpdate [id]
  metadata.schema_version: "2.0"
  metadata.last_updated_at: "[ISO 8601 timestamp]"
  metadata.review_stage: "code-review"
  metadata.review_result: "rejected"
  metadata.comments: [...existing comments, {
    "id": "[uuid]",
    "timestamp": "[ISO 8601 timestamp]",
    "author": "staff-engineer-agent",
    "type": "code-review-rejected",
    "content": "REJECTED - CODE REVIEW\n\n**Scope reviewed:** [Story/Epic] with [N] tasks\n\n**Issues found:**\n\n1. **[Issue title]**\n   - Task: [task-id]\n   - File: [app/AppName/AppName/ViewModels/SomeViewModel.swift]\n   - Description: [What's wrong]\n   - Expected: [What should happen]\n   - Actual: [What's in the code]\n   - Severity: [Blocker | Major | Minor]\n\n2. **[Issue title]**\n   - Task: [task-id]\n   - File: [app/AppName/AppName/Views/SomeView.swift]\n   - Description: [What's wrong]\n   - Expected: [What should happen]\n   - Actual: [What's in the code]\n   - Severity: [Blocker | Major | Minor]\n\n**Cross-task issues:**\n- [Any architectural inconsistencies or integration problems]\n\n**Story acceptance_criteria at risk:**\n- [ ] Criteria X: [Why it might fail with Given/When/Then context]\n\n**Task local_checks not satisfied:**\n- [task-abc]: [Which local_check failed]\n- [task-def]: [Which local_check failed]\n\n**Aikido scan findings:**\n- [findings or 'clean']\n\n**CodeRabbit review findings:**\n- [findings or 'clean']\n\n**Tasks requiring fixes:**\n- [task-abc]: [Brief description of needed fix]\n- [task-def]: [Brief description of needed fix]\n\n**Next action:** macOS Developer Agent to fix issues in affected tasks and resubmit Story for code review.",
  }]
```

Output:
```
Code review FAILED for [story-abc] "Phase 1: Core Data Model Setup"
Returned to Dev (review_stage: code-review, review_result: rejected)

Issues found:
1. [Blocker] task-123: ViewModel using ObservableObject instead of @Observable
2. [Major] task-124: Combine publishers used instead of async/await
3. [Minor] task-125: SwiftLint warning: force_cast violation

Cross-task issues:
- Inconsistent error handling patterns between task-123 and task-124
- Duplicate model validation code in task-123 and task-125

Next: macOS Developer Agent will fix affected tasks and resubmit Story via /fix
```

## Common Swift Review Issues

### MVVM Violations
- View contains business logic
- ViewModel directly imports SwiftUI (should only import Foundation/Observation)
- Model layer has UI dependencies

### @Observable Issues
- Using ObservableObject/@Published instead of @Observable
- Missing @MainActor on ViewModels with UI state
- Not using @Bindable in Views for two-way binding

### Concurrency Issues
- Using Combine instead of async/await
- Missing Task cancellation in onDisappear
- Blocking main thread with synchronous calls

### Core Data Issues
- Accessing managed objects on wrong thread
- Missing @FetchRequest or @Query macros
- N+1 query patterns

### Cross-Task Issues (Story/Epic Level)
- Inconsistent patterns between tasks
- Duplicate code that should be shared
- Missing abstractions for common functionality
- Integration points not properly designed

### v2.0 Schema Issues (Review the Metadata)
- Task using `acceptance_criteria` instead of `local_checks`
- Task using `subtasks` instead of `checklist`
- Task using `verify` instead of `validation_hint`
- Task still has `definition_of_done` (should be removed - repo-level gate)
- Missing `completion_signal` on tasks
- Missing `schema_version: "2.0"` on any items

## Task Tool Reference

```
# Find Stories/Epics needing code review
TaskList -> filter:
  - metadata.type in ["story", "epic"]
  - metadata.review_stage == "code-review" AND metadata.review_result == "awaiting"

# Get Story/Epic details with comments
TaskGet [id]

# Find child tasks of a Story
TaskList -> filter metadata.parent = [story-id]

# Find child Stories of an Epic
TaskList -> filter metadata.parent = [epic-id] AND metadata.type = "story"

# PASS - move to QA
TaskUpdate [id]
  - Set metadata.review_stage to "qa"
  - Set metadata.review_result to "awaiting"
  - Add comment to metadata.comments

# FAIL - return to dev
TaskUpdate [id]
  - Keep metadata.review_stage as "code-review"
  - Set metadata.review_result to "rejected"
  - Add comment to metadata.comments
```
