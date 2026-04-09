# Workflow State Machine

This document defines the workflow state fields for all issue types in the production workflow using Claude Code Tasks.

**Compatible with:** Metadata Schema v2.0

**Note:** Workflow state is managed through 4 dedicated metadata fields (`approval`, `blocked`, `review_stage`, `review_result`) rather than overloading the `labels` array. Labels remain available for pure categorization tags (e.g., `"ui"`, `"performance"`, `"database"`). For task metadata field definitions, see `.claude/templates/tasks/metadata-schema.md`.

## Terminology

| Term | Definition |
|------|------------|
| **Claude Tasks** | The TaskCreate, TaskUpdate, TaskGet, TaskList tool system |
| **Epic** | Top-level initiative (`type: "epic"`) - subject: `Epic: [Name]` |
| **Story** | Phase or component (`type: "story"`) - subject: `Story: [Name]` |
| **Task** | Individual work item (`type: "task"`) - subject: `Task: [Name]` |

---

## Issue Types

| Type | Purpose | Goes Through Review Cycle? |
|------|---------|---------------------------|
| **Epic** | High-level initiative | Yes - After ALL Stories complete |
| **Story** | Group of tasks under epic | Yes - After ALL Tasks complete |
| **Task** | Individual work item | NO - Mark complete when done |
| **Bug** | Defect fix | Yes - Full cycle |
| **TechDebt** | Maintenance work | Yes - Full cycle |

**Key Insight:** Tasks are the atomic unit of work. They do NOT go through the review cycle individually. Instead, when all Tasks under a Story are complete, the STORY goes through review. When all Stories under an Epic are complete, the EPIC goes through review.

---

## Workflow State Fields

### approval (string) - All Types

| Value | Meaning | Applied To |
|-------|---------|------------|
| `"pending"` | Plan awaiting human approval | Epic, Story, Task, Bug, TechDebt |
| `"approved"` | Approved for implementation | Epic, Story, Task, Bug, TechDebt |

### blocked (boolean) - All Types

| Value | Meaning | Applied To |
|-------|---------|------------|
| `true` | Blocked by external factor | Any |
| `false` | Not blocked | Any |

### review_stage (string or null) - Story, Epic, Bug, TechDebt Only

| Value | Meaning | Applied To |
|-------|---------|------------|
| `"code-review"` | In code review stage | Story, Epic, Bug, TechDebt |
| `"qa"` | In QA testing stage | Story, Epic, Bug, TechDebt |
| `"security"` | In security audit stage (mandatory for Epics) | Story, Epic, Bug, TechDebt |
| `"product-review"` | In product review stage | Story, Epic, Bug, TechDebt |
| `null` | Not in review (pre-review or completed) | Story, Epic, Bug, TechDebt |

### review_result (string or null) - Story, Epic, Bug, TechDebt Only

| Value | Meaning | Applied To |
|-------|---------|------------|
| `"awaiting"` | Waiting for reviewer to act | Story, Epic, Bug, TechDebt |
| `"rejected"` | Reviewer found issues | Story, Epic, Bug, TechDebt |
| `null` | Not in review (pre-review or completed) | Story, Epic, Bug, TechDebt |

**Note:** Tasks do NOT have `review_stage` or `review_result` fields. Tasks only use `approval` and `blocked`.

---

## Workflow by Issue Type

### Task Completion (No Review)

Tasks are individual work items. They do **NOT** go through the review cycle.

```
+---------------------------------------------------------------------+
|                       TASK WORKFLOW                                  |
+---------------------------------------------------------------------+
|                                                                     |
|  1. Dev Agent picks up approved Task                                |
|     -> Status: in_progress                                          |
|     -> approval: "approved"                                         |
|                                                                     |
|  2. Dev Agent implements the work                                   |
|     -> Write code                                                   |
|     -> Write tests                                                  |
|     -> Verify locally                                               |
|                                                                     |
|  3. Dev Agent marks Task complete                                   |
|     -> Status: completed                                            |
|     -> approval: "approved" (keep it)                               |
|     -> Add completion comment with:                                 |
|        - What was implemented                                       |
|        - Files changed                                              |
|        - Tests written (location and what they cover)               |
|                                                                     |
|  4. Dev Agent checks parent Story                                   |
|     -> Are ALL sibling Tasks completed?                             |
|     -> If YES: Submit Story for code review                         |
|     -> If NO: Move to next Task                                     |
|                                                                     |
+---------------------------------------------------------------------+
```

**Fields on Task completion:** Keep `approval: "approved"` only. **NO `review_stage` or `review_result`** fields on Tasks.

**Task Completion Comment Template:**
```
TASK COMPLETED

**Completed by:** [Agent name]
**Date:** [ISO timestamp]

**What was implemented:**
- [Brief description of changes]

**Files changed:**
- [path/to/file1.swift]
- [path/to/file2.swift]

**Tests written:**
- [path/to/TestFile.swift]: [What the tests cover]

**Notes:**
[Any observations or caveats]
```

---

### Story Workflow (Review After All Tasks Complete)

Stories go through the full review cycle, but only AFTER all child Tasks are completed.

