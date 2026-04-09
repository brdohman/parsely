# Task Template (v2.0)

Tasks are atomic units of work that implement specific deliverables within a story. They represent the actual implementation work done by developers.

**Schema Version:** 2.0 (AI-first schema)

---

## Title Format

**REQUIRED PREFIX:** All task subjects MUST begin with `Task: `

```
Task: <Action verb> <Specific deliverable>
```

**Action verbs:** Create, Implement, Add, Update, Fix, Refactor, Configure, Write, Build, Setup

Examples:
- `Task: Create User entity with Core Data model`
- `Task: Implement password validation service`
- `Task: Add loading states to login view`
- `Task: Configure Keychain storage for credentials`
- `Task: Write unit tests for auth service`

**Note:** The `Task:` prefix is mandatory. Tasks without this prefix will fail validation.

---

## Description Sections

### Required Sections

```markdown
## What
<1-2 sentences: Specific work to be done>

## Why
<Context: Why is this task needed? How does it fit into the story?>

## How
<Implementation approach>
<Specific patterns or approaches to use>
<Technical decisions>
```

### Fields in Metadata Only (DO NOT duplicate in description)

The following fields are stored in structured metadata and should NOT appear in the description:

- **Files to Modify** -> `metadata.files` array
- **Local Checks** -> `metadata.local_checks` array (string list)
- **Checklist** -> `metadata.checklist` array (string list)

This prevents duplication between description text and structured metadata.

---

## Complete Metadata Structure (v2.0)

Every task MUST include ALL of these fields.

**Key v2.0 Changes:**
- `schema_version`: Required, must be "2.0"
- `local_checks`: Renamed from `acceptance_criteria` (string array, min 3)
- `checklist`: Renamed from `subtasks` (string array, min 2)
- `validation_hint`: Renamed from `verify` (required string)
- `completion_signal`: NEW required field - when is this done?
- `ai_execution_hints`: NEW recommended field for AI agents
- `last_updated_at`: Required timestamp
- **REMOVED:** `definition_of_done` array (DoD is repo-level, not per-task)

```json
{
  "schema_version": "2.0",
  "type": "task",
  "parent": "2",
  "task_id": "PROJECT-101-1",
  "story_id": "PROJECT-101",
  "priority": "P2",

  "assignee": null,
  "claimed_by": null,
  "claimed_at": null,

  "hours_estimated": 2,
  "hours_actual": null,

  "approval": "pending",
  "blocked": false,

  "labels": [],

  "files": [
    "app/AppName/AppName/Views/Login/LoginView.swift"
  ],

  "checklist": [
    "Create LoginView.swift file structure",
    "Add SecureField with password binding",
    "Add lock icon and welcome text header",
    "Implement Unlock button with disabled state",
    "Add error message display area",
    "Add Enter key submit handling"
  ],

  "local_checks": [
    "LoginView renders with lock icon, title, and subtitle",
    "SecureField masks password input with bullets",
    "Unlock button is disabled when password is empty",
    "Error message area is hidden when no error",
    "Enter key submits the form"
  ],

  "completion_signal": "PR merged and story acceptance criteria still pass.",
  "validation_hint": "Build succeeds, LoginView renders correctly in preview",

  "ux_flows_refs": ["SM-Login-T3", "IS-001"],       // Specific UX Flows spec IDs this task implements
                                                      // References: state machine transitions (SM-*),
                                                      // interaction specs (IS-*), journey steps (J*-S*),
                                                      // or modal specs from the UX Flows doc

  "ai_execution_hints": [
    "Keep view purely presentational; state/errors should come from ViewModel.",
    "Match UI_SPEC: lock icon header + 'Welcome Back' title; keep spacing consistent with design system.",
    "Use .onSubmit to trigger unlock attempt; ensure Unlock button disabled when password empty."
  ],

  "comments": [],

  "created_at": "2026-01-30T10:00:00Z",
  "created_by": "staff-engineer-agent",
  "last_updated_at": "2026-01-30T12:00:00Z"
}
```

---

## Field Reference

### Identification Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | string | YES | Must be `"2.0"` |
| `type` | string | YES | Must be `"task"` |
| `parent` | string | YES | Task ID of parent story |
| `task_id` | string | YES | Format: PROJECT-XXX-N (story + number) |
| `story_id` | string | YES | Parent story ID for quick reference |
| `status` | string | YES | "pending" \| "in-progress" \| "blocked" \| "done" |

