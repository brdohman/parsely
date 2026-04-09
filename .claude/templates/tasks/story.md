# Story Template (v2.0)

Stories represent user-facing features or significant components within an epic. They break epics into deliverable chunks that provide user value.

**Schema Version:** 2.0 (AI-first schema)

---

## Title Format

**REQUIRED PREFIX:** All story subjects MUST begin with `Story: `

```
Story: [PROJECT-ID] - <User Story or Component>
```

Examples:
- `Story: MYAPP-101 - Login Form with email/password authentication`
- `Story: MYAPP-102 - Dashboard charts for revenue metrics`
- `Story: TRACKER-101 - API endpoints for user management`

**Note:** The `Story:` prefix is mandatory. Tasks without this prefix will fail validation.

---

## Description Sections

### Required Sections

```markdown
## Summary
<1-2 sentences: What does this story deliver?>

## User Story
As a <user type>, I want to <action> so that <benefit>.

## Context
<Why is this story needed now? How does it fit into the broader epic?>
<What value does completing this unlock?>

## Technical Approach
- <Brief description of implementation approach>
- <Key technical decisions>
- <Architecture considerations>

## Dependencies
- Story: <Other stories this depends on>
- System: <External services or APIs>
- Data: <Required data or infrastructure>
```

### Fields in Metadata Only (DO NOT duplicate in description)

The following fields are stored in structured metadata and should NOT appear in the description:

- **Out of Scope** -> `metadata.out_of_scope` array
- **Acceptance Criteria** -> `metadata.acceptance_criteria` array (Given/When/Then format)
- **Design Assets** -> `metadata.design_assets` array
- **Implementation Constraints** -> `metadata.implementation_constraints` array

This prevents duplication between description text and structured metadata.

---

## Complete Metadata Structure (v2.0)

Every story MUST include ALL of these fields.

**Key v2.0 Changes:**
- `schema_version`: Required, must be "2.0"
- `epic_id`: Quick reference to parent epic ID
- `implementation_constraints`: Recommended array for technical constraints
- `ai_context`: Recommended string for AI agent context
- `definition_of_done`: Now a structured object with completion_gates and generation_hints
- `last_updated_at`: Required timestamp
- **REMOVED:** `git` object (branch derived from story_id)
- **REMOVED:** `hours_estimated`, `hours_actual` (hours live at task level only)
- **REMOVED:** `context` field (use description Context section instead)

```json
{
  "schema_version": "2.0",
  "type": "story",
  "parent": "1",
  "story_id": "PROJECT-101",
  "epic_id": "PROJECT-100",
  "priority": "P2",

  "assignee": null,
  "claimed_by": null,
  "claimed_at": null,

  "sprint": 1,
  "points": 5,

  "approval": "pending",
  "blocked": false,
  "review_stage": null,
  "review_result": null,

  "labels": [],

  "journeys": ["J1"],                                // Journey IDs this story implements
  "ux_screens": ["SCR-01"],                          // Screen IDs this story covers
  "ux_flows_ref": "planning/[app]/UX_FLOWS.md",     // Path to UX Flows doc

  "design_assets": [
    {
      "name": "Login Flow Wireframes",
      "url": "https://figma.com/file/abc123",
      "type": "figma"
    },
    {
      "name": "Mobile Login Mockup",
      "url": "mockups/login-mobile.png",
      "type": "image"
    }
  ],

  "out_of_scope": [
    "Social login (OAuth) - separate story",
    "Password reset flow - separate story",
    "Remember me functionality - P3 enhancement",
    "Biometric authentication - future phase"
  ],

  "tasks": [
    {
      "id": "PROJECT-101-1",
      "claude_task_id": "13",
      "title": "Task: Create login form UI component",
      "status": "pending",
      "hours": 2
    },
    {
      "id": "PROJECT-101-2",
      "claude_task_id": "14",
      "title": "Task: Implement form validation",
      "status": "pending",
      "hours": 1.5
    }
  ],

  "acceptance_criteria": [
    {
      "id": "AC1",
      "title": "Email validation",
      "given": "User enters email in login form",
      "when": "Email format is invalid",
      "then": "Form shows inline validation error",
      "verify": "Unit test covers invalid email formats"
    },
    {
      "id": "AC2",
      "title": "Successful login",
      "given": "User enters valid credentials",
      "when": "Form is submitted",
      "then": "User is redirected to dashboard with session established",
      "verify": "Integration test verifies redirect and session cookie"
    }
  ],

  "implementation_constraints": [
    "SwiftUI SecureField for password entry",
    "Validate password via DatabaseService.validatePassword() against encrypted SQLite DB (Phase 1)",
    "Integrate with AppState to transition locked -> main",
    "Error handling for incorrect password attempts"
  ],

  "ai_context": "The login view is the first screen returning users see. It gates access to all app functionality and must integrate with the encrypted database from Phase 1.",

  "definition_of_done": {
    "completion_gates": [
      "All story acceptance_criteria pass (AC1..ACn) with evidence attached (test name or manual verification note)",
      "No regression on app launch routing for returning users"
    ],
    "generation_hints": [
      "Map each acceptance_criteria.id to a verification artifact (unit test name, UI test name, or screenshot + short note)."
    ]
  },

  "review": {
    "required": ["staff_engineer", "qa"],
    "completed": [],
    "current_reviewer": null
  },

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
| `type` | string | YES | Must be `"story"` |
| `parent` | string | YES | Task ID of parent epic |
| `story_id` | string | YES | Format: PROJECT-1XX |
| `epic_id` | string | YES | Parent epic ID for quick reference |

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
| `sprint` | number | YES | Sprint number (1, 2, 3...) |
| `points` | number | YES | Fibonacci: 1, 2, 3, 5, 8, 13, 21 |

**REMOVED in v2.0:** `hours_estimated`, `hours_actual` - Hours live at task level only. This eliminates double-counting and false precision.

### Context & Scope Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `out_of_scope` | string[] | YES | What this story does NOT cover (min 3) |

### Design Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `design_assets` | object[] | YES | Links to designs (can be empty array) |

#### Design Asset Object

```json
{
  "name": "Descriptive name",
  "url": "https://... or relative/path",
  "type": "figma" | "sketch" | "image" | "prototype" | "pdf" | "other"
}
```

### Tasks Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tasks` | object[] | YES | Child tasks (can start empty) |