```
+---------------------------------------------------------------------+
|                       STORY WORKFLOW                                 |
+---------------------------------------------------------------------+
|                                                                     |
|  1. Story created as child of Epic during /plan                     |
|     -> Status: pending                                              |
|     -> approval: "pending"                                          |
|                                                                     |
|  2. When parent Epic approved via /approve-epic                     |
|     -> approval: "approved" set on Story                            |
|     -> Child Tasks also get approval: "approved"                    |
|                                                                     |
|  3. Dev Agent implements all child Tasks                            |
|     -> Each Task marked completed (no review fields)                |
|     -> Story status: in_progress                                    |
|                                                                     |
|  4. When ALL Tasks under Story are completed:                       |
|     -> Dev Agent sets review_stage: "code-review",                  |
|        review_result: "awaiting" on STORY                           |
|     -> Add READY FOR CODE REVIEW comment to STORY                   |
|                                                                     |
|  5. Story goes through review cycle:                                |
|     Code Review -> QA -> Product Review                             |
|     (See Review Cycle section below)                                |
|                                                                     |
|  6. When Story passes Product Review:                               |
|     -> Status: completed                                            |
|     -> review_stage: null, review_result: null                      |
|     -> Check if all sibling Stories are completed                   |
|     -> If YES: Submit Epic for code review                          |
|                                                                     |
+---------------------------------------------------------------------+
```

**Fields progression (happy path):**
```
approval: "pending"
    -> approval: "approved"
    -> review_stage: "code-review", review_result: "awaiting"
    -> review_stage: "qa", review_result: "awaiting"
    -> review_stage: "product-review", review_result: "awaiting"
    -> review_stage: null, review_result: null [COMPLETED]
```

---

### Epic Workflow (Review After All Stories Complete)

Epics go through plan approval first, then the full review cycle after all Stories complete.

```
+---------------------------------------------------------------------+
|                         EPIC WORKFLOW                                |
+---------------------------------------------------------------------+
|                                                                     |
|  PHASE 1: PLAN APPROVAL                                             |
|  -----------------------                                            |
|  1. Agent creates Epic via /epic or /feature                        |
|     -> approval: "pending"                                          |
|     -> Status: pending                                              |
|                                                                     |
|  2. Human reviews epic, runs /write-stories-and-tasks               |
|     -> Stories and tasks created with approval: "pending"           |
|                                                                     |
|  3. Human reviews stories/tasks, then runs /approve-epic [epic-id]  |
|     -> approval: "approved" set on Epic + all Stories + all Tasks   |
|                                                                     |
|  PHASE 2: IMPLEMENTATION                                            |
|  ------------------------                                           |
|  4. Dev Agent implements all Tasks under all Stories                |
|     -> Tasks marked completed (no review fields)                    |
|     -> Stories submitted for review when Tasks done                 |
|     -> Stories go through Code Review -> QA -> Product Review       |
|                                                                     |
|  PHASE 3: EPIC REVIEW                                               |
|  ---------------------                                              |
|  5. When ALL Stories under Epic are completed:                      |
|     -> Dev Agent sets review_stage: "code-review",                  |
|        review_result: "awaiting" on EPIC                            |
|     -> Add READY FOR EPIC REVIEW comment                            |
|                                                                     |
|  6. Epic goes through review cycle:                                 |
|     Code Review -> QA -> Security Audit -> Product Review           |
|     (Security Audit is mandatory for Epics, orchestrated by         |
|      /security-audit with 3 sub-agents)                             |
|                                                                     |
|  7. When Epic passes Product Review:                                |
|     -> Status: completed                                            |
|     -> review_stage: null, review_result: null                      |
|     -> Epic is DONE                                                 |
|                                                                     |
+---------------------------------------------------------------------+
```

**Fields progression (full lifecycle):**
```
approval: "pending"
    -> approval: "approved"
    -> review_stage: "code-review", review_result: "awaiting"
    -> review_stage: "qa", review_result: "awaiting"
    -> review_stage: "security", review_result: "awaiting"   [Epic mandatory]
    -> review_stage: "product-review", review_result: "awaiting"
    -> review_stage: null, review_result: null [COMPLETED]
```

---

### Bug / TechDebt Workflow

Bugs and TechDebt are standalone items that go through the full review cycle (same as previous behavior).