### Assignment Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `assignee` | string | YES | Agent or person responsible (null if unassigned) |
| `claimed_by` | string | YES | Who is actively working on it |
| `claimed_at` | ISO8601 | YES | When it was claimed |

**Valid assignee values:** `pm-agent`, `staff-engineer-agent`, `macos-developer-agent`, `qa-agent`, `security-agent`, `designer-agent`, `human`, `null`

### Sizing Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `hours_estimated` | number | YES | Estimated hours (typically 1-4) |
| `hours_actual` | number | YES | Actual hours (null until complete) |

**Important:** Tasks should be sized to complete in 1-4 hours. If larger, split into multiple tasks.

### Files & Checklist Fields

| Field | Type | Required | Min Count | Description |
|-------|------|----------|-----------|-------------|
| `files` | string[] | YES | 1 | Files to create or modify |
| `checklist` | string[] | YES | 2 | Granular steps within the task |

**Note:** `subtasks` has been RENAMED to `checklist` in v2.0 to better reflect its purpose - these are steps to check off, not sub-tasks in a hierarchy.

### Local Checks Fields

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `local_checks` | string[] | YES | 3 |

**Note:** `acceptance_criteria` has been RENAMED to `local_checks` in v2.0 for tasks. Stories/Epics still use `acceptance_criteria` with Given/When/Then format.

`local_checks` answer: "What must be true for THIS specific task to be accepted?"

These are simple string assertions, not the structured Given/When/Then/Verify format used at story and epic level.

### Completion Signal Fields (NEW in v2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `completion_signal` | string | YES | When is this task done? Clear stop condition. |

```json
"completion_signal": "PR merged and story acceptance criteria still pass."
```

This field is REQUIRED. It tells the AI agent (and humans) what constitutes "done" for this specific task.

### Validation Hint Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `validation_hint` | string | YES | Quick summary of how to verify task is complete |

**Note:** `verify` has been RENAMED to `validation_hint` in v2.0 for clarity.

```json
"validation_hint": "Build succeeds, LoginView renders correctly in preview"
```

### AI Execution Hints Fields (NEW in v2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ai_execution_hints` | string[] | RECOMMENDED | Hints for AI agents executing this task |

**Note:** This field is RECOMMENDED. If empty, agents should prompt for it or derive from context.

```json
"ai_execution_hints": [
  "Keep view purely presentational; state/errors should come from ViewModel.",
  "Match UI_SPEC: lock icon header + 'Welcome Back' title.",
  "Use .onSubmit to trigger unlock attempt."
]
```

These hints help AI agents understand:
- Code style preferences
- Design system requirements
- Integration points
- Common pitfalls to avoid

### Definition of Done (REMOVED in v2.0)

**REMOVED:** The `definition_of_done` array is NO LONGER present on tasks in v2.0.

**Rationale:** Definition of Done is a repo-level quality gate, not a per-task field. All tasks in a repo share the same quality bar (builds, tests pass, lint passes, code review, etc.). Duplicating this on every task was:
1. Redundant - same list repeated on every task
2. Out of sync - repo standards evolve, task fields don't get updated
3. Noisy - agents had to process the same boilerplate repeatedly

**Where DoD lives now:** `CLAUDE.md#quality-gates` or equivalent repo-level documentation. CI enforces these gates.

### Comments Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `comments` | object[] | YES | Agent communication (can start empty) |

#### Comment Object

```json
{
  "id": "C1",
  "timestamp": "2026-01-30T10:15:00Z",
  "author": "staff-engineer-agent",
  "type": "question" | "decision" | "blocker" | "note" | "review" | "research",
  "content": "Comment text"
}
```

#### Implementation Comment — Include Verification Status

When writing the implementation comment, note which APIs/patterns were verified vs assumed from training data. This helps reviewers know what to trust.