#### Task Object (within story)

```json
{
  "id": "PROJECT-101-1",
  "claude_task_id": "13",
  "title": "Task: Task title",
  "status": "pending" | "in-progress" | "done",
  "hours": 2
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | YES | Logical project ID (e.g., PROJECT-101-1). Matches `task_id` on the task's own metadata. |
| `claude_task_id` | string | YES | Claude Code task system ID — use with `TaskGet`/`TaskUpdate`. Set after `TaskCreate` returns the ID. |
| `title` | string | YES | Task title (must include `Task:` prefix) |
| `status` | string | YES | `"pending"`, `"in-progress"`, or `"done"` |
| `hours` | number | YES | Hours estimate |

### Acceptance Criteria Fields

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `acceptance_criteria` | object[] | YES | 3 |

#### Acceptance Criteria Object

```json
{
  "id": "AC1",
  "title": "Short descriptive title",
  "given": "Starting condition or context",
  "when": "Action taken by user or system",
  "then": "Expected result or behavior",
  "verify": "How to verify this works"
}
```

### Implementation Constraints Fields (NEW in v2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `implementation_constraints` | string[] | RECOMMENDED | Technical constraints for implementation |

**Note:** This field is RECOMMENDED. If empty, agents should prompt for it or derive from context.

```json
"implementation_constraints": [
  "SwiftUI SecureField for password entry",
  "Validate password via DatabaseService.validatePassword()",
  "Integrate with AppState to transition locked -> main"
]
```

### AI Context Fields (NEW in v2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ai_context` | string | RECOMMENDED | Context for AI agents about this story |

**Note:** This field is RECOMMENDED. If empty, agents should prompt for it.

```json
"ai_context": "The login view is the first screen returning users see. It gates access to all app functionality."
```

### Definition of Done Fields (Restructured in v2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `definition_of_done` | object | YES | Structured completion criteria |

#### Definition of Done Object

```json
{
  "completion_gates": [
    "All story acceptance_criteria pass with evidence attached",
    "No regression on related functionality"
  ],
  "generation_hints": [
    "Map each acceptance_criteria.id to a verification artifact."
  ]
}
```

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `completion_gates` | string[] | YES | 2 |
| `generation_hints` | string[] | YES | 1 |

### Review Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `review` | object | YES | Review workflow tracking |

#### Review Object

```json
{
  "required": ["staff_engineer", "qa"],
  "completed": [],
  "current_reviewer": null
}
```

### Git Fields (REMOVED in v2.0)

The `git` object has been REMOVED from story metadata. Git branch information is derived from:
- Story branch: `story/PROJECT-XXX-description` (derived from story_id)
- Base branch: Parent epic branch

This reduces duplication and prevents stale git state.

### Comments Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `comments` | object[] | YES | Agent communication (can start empty) |

#### Comment Object

```json
{
  "id": "C1",
  "timestamp": "2026-01-30T10:15:00Z",
  "author": "pm-agent",
  "type": "question" | "decision" | "blocker" | "note" | "review",
  "content": "Comment text"
}
```