```
+---------------------------------------------------------------------+
|                     BUG / CHORE WORKFLOW                             |
+---------------------------------------------------------------------+
|                                                                     |
|  +---------------------------------------------------------------+  |
|  | 1. IMPLEMENTATION (Dev Agent)                                 |  |
|  |    Status: in_progress                                        |  |
|  |    approval: "approved"                                       |  |
|  |    Action: Implement the fix/maintenance                      |  |
|  |    Exit: Set review_stage: "code-review",                     |  |
|  |          review_result: "awaiting"                            |  |
|  |          Add comment with READY FOR CODE REVIEW template      |  |
|  +---------------------------------------------------------------+  |
|                              |                                      |
|                              v                                      |
|  +---------------------------------------------------------------+  |
|  | 2. CODE REVIEW (Staff Engineer Agent)                         |  |
|  |    review_stage: "code-review"                                |  |
|  |    review_result: "awaiting"                                  |  |
|  |    Focus: Architecture, patterns, standards, security         |  |
|  |                                                               |  |
|  |    PASS: Set review_stage: "qa",                              |  |
|  |          review_result: "awaiting"                            |  |
|  |          Add comment with CODE REVIEW PASSED template         |  |
|  |                                                               |  |
|  |    FAIL: Set review_result: "rejected"                        |  |
|  |          (review_stage stays "code-review")                   |  |
|  |          Add comment with REJECTION template                  |  |
|  |          -> Returns to step 1                                 |  |
|  +---------------------------------------------------------------+  |
|                              |                                      |
|                              v                                      |
|  +---------------------------------------------------------------+  |
|  | 3. QA TESTING (QA Agent)                                      |  |
|  |    review_stage: "qa"                                         |  |
|  |    review_result: "awaiting"                                  |  |
|  |    Focus: Acceptance criteria, edge cases, regression         |  |
|  |                                                               |  |
|  |    PASS (Epic): Set review_stage: "security",                 |  |
|  |          review_result: "awaiting"                            |  |
|  |          Add comment with QA PASSED template                  |  |
|  |          (routes to mandatory Security Audit)                 |  |
|  |    PASS (Story/Bug/TechDebt):                                 |  |
|  |          Set review_stage: "product-review",                  |  |
|  |          review_result: "awaiting"                            |  |
|  |          Add comment with QA PASSED template                  |  |
|  |                                                               |  |
|  |    FAIL: Set review_result: "rejected"                        |  |
|  |          (review_stage stays "qa")                            |  |
|  |          Add comment with REJECTION template                  |  |
|  |          -> Returns to step 1                                 |  |
|  +---------------------------------------------------------------+  |
|                              |                                      |
|                              v                                      |
|  +---------------------------------------------------------------+  |
|  | 3b. SECURITY AUDIT (/security-audit) [Epic mandatory]         |  |
|  |    review_stage: "security"                                   |  |
|  |    review_result: "awaiting"                                  |  |
|  |    Focus: 3 parallel sub-agents (static, reasoning, platform) |  |
|  |                                                               |  |
|  |    PASS: Set review_stage: "product-review",                  |  |
|  |          review_result: "awaiting"                            |  |
|  |          Add comment with SECURITY AUDIT PASSED template      |  |
|  |                                                               |  |
|  |    FAIL: Set review_result: "rejected"                        |  |
|  |          (review_stage stays "security")                      |  |
|  |          Add comment with REJECTION template                  |  |
|  |          -> Returns to step 1                                 |  |
|  +---------------------------------------------------------------+  |
|                              |                                      |
|                              v                                      |
|  +---------------------------------------------------------------+  |
|  | 4. PRODUCT REVIEW (PM Agent or Human)                         |  |
|  |    review_stage: "product-review"                             |  |
|  |    review_result: "awaiting"                                  |  |
|  |    Focus: UX, business logic, user value, correctness         |  |
|  |                                                               |  |
|  |    PASS: Set review_stage: null, review_result: null          |  |
|  |          Update status to completed                           |  |
|  |          Add comment with PRODUCT REVIEW PASSED template      |  |
|  |                                                               |  |
|  |    FAIL: Set review_result: "rejected"                        |  |
|  |          (review_stage stays "product-review")                |  |
|  |          Add comment with REJECTION template                  |  |
|  |          -> Returns to step 1                                 |  |
|  +---------------------------------------------------------------+  |
|                              |                                      |
|                              v                                      |
|                          COMPLETED                                  |
|                                                                     |
+---------------------------------------------------------------------+
```

---

## The Review Cycle (For Stories, Epics, Bugs, TechDebt)

This is the standard review cycle applied to Stories, Epics, Bugs, and TechDebt. Tasks do NOT go through this cycle.