```json
{
  "id": "C2",
  "type": "implementation",
  "content": "IMPLEMENTATION COMPLETE\n\nFiles changed:\n- Views/Login/LoginView.swift\n\nAPIs used:\n- NavigationStack with path-based navigation [VERIFIED: developer.apple.com/swiftui]\n- SecureField with .onSubmit modifier [VERIFIED: developer.apple.com/swiftui]\n- @Observable macro for ViewModel [VERIFIED: swift.org/migration]\n\nNotes: Used .presentationDetents for sheet sizing — API confirmed current for macOS 26+."
}
```

If an API couldn't be verified during implementation, mark it `[UNVERIFIED]` so the code reviewer knows to check it.

### Timestamp Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `created_at` | ISO8601 | YES | When task was created |
| `created_by` | string | YES | Agent or human who created it |
| `last_updated_at` | ISO8601 | YES | When task was last modified |

---

## Hours Estimation Guidelines

| Hours | Complexity | Typical Work |
|-------|------------|--------------|
| 0.5-1 | Trivial | Config change, small fix, copy update |
| 1-2 | Simple | Single file change, basic implementation |
| 2-3 | Moderate | Multiple files, some complexity |
| 3-4 | Complex | Cross-cutting, multiple components |
| 4+ | Too Large | **Split into multiple tasks** |

**Rule:** If a task exceeds 4 hours, it should be broken down.

---

## Priority Guidelines

| Priority | Meaning | When to Use |
|----------|---------|-------------|
| P0 | Critical blocker | Blocks story completion, urgent fix |
| P1 | Must have | Required for story to be complete |
| P2 | Should have | Default, part of full implementation |
| P3 | Nice to have | Polish, optimization |
| P4 | Backlog | Technical debt, future cleanup |

Tasks typically inherit their story's priority unless blocking or optional.

---

## TaskCreate Usage (v2.0)

```typescript
await TaskCreate({
  subject: "Task: Create LoginView with password field",
  description: `## What
Create the SwiftUI LoginView component with a secure password field, unlock button, and error message display area following the UI specification.

## Why
The login view is the entry point for returning users. It must provide a clean, secure interface for password entry that matches the app's visual design language.

## How
- Create LoginView.swift in Views/Login/
- Use SecureField for password input with masked display
- Add lock icon header and "Welcome Back" title per UI spec
- Implement disabled button state when field is empty
- Add error message area that shows/hides based on ViewModel state
- Support Enter key to submit via .onSubmit modifier`,
  activeForm: "Creating LoginView with password field",
  metadata: {
    schema_version: "2.0",
    type: "task",
    parent: "2",
    task_id: "PROJECT-101-1",
    story_id: "PROJECT-101",
    priority: "P2",
    assignee: null,
    claimed_by: null,
    claimed_at: null,
    hours_estimated: 2,
    hours_actual: null,
    approval: "pending",
    blocked: false,
    labels: [],
    files: [
      "app/AppName/AppName/Views/Login/LoginView.swift"
    ],
    checklist: [
      "Create LoginView.swift file structure",
      "Add SecureField with password binding",
      "Add lock icon and welcome text header",
      "Implement Unlock button with disabled state",
      "Add error message display area",
      "Add Enter key submit handling"
    ],
    local_checks: [
      "LoginView renders with lock icon, title, and subtitle",
      "SecureField masks password input with bullets",
      "Unlock button is disabled when password is empty",
      "Error message area is hidden when no error",
      "Enter key submits the form"
    ],
    completion_signal: "PR merged and story acceptance criteria still pass.",
    validation_hint: "Build succeeds, LoginView renders correctly in preview",
    ux_flows_refs: ["SM-Login-T3", "IS-001"],
    ai_execution_hints: [
      "Keep view purely presentational; state/errors should come from ViewModel.",
      "Match UI_SPEC: lock icon header + 'Welcome Back' title.",
      "Use .onSubmit to trigger unlock attempt."
    ],
    comments: [],
    created_at: "2026-01-30T10:00:00Z",
    created_by: "staff-engineer-agent",
    last_updated_at: "2026-01-30T10:00:00Z"
  }
});
```

---

## Validation Checklist (v2.0)

### Before creating the task, verify ALL of these:

#### Identification (6 checks)
- [ ] `schema_version` is "2.0"
- [ ] `type` is "task"
- [ ] `parent` links to correct story task ID
- [ ] `task_id` follows PROJECT-XXX-N format
- [ ] `story_id` matches parent story
- [ ] `status` is valid