### Timestamp Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `created_at` | ISO8601 | YES | When story was created |
| `created_by` | string | YES | Agent or human who created it |
| `last_updated_at` | ISO8601 | YES | When story was last modified |

---

## Points Guidelines (Fibonacci)

| Points | Complexity | Typical Duration | Example |
|--------|------------|------------------|---------|
| 1 | Trivial | < 2 hours | Config change, copy update |
| 2 | Simple | 2-4 hours | Single component, basic CRUD |
| 3 | Moderate | 4-8 hours | Feature with some complexity |
| 5 | Complex | 1-2 days | Multi-component feature |
| 8 | Very Complex | 2-3 days | Cross-cutting concern |
| 13 | Large | 3-5 days | Consider splitting |
| 21 | Too Large | > 5 days | Must split into multiple stories |

**Rule of thumb:** If a story is 13+ points, look for ways to split it.

---

## Priority Guidelines

| Priority | Meaning | When to Use |
|----------|---------|-------------|
| P0 | Critical blocker | Blocks other critical work |
| P1 | Must have | Required for epic completion |
| P2 | Should have | Default, important for full feature |
| P3 | Nice to have | Enhancement, can ship without |
| P4 | Backlog | Future improvement |

Stories typically inherit or are one level below their epic's priority.

---

## TaskCreate Usage (v2.0)

```typescript
await TaskCreate({
  subject: "Story: PROJECT-101 - Login Form with email/password authentication",
  description: `## Summary
Implement login form that authenticates users via email/password and establishes a secure session.

## User Story
As a registered user, I want to log in with my email and password so that I can access my account.

## Context
This story enables user authentication, which is required before any personalized features can be built. It's the first user-facing deliverable in the Auth epic and unblocks the Dashboard and Settings stories.

## Technical Approach
- SwiftUI form with client-side validation
- API call to /api/auth/login
- JWT stored in Keychain
- Redirect to dashboard on success

## Dependencies
- Story: Database schema for users table (PROJECT-100-1)
- System: Auth API endpoint must be deployed
- Data: Test user accounts in staging`,
  activeForm: "Implementing login authentication",
  metadata: {
    schema_version: "2.0",
    type: "story",
    parent: "1",
    story_id: "PROJECT-101",
    epic_id: "PROJECT-100",
    priority: "P1",
    assignee: null,
    claimed_by: null,
    claimed_at: null,
    sprint: 1,
    points: 5,
    approval: "pending",
    blocked: false,
    review_stage: null,
    review_result: null,
    labels: [],
    journeys: ["J1"],
    ux_screens: ["SCR-01"],
    ux_flows_ref: "planning/project-name/UX_FLOWS.md",
    design_assets: [
      {
        name: "Login Flow Wireframes",
        url: "https://figma.com/file/abc123",
        type: "figma"
      }
    ],
    out_of_scope: [
      "Social login (OAuth) - separate story",
      "Password reset flow - separate story",
      "Remember me functionality - P3 enhancement",
      "Biometric authentication - future phase"
    ],
    tasks: [],
    acceptance_criteria: [
      {
        id: "AC1",
        title: "Email validation",
        given: "User enters email in login form",
        when: "Email format is invalid",
        then: "Form shows inline validation error",
        verify: "Unit test covers invalid email formats"
      },
      {
        id: "AC2",
        title: "Successful login",
        given: "User enters valid credentials",
        when: "Form is submitted",
        then: "User is redirected to dashboard with session established",
        verify: "Integration test verifies redirect and session"
      },
      {
        id: "AC3",
        title: "Rate limiting",
        given: "User has failed login 5 times in 1 minute",
        when: "User attempts another login",
        then: "Request is blocked with clear error message",
        verify: "Integration test verifies rate limit triggers"
      }
    ],
    implementation_constraints: [
      "SwiftUI SecureField for password entry",
      "Validate via DatabaseService.validatePassword()",
      "Integrate with AppState for state transitions"
    ],
    ai_context: "Login is the entry point for returning users. Must integrate with encrypted database from Phase 1.",
    definition_of_done: {
      completion_gates: [
        "All AC pass with evidence attached",
        "No regression on existing functionality"
      ],
      generation_hints: [
        "Map each AC to a test name or verification note"
      ]
    },
    review: {
      required: ["staff_engineer", "qa"],
      completed: [],
      current_reviewer: null
    },
    comments: [],
    created_at: "2026-01-30T10:00:00Z",
    created_by: "staff-engineer-agent",
    last_updated_at: "2026-01-30T10:00:00Z"
  }
});
```

---

## Validation Checklist (v2.0)

### Before creating the story, verify ALL of these:

#### Identification (6 checks)
- [ ] `schema_version` is "2.0"
- [ ] `type` is "story"
- [ ] `parent` links to correct epic task ID
- [ ] `story_id` follows PROJECT-1XX format
- [ ] `epic_id` matches parent epic's ID
- [ ] `status` is valid

#### Description (5 checks)
- [ ] Has Summary section (1-2 sentences)
- [ ] Has User Story in "As a... I want... So that..." format
- [ ] Has Context explaining why now and how it fits
- [ ] Has Technical Approach with implementation details
- [ ] Has Dependencies listed

#### Sizing (2 checks)
- [ ] `points` uses Fibonacci scale (1, 2, 3, 5, 8, 13, 21)
- [ ] `sprint` is assigned

#### Acceptance Criteria (3 checks)
- [ ] At least 3 acceptance criteria
- [ ] Each has id, title, given, when, then, verify
- [ ] Criteria are specific and testable

#### Scope (2 checks)
- [ ] `out_of_scope` has at least 3 items
- [ ] Boundaries are clear

#### AI Fields (2 checks)
- [ ] `implementation_constraints` array exists (can be empty but agents will prompt)
- [ ] `ai_context` string exists (can be empty but agents will prompt)

#### Definition of Done (2 checks)
- [ ] `definition_of_done.completion_gates` has at least 2 items
- [ ] `definition_of_done.generation_hints` has at least 1 item

#### Design (1 check)
- [ ] `design_assets` array exists (can be empty if no designs yet)

#### Tasks (1 check)
- [ ] `tasks` array exists (can be empty, populated as tasks are created)

#### Timestamps (2 checks)
- [ ] `created_at` is valid ISO 8601
- [ ] `last_updated_at` is valid ISO 8601

#### Workflow Fields (4 checks)
- [ ] `approval` is "pending" (initial state)
- [ ] `blocked` is false (unless dependencies unmet)
- [ ] `review_stage` is null (initial state)
- [ ] `review_result` is null (initial state)

#### Labels (1 check)
- [ ] Labels contain only categorization tags (no workflow state)

---

## Minimum Requirements Summary

| Field | Minimum Count |
|-------|---------------|
| `acceptance_criteria` | 3 |
| `out_of_scope` | 3 |
| `definition_of_done.completion_gates` | 2 |
| `definition_of_done.generation_hints` | 1 |
| `design_assets` | 0 (array required, can be empty) |
| `tasks` | 0 (array required, populated later) |
| `labels` | 0 (categorization tags only) |

---

## Anti-Patterns

| DO NOT | DO INSTEAD |
|--------|------------|
| Stories without user value | Pure technical work should be tasks |
| Missing parent epic link | Always link to parent |
| Vague user stories ("I want it to work") | Be specific about action and benefit |
| No technical approach | Include implementation guidance |
| Forgetting dependencies | List all blockers |
| Duplicate AC/out_of_scope in description | Put these in metadata ONLY |
| Acceptance criteria that can't be tested | Make every criterion verifiable |
| 13+ point stories | Split into smaller stories |
| Include `git` object | REMOVED in v2.0 - branch derived from story_id |
| Include `hours_estimated` | REMOVED in v2.0 - hours live at task level only |
| Include `context` field | Moved to description Context section |
| Simple string array for definition_of_done | Use structured object |
| Skipping design_assets array | Include even if empty |
| Forgetting `epic_id` | Required for quick reference |

---

## v2.0 Migration Notes

If converting a v1.0 story to v2.0:

### Remove These Fields
- `git` object
- `hours_estimated`
- `hours_actual`
- `context` (move content to description)

### Add These Fields
- `schema_version: "2.0"`
- `epic_id`
- `implementation_constraints` array (can be empty)
- `ai_context` string (can be empty)
- `definition_of_done` as structured object
- `last_updated_at`

### Transform These Fields
- `definition_of_done` from string array (if it existed) to structured object

---

## Story vs Task vs Epic

| Aspect | Epic | Story | Task |
|--------|------|-------|------|
| Scope | Business outcome | User value | Technical work |
| Duration | Weeks to months | Days to a week | Hours |
| Contains | Stories | Tasks | Checklist items |
| Owner | PM/Lead | Staff Engineer | Individual dev |
| Demoed to | Stakeholders | Product team | Technical team |
| Hours estimated | No (points only) | No (points only) | Yes |

---

## Cross-References

- **Epic Template:** `.claude/templates/tasks/epic.md`
- **Task Template:** `.claude/templates/tasks/task.md`
- **Metadata Schema:** `.claude/templates/tasks/metadata-schema.md`
- **Progress Tracking:** `.claude/templates/tasks/progress.md`