```
+---------------------------------------------------------------------+
|                    REVIEW CYCLE (DETAILED)                           |
+---------------------------------------------------------------------+
|                                                                     |
|  +-- CODE REVIEW (Staff Engineer) ------------------------------+   |
|  |                                                              |   |
|  |  Checks:                                                     |   |
|  |  - Architecture follows patterns (MVVM)                      |   |
|  |  - @Observable used for ViewModels                           |   |
|  |  - async/await for async operations                          |   |
|  |  - Core Data best practices                                  |   |
|  |  - No security concerns                                      |   |
|  |  - SwiftLint passing                                         |   |
|  |  - Error handling adequate                                   |   |
|  |                                                              |   |
|  |  PASS -> review_stage: "qa", review_result: "awaiting"       |   |
|  |  FAIL -> review_result: "rejected" -> Dev fixes -> restart   |   |
|  +--------------------------------------------------------------+   |
|                              |                                      |
|                              v                                      |
|  +-- QA TESTING (QA Agent) -------------------------------------+   |
|  |                                                              |   |
|  |  Checks:                                                     |   |
|  |  - All acceptance criteria met                               |   |
|  |  - Edge cases handled                                        |   |
|  |  - No regressions introduced                                 |   |
|  |  - Error states work correctly                               |   |
|  |  - Performance acceptable                                    |   |
|  |                                                              |   |
|  |  PASS (Epic):                                                |   |
|  |    -> review_stage: "security", review_result: "awaiting"    |   |
|  |  PASS (Story/Bug/TechDebt):                                  |   |
|  |    -> review_stage: "product-review",                        |   |
|  |       review_result: "awaiting"                              |   |
|  |  FAIL -> review_result: "rejected" -> Dev fixes -> restart   |   |
|  +--------------------------------------------------------------+   |
|                              |                                      |
|                              v                                      |
|  +-- SECURITY AUDIT (/security-audit) [Epic mandatory] --------+   |
|  |                                                              |   |
|  |  Orchestrated by /security-audit with 3 sub-agents:          |   |
|  |  - Static analysis agent                                     |   |
|  |  - Reasoning/threat-model agent                              |   |
|  |  - Platform-specific agent                                   |   |
|  |                                                              |   |
|  |  PASS -> review_stage: "product-review",                     |   |
|  |          review_result: "awaiting"                           |   |
|  |  FAIL -> review_result: "rejected" -> Dev fixes -> restart   |   |
|  +--------------------------------------------------------------+   |
|                              |                                      |
|                              v                                      |
|  +-- PRODUCT REVIEW (PM Agent) ---------------------------------+   |
|  |                                                              |   |
|  |  Checks:                                                     |   |
|  |  - Meets user requirements                                   |   |
|  |  - UX is correct                                             |   |
|  |  - Business logic is sound                                   |   |
|  |  - Ready for users                                           |   |
|  |                                                              |   |
|  |  PASS -> review_stage: null, review_result: null             |   |
|  |          + status: completed                                 |   |
|  |  FAIL -> review_result: "rejected" -> Dev fixes -> restart   |   |
|  +--------------------------------------------------------------+   |
|                                                                     |
+---------------------------------------------------------------------+
```

---

## Rejection Rule

**When ANY reviewer rejects, the item goes back to the Dev Agent and restarts the FULL cycle from Code Review.**

This applies to Stories, Epics, Bugs, and TechDebt (NOT Tasks):
- Code Review fails -> Dev fixes -> `review_stage: "code-review", review_result: "awaiting"` -> full cycle restart
- QA fails -> Dev fixes -> `review_stage: "code-review", review_result: "awaiting"` -> full cycle restart
- Security Audit fails (Epic) -> Dev fixes -> `review_stage: "code-review", review_result: "awaiting"` -> full cycle restart
- Product Review fails -> Dev fixes -> `review_stage: "code-review", review_result: "awaiting"` -> full cycle restart

This ensures:
1. Simple, consistent flow for LLMs to follow
2. All changes get reviewed by all roles
3. No shortcuts that might miss issues

---

## Comment Templates

Comments are stored in `metadata.comments` array on each task. Each comment object contains:
- `id`: Unique identifier (e.g., "C1", "C2")
- `author`: Agent or human name
- `timestamp`: ISO 8601 timestamp
- `type`: Comment type (handoff, review, rejection, fix, completion)
- `content`: The comment text
- `resolved`: Boolean (only for `rejection` type comments)
- `resolved_by`: Who resolved it (only for `rejection` type comments)
- `resolved_at`: When resolved (only for `rejection` type comments)

### TASK COMPLETED (Dev - No Review)

```
TASK COMPLETED

**Completed by:** [Agent name]
**Date:** [ISO timestamp]

**What was implemented:**
- [Brief description of changes]

**Files changed:**
- [path/to/file1.swift]
- [path/to/file2.swift]

**Tests written:**
- [path/to/TestFile.swift]: [What the tests cover]

**Notes:**
[Any observations or caveats]

**Parent Story status:** [X of Y Tasks completed]
```

### READY FOR CODE REVIEW (Dev -> Staff Engineer) - Stories/Epics Only

```
READY FOR CODE REVIEW

**Submitted by:** [Agent name]
**Date:** [ISO timestamp]
**Item type:** [Story | Epic | Bug | TechDebt]

**Summary of work:**
- [Brief description of all changes in this Story/Epic]

**Tasks completed (if Story):**
- [x] Task 1: [description]
- [x] Task 2: [description]
- [x] Task 3: [description]

**Stories completed (if Epic):**
- [x] Story 1: [description]
- [x] Story 2: [description]

**All files changed:**
- [List key files across all tasks]

**Testing done:**
- [What was tested]

**Acceptance criteria addressed:**
- [x] Criteria 1
- [x] Criteria 2
- [x] Criteria 3
```

### CODE REVIEW PASSED (Staff Engineer -> QA)

```
CODE REVIEW PASSED

**Reviewed by:** [Staff Engineer name/agent]
**Review date:** [ISO timestamp]
**Item type:** [Story | Epic | Bug | TechDebt]

**What was checked:**
- [x] Architecture follows patterns
- [x] Code meets standards
- [x] No security concerns
- [x] Performance acceptable
- [x] Error handling adequate

**Notes:**
[Any observations or suggestions for future]
```