#### Title (2 checks)
- [ ] Title starts with action verb
- [ ] Title describes specific deliverable

#### Description (3 checks)
- [ ] Has What section (1-2 sentences)
- [ ] Has Why section (context and story fit)
- [ ] Has How section (implementation approach)

#### Sizing (2 checks)
- [ ] `hours_estimated` is between 0.5 and 4
- [ ] If > 4 hours, task should be split

#### Local Checks (2 checks)
- [ ] At least 3 local_checks
- [ ] Each check is specific and testable

#### Files & Checklist (2 checks)
- [ ] `files` array lists all files to modify
- [ ] `checklist` breaks down the work (min 2 items)

#### Completion & Validation (2 checks)
- [ ] `completion_signal` clearly defines "done"
- [ ] `validation_hint` summarizes how to confirm completion

#### AI Hints (1 check)
- [ ] `ai_execution_hints` array exists (can be empty but agents will prompt)

#### Timestamps (2 checks)
- [ ] `created_at` is valid ISO 8601
- [ ] `last_updated_at` is valid ISO 8601

#### Workflow Fields (2 checks)
- [ ] `approval` is "pending" (initial state)
- [ ] `blocked` is false (unless dependencies unmet)

#### Labels (1 check)
- [ ] Labels contain only categorization tags (no workflow state)

---

## Minimum Requirements Summary

| Field | Minimum Count |
|-------|---------------|
| `local_checks` | 3 |
| `files` | 1 |
| `checklist` | 2 |
| `labels` | 0 (categorization tags only) |

---

## Anti-Patterns

| DO NOT | DO INSTEAD |
|--------|------------|
| Vague titles ("Fix the thing") | Be specific: "Fix: Null pointer in login validation" |
| Use `acceptance_criteria` | RENAMED to `local_checks` in v2.0 |
| Use `subtasks` | RENAMED to `checklist` in v2.0 |
| Use `verify` | RENAMED to `validation_hint` in v2.0 |
| Include `definition_of_done` | REMOVED in v2.0 - DoD is repo-level |
| No parent story link | Always link to parent story |
| Tasks > 4 hours | Split into multiple tasks |
| Duplicate files/checklist in description | Put these in metadata ONLY |
| Local checks that can't be tested | Make every check verifiable |
| No assignee field | Include even if null initially |
| Forgetting hours_estimated | Always estimate (helps planning) |
| Forgetting completion_signal | Required - defines when task is done |
| Empty ai_execution_hints without prompting | Prompt for hints or derive from context |

---

## Local Checks Examples

### Good (Specific, Testable)

```json
"local_checks": [
  "LoginView renders with lock icon, title, and subtitle",
  "SecureField masks password input with bullets",
  "Unlock button is disabled when password is empty",
  "Error message area is hidden when no error state",
  "Enter key triggers unlock attempt via .onSubmit"
]
```

### Bad (Vague, Untestable)

```json
"local_checks": [
  "View works correctly",
  "Good user experience",
  "Code is clean"
]
```

---

## v2.0 Migration Notes

If converting a v1.0 task to v2.0:

### Remove These Fields
- `definition_of_done` array (DoD is now repo-level)
- `acceptance_criteria` (rename to `local_checks`)
- `subtasks` (rename to `checklist`)
- `verify` (rename to `validation_hint`)

### Add These Fields
- `schema_version: "2.0"`
- `last_updated_at`
- `completion_signal` (required)
- `ai_execution_hints` array (can be empty)

### Rename These Fields
| Old Name | New Name |
|----------|----------|
| `acceptance_criteria` | `local_checks` |
| `subtasks` | `checklist` |
| `verify` | `validation_hint` |

---

## Task Size Guidelines

A well-sized task should:
- Be completable in 1-4 hours
- Touch a focused set of files (ideally 1-5)
- Have 3-5 local_checks
- Have 2-6 checklist items
- Be independently testable
- Have a clear completion_signal

If a task seems too large, break it into multiple tasks under the same story.

---

## Cross-References

- **Epic Template:** `.claude/templates/tasks/epic.md`
- **Story Template:** `.claude/templates/tasks/story.md`
- **Metadata Schema:** `.claude/templates/tasks/metadata-schema.md`
- **Progress Tracking:** `.claude/templates/tasks/progress.md`
