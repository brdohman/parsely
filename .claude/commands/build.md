---
description: Build next available task or specified task. Claims task and implements. Delegates to appropriate agent.
argument-hint: task ID (optional, finds next approved task if omitted) OR --submit-story [story-id]
---

# /build

Work on next available task from Claude Code Tasks.

> ⛔ **Task State Protocol:** All TaskUpdate calls MUST follow `.claude/rules/global/task-state-updates.md`.

For v2.0 field names and workflow state values: see `.claude/rules/global/task-state-updates.md` and `.claude/templates/tasks/metadata-schema.md`.

## Review Scope

Tasks do NOT go through the review cycle. Only Stories do.

- **Task completion**: Mark as `completed`, add completion comment, NO review fields
- **Story submission**: When ALL Tasks under a Story are complete, submit the STORY for code review

## Delegation

- **Core Data/persistence work** -> Data Architect agent
- **UI/View work** -> Load design system (`skills/design-system/SKILL.md`), check design spec (`planning/design/[screen]-spec.md`), then macOS Developer agent
- **ViewModel/Service work** -> macOS Developer agent

## Flow

### 0. Pre-Work Validation (MANDATORY)

Before starting any Task, ALL of the following must pass:

| Check | What | Failure Action |
|-------|------|----------------|
| 1 | Task `approval == "approved"` | HARD STOP — run /approve-epic |
| 2 | Task `blocked == false` | HARD STOP — resolve blocker first |
| 3 | Parent Story `approval == "approved"` | HARD STOP — run /approve-epic |
| 4 | Parent Epic `approval == "approved"` | HARD STOP — run /approve-epic |

### 1. Find Task

```
# If no ID provided
TaskList: approval=="approved", status="pending", type="task"

# If ID provided
TaskGet [id]
```

### 2. Claim Task

```
TaskUpdate [id]: status="in_progress", claimed_by, claimed_at
Add STARTING comment (see task-state-updates.md Protocol 2)
```

### 3. Implement

Delegate to appropriate agent based on task type. Agent reads `local_checks`, `checklist`, `ai_execution_hints` from task before starting.

### 4. Discover New Work (if needed)

```
TaskCreate:
  subject: "Task: Found: [description]"
  metadata:
    schema_version: "2.0", type: "task"
    parent: [current-task-parent-id]
    approval: "pending", blocked: false
    local_checks: ["Check 1", "Check 2", "Check 3"]
    checklist: ["Step 1", "Step 2"]
    completion_signal: "...", validation_hint: "..."
    ai_execution_hints: ["..."]
```

### 5. Complete Task

#### Build Verification Gate

**MCP mode (preferred when Xcode is open):**
```
mcp__xcode__BuildProject(tabIdentifier: "...")
# If errors: mcp__xcode__GetBuildLog(tabIdentifier: "...")
```

**Shell fallback:**
```bash
xcodebuild build -scheme [AppName] -destination 'platform=macOS'
```

DO NOT run tests — deferred to QA stage.

If build FAILS -> DO NOT mark completed. Fix first.

#### Comment Gate

A task CANNOT be `status: "completed"` without BOTH:
1. Comment `type: "implementation"` — summary of work done
2. Comment `type: "testing"` — test files written (omit only if `testable: false`)

For comment JSON format: see `.claude/rules/global/task-state-updates.md` Protocol 6.

```
TaskUpdate [id]: status="completed" + both comments in same call
DO NOT add review_stage or review_result to Tasks
```

### 6. Check Parent Story Completion

```
TaskList: parent=[parent-story-id], type="task"
# Are ALL tasks completed?
```

If all complete: `Run: /build --submit-story [story-id]`

### 7. Show Next Available

```
TaskList: approval=="approved", status="pending", type="task"
```

---

## Submitting a Story for Review

### /build --submit-story [story-id]

1. Verify all child Tasks are `status="completed"`
2. Verify each task has implementation + testing comments
3. If any task missing comments -> HARD STOP

```
TaskUpdate [story-id]:
  metadata.review_stage: "code-review"
  metadata.review_result: "awaiting"
  Add READY FOR CODE REVIEW handoff comment
```

For handoff comment format: see `.claude/rules/global/task-state-updates.md` Protocol 4.

---

## Pre-Conditions

- **Task not approved** -> "Task missing `approval == "approved"`. Run /approve-epic first."
- **UI task without design spec** -> "Run /design first"
- **Blocked task** -> "Task has `blocked == true`. Resolve blocker first."
- **Has rejection** -> "Story has `review_result == "rejected"`. Use /fix"

## Swift/SwiftUI File Organization (MVVM)

All code lives in `app/[AppName]/`:

```
app/[AppName]/
├── [AppName].xcodeproj/
├── [AppName]/
│   ├── Features/[FeatureName]/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   ├── Core/
│   │   ├── Services/
│   │   ├── Repositories/
│   │   └── Extensions/
│   └── Shared/
│       ├── Components/
│       └── Utilities/
├── [AppName]Tests/
│   ├── Unit/
│   └── Integration/
└── [AppName]UITests/
```