### QA PASSED (QA -> PM)

```
QA PASSED

**Tested by:** [QA name/agent]
**Test date:** [ISO timestamp]
**Item type:** [Story | Epic | Bug | TechDebt]

**Acceptance criteria verification:**
- [x] Criteria 1: [How verified]
- [x] Criteria 2: [How verified]
- [x] Criteria 3: [How verified]

**Additional testing:**
- [Edge cases tested]
- [Regression check: Pass/Fail]

**Notes:**
[Any observations]
```

### SECURITY AUDIT PASSED (Security Audit -> PM) - Epic Only

```
SECURITY AUDIT PASSED

**Audited by:** security-audit lead agent
**Audit date:** [ISO timestamp]
**Item type:** Epic

**Findings consolidated from 3 sub-agents:**
- **Static analysis:** [summary]
- **Reasoning/threat-model:** [summary]
- **Platform-specific:** [summary]

**Severity:** [none | low | medium]
**Decision:** PASS

**Notes:**
[Any advisory findings or future recommendations]
```

### SECURITY AUDIT REJECTED (Security Audit -> Dev) - Epic Only

```
SECURITY AUDIT REJECTED

**Rejected by:** security-audit lead agent
**Rejection date:** [ISO timestamp]
**Item type:** Epic

**Blocking findings:**

1. **[Finding title]**
   - Severity: [High | Critical]
   - Description: [What's wrong]
   - Recommendation: [How to fix]

**Bugs created:** [task-ids]

**Next action:** Dev to fix blocking findings and resubmit for code review.
```

### PRODUCT REVIEW PASSED (PM -> Close)

```
PRODUCT REVIEW PASSED

**Reviewed by:** [PM name/agent]
**Review date:** [ISO timestamp]
**Item type:** [Story | Epic | Bug | TechDebt]

**Verification:**
- [x] Meets user requirements
- [x] UX is correct
- [x] Business logic is sound
- [x] Ready for users

**Notes:**
[Any observations or follow-up items to track separately]
```

### REJECTION TEMPLATE (Any Reviewer)

```
REJECTED - [CODE REVIEW | QA | SECURITY AUDIT | PRODUCT REVIEW]

**Rejected by:** [Name/agent]
**Rejection date:** [ISO timestamp]
**Rejection stage:** [Code Review | QA | Security Audit | Product Review]
**Item type:** [Story | Epic | Bug | TechDebt]

**Issues found:**

1. **[Issue title]**
   - Description: [What's wrong]
   - Expected: [What should happen]
   - Actual: [What happened]
   - Severity: [Blocker | Major | Minor]

2. **[Issue title]**
   - Description: [What's wrong]
   - Expected: [What should happen]
   - Actual: [What happened]
   - Severity: [Blocker | Major | Minor]

**Acceptance criteria failed:**
- [ ] Criteria X: [Why it failed]

**Steps to reproduce (if applicable):**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Next action:** Dev to fix issues and resubmit for code review.
```

---

## State Transitions Summary

### Task (No Review Fields)
```
approval: "approved"
    | (dev implements)
    v
approval: "approved" [COMPLETED]
```

Tasks never get `review_stage` or `review_result` fields.

### Story / Bug / TechDebt (Review Cycle)
```
approval: "approved"
    | (dev completes all work)
    v
review_stage: "code-review", review_result: "awaiting"
    | (staff engineer approves)
    v
review_stage: "qa", review_result: "awaiting"
    | (QA approves)
    v
review_stage: "product-review", review_result: "awaiting"
    | (PM approves)
    v
review_stage: null, review_result: null [COMPLETED]
```

### Epic (Full Review Cycle with Mandatory Security Audit)
```
approval: "approved"
    | (dev completes all work)
    v
review_stage: "code-review", review_result: "awaiting"
    | (staff engineer approves)
    v
review_stage: "qa", review_result: "awaiting"
    | (QA approves)
    v
review_stage: "security", review_result: "awaiting"
    | (/security-audit with 3 sub-agents)
    v
review_stage: "product-review", review_result: "awaiting"
    | (PM approves)
    v
review_stage: null, review_result: null [COMPLETED]
```

### Rejection Path (Stories, Epics, Bugs, TechDebt Only)
```
[any stage]
    | (reviewer rejects)
    v
review_stage: [current stage], review_result: "rejected"
    | (dev fixes)
    v
review_stage: "code-review", review_result: "awaiting"  <-- ALWAYS RESTARTS HERE
    | (full cycle again)
    v
...
```

---

## Commands by Role

All workflow state operations use TaskUpdate tool calls. Workflow fields are set in `metadata` alongside other metadata fields.

### Dev Agent - Task Completion

```
// Start work on Task
TaskUpdate {
  id: "[task-id]",
  status: "in_progress"
}

// Complete Task (NO review fields)
TaskUpdate {
  id: "[task-id]",
  status: "completed",
  metadata: {
    approval: "approved",  // Keep approved, NO review_stage or review_result
    comments: [
      ...existing_comments,
      {
        "id": "C[next]",
        "timestamp": "2026-01-30T10:30:00Z",
        "author": "macos-developer-agent",
        "type": "completion",
        "content": "TASK COMPLETED\n\n**Completed by:** macOS Developer Agent\n**Date:** 2026-01-30\n\n**What was implemented:**\n- [description]\n\n**Files changed:**\n- [files]\n\n**Tests written:**\n- [test files]: [coverage]"
      }
    ]
  }
}

// After completing all Tasks, check parent Story
TaskGet { id: "[story-id]" }
// Check if all sibling Tasks are completed
```

### Dev Agent - Story Submission (After All Tasks Done)

```
// Submit Story for code review (when ALL Tasks complete)
TaskUpdate {
  id: "[story-id]",
  status: "in_progress",
  metadata: {
    approval: "approved",
    review_stage: "code-review",
    review_result: "awaiting",
    comments: [
      ...existing_comments,
      {
        "id": "C[next]",
        "timestamp": "2026-01-30T12:00:00Z",
        "author": "macos-developer-agent",
        "type": "handoff",
        "content": "READY FOR CODE REVIEW\n\n**Submitted by:** macOS Developer Agent\n**Date:** 2026-01-30\n**Item type:** Story\n\n**Summary of work:**\n- [description]\n\n**Tasks completed:**\n- [x] Task 1\n- [x] Task 2\n\n**All files changed:**\n- [files]"
      }
    ]
  }
}
```

### Dev Agent - Epic Submission (After All Stories Done)

```
// Submit Epic for code review (when ALL Stories complete)
TaskUpdate {
  id: "[epic-id]",
  status: "in_progress",
  metadata: {
    approval: "approved",
    review_stage: "code-review",
    review_result: "awaiting",
    comments: [
      ...existing_comments,
      {
        "id": "C[next]",
        "timestamp": "2026-01-30T16:00:00Z",
        "author": "macos-developer-agent",
        "type": "handoff",
        "content": "READY FOR CODE REVIEW\n\n**Submitted by:** macOS Developer Agent\n**Date:** 2026-01-30\n**Item type:** Epic\n\n**Summary of work:**\n- [description]\n\n**Stories completed:**\n- [x] Story 1\n- [x] Story 2\n\n**All files changed:**\n- [files across all stories]"
      }
    ]
  }
}
```

### Dev Agent - After Rejection (Stories, Epics, Bugs, TechDebt)

```
// Fix and resubmit (reset to code-review stage with awaiting result)
TaskUpdate {
  id: "[id]",
  metadata: {
    approval: "approved",
    review_stage: "code-review",
    review_result: "awaiting",
    comments: [
      ...existing_comments,
      {
        "id": "C[next]",
        "timestamp": "2026-01-30T14:00:00Z",
        "author": "macos-developer-agent",
        "type": "fix",
        "content": "FIXED AND RESUBMITTED\n\n**Fixed by:** macOS Developer Agent\n**Date:** 2026-01-30\n\n**Issues fixed:**\n- [what was fixed]"
      }
    ]
  }
}
```

### Staff Engineer Agent - Review Stories/Epics

```
// Find work to review (Stories, Epics, Bugs, TechDebt only - NOT Tasks)
TaskList
// Filter results where metadata.review_stage == "code-review"
// AND metadata.review_result == "awaiting"
// AND type is "story", "epic", "bug", or "chore" (NOT "task")

// Get details
TaskGet { id: "[id]" }

// PASS - advance to QA
TaskUpdate {
  id: "[id]",
  metadata: {
    approval: "approved",
    review_stage: "qa",
    review_result: "awaiting",
    comments: [
      ...existing_comments,
      {
        "id": "C[next]",
        "timestamp": "2026-01-30T11:00:00Z",
        "author": "staff-engineer-agent",
        "type": "review",
        "content": "CODE REVIEW PASSED\n\n**Reviewed by:** Staff Engineer Agent\n**Review date:** 2026-01-30\n**Item type:** [Story | Epic | Bug | TechDebt]\n\n**What was checked:**\n- [x] Architecture follows patterns\n- [x] Code meets standards\n..."
      }
    ]
  }
}

// FAIL - reject back to dev
TaskUpdate {
  id: "[id]",
  metadata: {
    approval: "approved",
    review_stage: "code-review",
    review_result: "rejected",
    comments: [
      ...existing_comments,
      {
        "id": "C[next]",
        "timestamp": "2026-01-30T11:00:00Z",
        "author": "staff-engineer-agent",
        "type": "rejection",
        "content": "REJECTED - CODE REVIEW\n\n**Rejected by:** Staff Engineer Agent\n**Rejection date:** 2026-01-30\n**Item type:** [Story | Epic | Bug | TechDebt]\n\n**Issues found:**\n1. [issue description]",
        "resolved": false,
        "resolved_by": null,
        "resolved_at": null
      }
    ]
  }
}
```

### QA Agent - Test Stories/Epics

```
// Find work to test
TaskList
// Filter results where metadata.review_stage == "qa"
// AND metadata.review_result == "awaiting"
// AND type is "story", "epic", "bug", or "chore" (NOT "task")

// Get details
TaskGet { id: "[id]" }

// PASS - advance to security (Epic) or product-review (Story/Bug/TechDebt)
// For Epics: review_stage: "security" (mandatory security audit gate)
// For Story/Bug/TechDebt: review_stage: "product-review"
TaskUpdate {
  id: "[id]",
  metadata: {
    approval: "approved",
    review_stage: "security",          // <- Epic; use "product-review" for Story/Bug/TechDebt
    review_result: "awaiting",
    comments: [
      ...existing_comments,
      {
        "id": "C[next]",
        "timestamp": "2026-01-30T12:00:00Z",
        "author": "qa-agent",
        "type": "review",
        "content": "QA PASSED\n\n**Tested by:** QA Agent\n**Test date:** 2026-01-30\n**Item type:** [Story | Epic | Bug | TechDebt]\n\n**Acceptance criteria verification:**\n- [x] Criteria 1: [how verified]"
      }
    ]
  }
}

// FAIL - reject back to dev
TaskUpdate {
  id: "[id]",
  metadata: {
    approval: "approved",
    review_stage: "qa",
    review_result: "rejected",
    comments: [
      ...existing_comments,
      {
        "id": "C[next]",
        "timestamp": "2026-01-30T12:00:00Z",
        "author": "qa-agent",
        "type": "rejection",
        "content": "REJECTED - QA\n\n**Rejected by:** QA Agent\n**Rejection date:** 2026-01-30\n**Item type:** [Story | Epic | Bug | TechDebt]\n\n**Issues found:**\n1. [issue description]",
        "resolved": false,
        "resolved_by": null,
        "resolved_at": null
      }
    ]
  }
}
```

### PM Agent (or Human) - Review Stories/Epics

```
// Find work to review
TaskList
// Filter results where metadata.review_stage == "product-review"
// AND metadata.review_result == "awaiting"
// AND type is "story", "epic", "bug", or "chore" (NOT "task")

// Get details
TaskGet { id: "[id]" }

// PASS - complete the item
TaskUpdate {
  id: "[id]",
  status: "completed",
  metadata: {
    approval: "approved",
    review_stage: null,
    review_result: null,
    comments: [
      ...existing_comments,
      {
        "id": "C[next]",
        "timestamp": "2026-01-30T13:00:00Z",
        "author": "pm-agent",
        "type": "review",
        "content": "PRODUCT REVIEW PASSED\n\n**Reviewed by:** PM Agent\n**Review date:** 2026-01-30\n**Item type:** [Story | Epic | Bug | TechDebt]\n\n**Verification:**\n- [x] Meets user requirements\n- [x] UX is correct\n- [x] Business logic is sound\n- [x] Ready for users"
      }
    ]
  }
}

// FAIL - reject back to dev
TaskUpdate {
  id: "[id]",
  metadata: {
    approval: "approved",
    review_stage: "product-review",
    review_result: "rejected",
    comments: [
      ...existing_comments,
      {
        "id": "C[next]",
        "timestamp": "2026-01-30T13:00:00Z",
        "author": "pm-agent",
        "type": "rejection",
        "content": "REJECTED - PRODUCT REVIEW\n\n**Rejected by:** PM Agent\n**Rejection date:** 2026-01-30\n**Item type:** [Story | Epic | Bug | TechDebt]\n\n**Issues found:**\n1. [issue description]",
        "resolved": false,
        "resolved_by": null,
        "resolved_at": null
      }
    ]
  }
}
```

---

## Querying by State

All queries use TaskList tool calls with appropriate filters.

```
// Plans awaiting human approval (epics only)
TaskList -> filter where metadata.approval == "pending"

// Ready to implement (approved Tasks, not started)
TaskList -> filter where metadata.approval == "approved" AND status = "pending" AND type = "task"

// Tasks currently being implemented
TaskList -> filter where metadata.approval == "approved" AND status = "in_progress" AND type = "task"

// Completed Tasks (check if parent Story ready for review)
TaskList -> filter where status = "completed" AND type = "task"

// Stories/Epics/Bugs/TechDebt waiting for code review
TaskList -> filter where metadata.review_stage == "code-review" AND metadata.review_result == "awaiting" AND type != "task"

// Stories/Epics/Bugs/TechDebt waiting for QA
TaskList -> filter where metadata.review_stage == "qa" AND metadata.review_result == "awaiting" AND type != "task"

// Epics waiting for security audit (mandatory gate)
TaskList -> filter where metadata.review_stage == "security" AND metadata.review_result == "awaiting" AND type != "task"

// Stories/Epics/Bugs/TechDebt waiting for product review
TaskList -> filter where metadata.review_stage == "product-review" AND metadata.review_result == "awaiting" AND type != "task"

// Items needing dev attention (rejected at any stage)
TaskList -> filter where metadata.review_stage == "code-review" AND metadata.review_result == "rejected"
TaskList -> filter where metadata.review_stage == "qa" AND metadata.review_result == "rejected"
TaskList -> filter where metadata.review_stage == "security" AND metadata.review_result == "rejected"
TaskList -> filter where metadata.review_stage == "product-review" AND metadata.review_result == "rejected"
```

---

## Status + Field Matrix

### Tasks (No Review Cycle)

| Stage | Status | approval | blocked | review_stage | review_result | Next Action |
|-------|--------|----------|---------|--------------|---------------|-------------|
| Approved, not started | `pending` | `"approved"` | `false` | n/a | n/a | Dev picks up |
| Being implemented | `in_progress` | `"approved"` | `false` | n/a | n/a | Dev codes |
| Complete | `completed` | `"approved"` | `false` | n/a | n/a | Check if Story ready for review |
| Blocked | any | `"approved"` | `true` | n/a | n/a | Resolve blocker |

### Stories / Epics / Bugs / TechDebt (Full Review Cycle)

| Stage | Status | approval | blocked | review_stage | review_result | Next Action |
|-------|--------|----------|---------|--------------|---------------|-------------|
| Planned, not approved (Epic only) | `pending` | `"pending"` | `false` | `null` | `null` | `/approve-epic` |
| Approved, not started | `pending` | `"approved"` | `false` | `null` | `null` | Work on child items (Story/Epic) or implement (Bug/TechDebt) |
| Being worked on | `in_progress` | `"approved"` | `false` | `null` | `null` | Complete all work |
| Ready for code review | `in_progress` | `"approved"` | `false` | `"code-review"` | `"awaiting"` | Staff Engineer reviews |
| Code review failed | `in_progress` | `"approved"` | `false` | `"code-review"` | `"rejected"` | Dev fixes |
| Ready for QA | `in_progress` | `"approved"` | `false` | `"qa"` | `"awaiting"` | QA tests |
| QA failed | `in_progress` | `"approved"` | `false` | `"qa"` | `"rejected"` | Dev fixes |
| Ready for security audit (Epic) | `in_progress` | `"approved"` | `false` | `"security"` | `"awaiting"` | `/security-audit` runs |
| Security audit failed (Epic) | `in_progress` | `"approved"` | `false` | `"security"` | `"rejected"` | Dev fixes |
| Ready for product review | `in_progress` | `"approved"` | `false` | `"product-review"` | `"awaiting"` | PM reviews |
| Product review failed | `in_progress` | `"approved"` | `false` | `"product-review"` | `"rejected"` | Dev fixes |
| Complete | `completed` | `"approved"` | `false` | `null` | `null` | Done |
| Blocked | any | `"approved"` | `true` | any | any | Resolve blocker |

---

## Hierarchy Review Flow Summary

```
EPIC
├── STORY 1
│   ├── Task A [completed - no review fields]
│   ├── Task B [completed - no review fields]
│   └── Task C [completed - no review fields]
│   └── [ALL TASKS DONE] -> Story 1 goes through Code Review -> QA -> Product Review
│
├── STORY 2
│   ├── Task D [completed - no review fields]
│   └── Task E [completed - no review fields]
│   └── [ALL TASKS DONE] -> Story 2 goes through Code Review -> QA -> Product Review
│
└── [ALL STORIES DONE] -> Epic goes through Code Review -> QA -> Security Audit -> Product Review
```

**Key Points:**
1. Tasks are marked complete with a completion comment only
2. Tasks NEVER get `review_stage` or `review_result` fields
3. When ALL Tasks under a Story complete, the STORY is submitted for code review
4. When ALL Stories under an Epic complete, the EPIC is submitted for code review
5. Reviews happen at Story and Epic level, aggregating all the work done in child items

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| `.claude/templates/tasks/metadata-schema.md` | Complete v2.0 metadata schema with all field definitions |
| `.claude/templates/tasks/epic.md` | Epic template with description structure |
| `.claude/templates/tasks/story.md` | Story template with description structure |
| `.claude/templates/tasks/task.md` | Task template with description structure |
| `.claude/rules/workflow/comment-requirements.md` | Comment format requirements |

---

## Schema Version Notes

This workflow document is compatible with **Metadata Schema v2.0**. In this version, workflow state has been moved from the `labels` array into 4 dedicated metadata fields:

- **`approval`** (string): `"pending"` or `"approved"` - replaces `awaiting:approval` and `approved` labels
- **`blocked`** (boolean): `true` or `false` - replaces `blocked` label
- **`review_stage`** (string or null): `"code-review"`, `"qa"`, `"security"` (mandatory for Epics, orchestrated by `/security-audit`), `"product-review"`, or `null` - replaces queue and rejection label prefixes
- **`review_result`** (string or null): `"awaiting"`, `"passed"`, `"rejected"`, or `null` - replaces the `awaiting:*` / `rejected:*` label suffixes

The `metadata.labels` array is now free for pure categorization tags (e.g., `"ui"`, `"networking"`, `"refactor"`, `"high-priority"`) and no longer carries workflow state.

Other v2.0 changes (unchanged by this migration):
- Task fields renamed: `acceptance_criteria` -> `local_checks`, `subtasks` -> `checklist`, `verify` -> `validation_hint`
- New required fields: `schema_version`, `last_updated_at`, `completion_signal`
- New AI hints fields: `ai_execution_hints`, `ai_context`, `implementation_constraints`
