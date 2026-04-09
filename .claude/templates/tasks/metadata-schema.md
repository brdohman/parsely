# Task Metadata Schema (v2.0)

This document defines the complete JSON structure for task metadata. All agents must follow this schema when creating or updating tasks.

**Schema Version:** 2.0 (AI-first schema)

---

## Subject and Title Naming Convention

**IMPORTANT:** All task subjects MUST use the appropriate type prefix. This applies to:
- The `subject` field on TaskCreate
- The `title` field in parent summary arrays (`stories[]` on epics, `tasks[]` on stories)

| Type | Required Prefix | Example |
|------|-----------------|---------|
| Epic | `Epic: ` | `Epic: MYAPP-100 - Project Foundation` |
| Story | `Story: ` | `Story: MYAPP-101 - Login Form with authentication` |
| Task | `Task: ` | `Task: Create User entity with Core Data` |
| Bug | `Bug: ` | `Bug: Duplicate matches for split transactions` |
| TechDebt | `TechDebt: ` | `TechDebt: SessionViewModel - Migrate to @Observable` |

**Why prefixes matter:**
- Enables quick visual identification of task type
- Supports consistent filtering and searching
- Ensures hierarchy is immediately clear
- Required for validation to pass

---

## Overview

Task metadata enables structured data for:
- Hierarchy tracking (Epic -> Story -> Task)
- Workflow state fields and status
- Acceptance criteria with Given/When/Then/Verify format
- Planning document references (section anchors, not line numbers)
- Risk management
- AI execution hints and constraints
- Agent communication via comments

---

## Prohibited Fields

**Do NOT include these fields in metadata.** They conflict with Claude Tasks built-in fields or have been removed in v2.0.

| Field | Why Prohibited |
|-------|----------------|
| `metadata.status` | **Conflicts with top-level `status`** (pending/in_progress/completed) managed by Claude Tasks. Use top-level `status` for task state and `approval`/`review_stage`/`review_result` for workflow state. **Do not add `status` to epic, story, or task metadata.** |
| `metadata.labels` with workflow values | Labels like `awaiting:approval`, `rejected:qa`, etc. are v1.0 patterns. Use dedicated workflow fields instead. Labels are for categorization only (e.g., `"ui"`, `"infrastructure"`). |

## ID Field Disambiguation

ID fields have different meanings depending on context. This table clarifies:

| Context | Field | Meaning | Example |
|---------|-------|---------|---------|
| Top-level `TaskItem` | `id` | Claude Code system ID | `"2"` |
| Epic metadata | `id` | Logical project ID | `"CASHFLOW-200"` |
| Story metadata | `story_id` | Logical project ID | `"CASHFLOW-201"` |
| Task metadata | `task_id` | Logical project ID | `"CASHFLOW-201-1"` |
| Epic's `stories[]` array | `id` | Logical project ID (matches `story_id`) | `"CASHFLOW-201"` |
| Epic's `stories[]` array | `claude_task_id` | Claude Code system ID (for `TaskGet`) | `"3"` |
| Story's `tasks[]` array | `id` | Logical project ID (matches `task_id`) | `"CASHFLOW-201-1"` |
| Story's `tasks[]` array | `claude_task_id` | Claude Code system ID (for `TaskGet`) | `"6"` |

**Rule:** In parent summary arrays (`stories[]`, `tasks[]`), always use `claude_task_id` for the Claude Code system ID. Never use `task_id` in these arrays — it would be ambiguous with the logical project ID field on the referenced item's own metadata.

---

## Schema by Type

### Epic Metadata (Complete)

Epics are top-level initiatives. **ALL fields below are REQUIRED** for comprehensive planning.

```json
{
  "schema_version": "2.0",
  "id": "PROJECT-100",
  "type": "epic",
  "phase": "phase-1",
  "project": "project-name",
  "priority": "P1",
  "goal": "One-line goal statement",
  "test_criteria": "How to verify the epic is complete",

  "created_at": "2026-01-30T10:00:00Z",
  "created_by": "claude",
  "planned_by": "claude",
  "last_updated_at": "2026-01-30T12:00:00Z",

  "story_count": 5,
  "complexity": "L",
  "risk_level": "medium",
  "sprint": 1,

  "estimate": {
    "primary_unit": "points",
    "value": 21,
    "notes": "Use story points as the primary estimate. Avoid parallel hour/day estimates at epic level to reduce false precision."
  },

  "approval": "pending",
  "blocked": false,
  "review_stage": null,
  "review_result": null,
  "labels": ["infrastructure", "phase-1"],

  "branch": "epic/PROJECT-100-foundation",
  "base_branch": "main",

  "ux_flows_ref": "planning/project-name/UX_FLOWS.md",
  "journeys": ["J1", "J3"],
  "screens": ["SCR-01", "SCR-04"],
  "design_scope": "full_design",
  "design_phase_complete": false,
  "max_parallel_tasks": 2,

  "references": {
    "prd_stories": ["O1", "X1", "X2"],
    "tech_spec_sections": ["Architecture", "Data Models", "Security"],
    "data_schema_sections": ["Entities", "Relationships"],
    "ui_spec_sections": ["Login Screen", "Dashboard"],
    "notes": "Prefer stable section anchors/headers over line numbers."
  },

  "external_deps": ["macOS 26.0+", "Xcode 16+", "Swift 5.9+"],
  "blocks_epics": ["PROJECT-200"],
  "dependencies": {
    "external": [
      {"name": "Alamofire", "version": "5.x", "purpose": "Networking"}
    ],
    "internal": ["PROJECT-050"],
    "blocks_epics": ["PROJECT-200"]
  },

  "success_metrics": {
    "primary": [
      "Metric 1 - specific and measurable",
      "Metric 2 - specific and measurable",
      "Metric 3 - specific and measurable"
    ],
    "secondary": [
      "Metric 1 - nice to have",
      "Metric 2 - nice to have"
    ]
  },

  "acceptance_criteria": [
    {
      "id": "AC1",
      "title": "Short descriptive title",
      "given": "Starting condition or context",
      "when": "Action taken by user or system",
      "then": "Expected result or behavior",
      "verify": "How to verify this works (test method)"
    }
  ],

  "stories": [
    {
      "id": "PROJECT-101",
      "claude_task_id": "3",
      "title": "Story: Story title",
      "description": "What this story delivers",
      "points": 5,
      "hours": 6,
      "tasks": [
        "Task: Task 1 description",
        "Task: Task 2 description"
      ]
    }
  ],

  "risks": [
    {
      "id": "R1",
      "description": "Risk description",
      "probability": "medium",
      "impact": "high",
      "mitigation": "Mitigation strategy"
    }
  ],

  "execution_plan": {
    "shape": "precedence_phases",
    "phases": [
      {
        "phase": "execution-1",
        "intent": "Core infrastructure",
        "stories": ["PROJECT-101", "PROJECT-102"],
        "deliverables": ["Core Data stack working", "Basic CRUD verified"]
      }
    ],
    "notes": "AI-oriented sequencing: precedence-driven phases (not calendar days). Treat as ordering guidance; adjust as dependencies evolve."
  },

  "out_of_scope": [
    "Explicitly excluded item 1",
    "Explicitly excluded item 2",
    "Explicitly excluded item 3"
  ],

  "definition_of_done": {
    "purpose": "Stop condition for AI + humans: when to consider the epic complete.",
    "completion_gates": [
      "All epic acceptance criteria pass via runnable checks",
      "End-to-end flow runs through all stories",
      "All declared out_of_scope items remain unimplemented",
      "No open P0/P1 bugs for this epic scope"
    ],
    "quality_gates_source": "CLAUDE.md#quality-gates (or CI)",
    "generation_hints": [
      "Derive a checklist run log from epic acceptance_criteria.verify fields.",
      "Require each story to attach evidence: test name, screenshot, or manual verification note.",
      "Treat linting/coverage/accessibility as repo-level quality gates enforced by CI, not repeated here."
    ]
  },

  "suggested_inputs": [
    {
      "field": "owner",
      "suggestion": "Set a single accountable owner (PM or TL) for routing decisions and scope control."
    }
  ],

  "comments": [],
  "restored_from": null,
  "original_task_id": null
}
```

---

## Epic Fields Reference

### Identification Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | string | YES | Must be `"2.0"` |
| `id` | string | YES | Format: PROJECT-X00 (e.g., MYAPP-100) |
| `type` | string | YES | Must be `"epic"` |
| `phase` | string | YES | Phase identifier (e.g., "phase-1") |
| `project` | string | YES | Project code (e.g., "myapp") |

### Priority Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `priority` | string | YES | "P0" \| "P1" \| "P2" \| "P3" \| "P4" |

### Goal & Criteria Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `goal` | string | YES | One-line goal statement |
| `test_criteria` | string | YES | How to verify epic is complete |

### Timestamp Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `created_at` | ISO8601 | YES | When epic was created |
| `created_by` | string | YES | "claude" \| "human" |
| `planned_by` | string | YES | "claude" \| "human" |
| `last_updated_at` | ISO8601 | YES | When epic was last modified |

### Sizing Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `story_count` | number | YES | Count of stories in this epic |
| `complexity` | string | YES | "S" \| "M" \| "L" \| "XL" |
| `risk_level` | string | YES | "low" \| "medium" \| "high" |
| `sprint` | number | YES | Sprint number (1, 2, 3...) |
| `estimate` | object | YES | Unified estimate (see below) |

#### Estimate Object (NEW in v2.0)

Replaces the old `estimated_hours`, `estimated_days`, and `size` fields with a single unified estimate.

```json
{
  "primary_unit": "points",
  "value": 21,
  "notes": "Use story points as the primary estimate. Avoid parallel hour/day estimates at epic level to reduce false precision."
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `primary_unit` | string | YES | "points" \| "hours" \| "days" |
| `value` | number | YES | The estimate value |
| `notes` | string | YES | Context for the estimate |

### Workflow State & Labels Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `approval` | string | YES | `"pending"` \| `"approved"` |
| `blocked` | boolean | YES | `true` \| `false` |
| `review_stage` | string \| null | YES | `"code-review"` \| `"qa"` \| `"security"` \| `"product-review"` \| `"human-uat"` \| `null` |
| `review_result` | string \| null | YES | `"awaiting"` \| `"passed"` \| `"rejected"` \| `null` |
| `labels` | string[] | YES | Categorization tags only (no workflow state). Minimum 0. |
| `branch` | string | YES | Branch name format: epic/PROJECT-XXX-description |
| `base_branch` | string | YES | Branch to merge back into when epic completes. Default: `"main"`. Set to another epic branch (e.g., `"epic/PROJECT-100-foundation"`) when this epic builds on uncommitted work. |

**Note:** The `git_setup` object has been REMOVED in v2.0. Git commands are standard and don't need to be stored per-epic.

### Planning Document Reference Fields (Simplified in v2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `references` | object | YES | Section anchors (NOT line numbers) |

#### References Object

```json
{
  "prd_stories": ["O1", "X1", "X2"],
  "tech_spec_sections": ["Architecture", "Data Models"],
  "data_schema_sections": ["Entities", "Relationships"],
  "ui_spec_sections": ["Login Screen", "Dashboard"],
  "notes": "Prefer stable section anchors/headers over line numbers."
}
```

**REMOVED in v2.0:** `tech_spec_lines`, `data_schema_lines` - Line numbers are brittle and break when files change. Use section headers/anchors instead.

### Dependency Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `external_deps` | string[] | YES | External dependencies |
| `blocks_epics` | string[] | YES | Epic IDs this blocks |
| `dependencies` | object | YES | Detailed dependency info |

### Success Metrics Fields

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `success_metrics.primary` | string[] | YES | 3 |
| `success_metrics.secondary` | string[] | YES | 2 |

### Acceptance Criteria Fields

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `acceptance_criteria` | object[] | YES | 5 |

#### Acceptance Criteria Object (Given/When/Then/Verify)

```json
{
  "id": "AC1",
  "title": "Short descriptive title",
  "given": "Starting condition or context",
  "when": "Action taken by user or system",
  "then": "Expected result or behavior",
  "verify": "How to verify this works (test method)"
}
```

### Stories Fields

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `stories` | object[] | YES | 3 |

#### Story Object (Summary within Epic)

**Lifecycle:** At epic creation time (planning agent), `claude_task_id` is `null` and `tasks` is an empty array. After `/write-stories-and-tasks` runs, both are populated with real values. The object shape must have exactly these 7 fields — no more, no less. Do NOT add `status`, `task_count`, or other fields.

```json
{
  "id": "PROJECT-101",
  "claude_task_id": "3",
  "title": "Story: Story title here",
  "description": "What this story delivers",
  "points": 5,
  "hours": 6,
  "tasks": [
    "Task: Task 1 description",
    "Task: Task 2 description"
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | YES | Logical project ID (e.g., PROJECT-101). Matches `story_id` on the story's own metadata. |
| `claude_task_id` | string\|null | YES | Claude Code task system ID — use with `TaskGet`/`TaskUpdate`. Set to `null` at epic creation time (by planning agent), then populated by `/write-stories-and-tasks` after stories are created via `TaskCreate`. |
| `title` | string | YES | Story title (must include `Story:` prefix) |
| `description` | string | YES | What this story delivers |
| `points` | number | YES | Story points estimate |
| `hours` | number | YES | Hours estimate |
| `tasks` | string[] | YES | Task descriptions (brief summaries, include `Task:` prefix) |

### Risks Fields

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `risks` | object[] | YES | 3 |

#### Risk Object

```json
{
  "id": "R1",
  "description": "Risk description",
  "probability": "low" | "medium" | "high",
  "impact": "low" | "medium" | "high",
  "mitigation": "Mitigation strategy"
}
```

### Execution Plan Fields (NEW in v2.0 - Replaces timeline)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `execution_plan` | object | YES | AI-oriented sequencing |

#### Execution Plan Object

Replaces the old `timeline` array which used calendar days.

```json
{
  "shape": "precedence_phases",
  "phases": [
    {
      "phase": "execution-1",
      "intent": "Focus area for this phase",
      "stories": ["PROJECT-101", "PROJECT-102"],
      "deliverables": ["What should be done by end of phase"]
    }
  ],
  "notes": "AI-oriented sequencing: precedence-driven phases (not calendar days). Treat as ordering guidance; adjust as dependencies evolve."
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `shape` | string | YES | "precedence_phases" \| "parallel" \| "sequential" |
| `phases` | object[] | YES | Ordered list of execution phases |
| `notes` | string | YES | Context for AI agents |

### Scope Fields

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `out_of_scope` | string[] | YES | 3 |

### Definition of Done Fields (Restructured in v2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `definition_of_done` | object | YES | Structured completion criteria |

#### Definition of Done Object (NEW Structure)

Replaces the simple string array with a structured object.

```json
{
  "purpose": "Stop condition for AI + humans: when to consider the epic complete.",
  "completion_gates": [
    "All epic acceptance criteria pass via runnable checks",
    "End-to-end flow runs through all stories",
    "All declared out_of_scope items remain unimplemented",
    "No open P0/P1 bugs for this epic scope"
  ],
  "quality_gates_source": "CLAUDE.md#quality-gates (or CI)",
  "generation_hints": [
    "Derive a checklist run log from epic acceptance_criteria.verify fields.",
    "Require each story to attach evidence: test name, screenshot, or manual verification note."
  ]
}
```

| Field | Type | Required | Min Count | Description |
|-------|------|----------|-----------|-------------|
| `purpose` | string | YES | - | Why this exists |
| `completion_gates` | string[] | YES | 4 | Specific completion criteria |
| `quality_gates_source` | string | YES | - | Where repo quality gates are defined |
| `generation_hints` | string[] | YES | 2 | Hints for AI agents |

### Suggested Inputs Fields (NEW in v2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `suggested_inputs` | object[] | NO | Fields that could be populated later |

```json
{
  "field": "owner",
  "suggestion": "Set a single accountable owner (PM or TL) for routing decisions and scope control."
}
```

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
  "type": "question",
  "content": "Comment text"
}
```

**Comment Types:** question, decision, blocker, note, review, planning

**Comment Authors:** pm-agent, staff-engineer-agent, qa-agent, macos-developer-agent, security-agent, build-engineer-agent, human

### Backup/Restore Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `restored_from` | string | NO | Backup name if restored |
| `original_task_id` | string | NO | Original task ID before restore |

---

## Story Metadata (Complete)

Stories are phases or components under an epic. **ALL fields below are REQUIRED.**

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

  "journeys": ["J1"],
  "ux_screens": ["SCR-01"],
  "ux_flows_ref": "planning/project-name/UX_FLOWS.md",

  "design_assets": [],

  "out_of_scope": [
    "Social login (OAuth) - separate story",
    "Password reset flow - separate story",
    "Remember me functionality - P3 enhancement"
  ],

  "tasks": [
    {
      "id": "PROJECT-101-1",
      "claude_task_id": "13",
      "title": "Task: Create login form UI component",
      "status": "pending",
      "hours": 2
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
    }
  ],

  "implementation_constraints": [
    "SwiftUI SecureField for password entry",
    "Validate password via DatabaseService.validatePassword()",
    "Integrate with AppState to transition locked → main"
  ],

  "ai_context": "The login view is the first screen returning users see. It gates access to all app functionality.",

  "definition_of_done": {
    "completion_gates": [
      "All story acceptance_criteria pass with evidence attached",
      "No regression on related functionality"
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

## Story Fields Reference

### Identification Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | string | YES | Must be `"2.0"` |
| `type` | string | YES | Must be `"story"` |
| `parent` | string | YES | Task ID of parent epic |
| `story_id` | string | YES | Format: PROJECT-1XX |
| `epic_id` | string | YES | Parent epic ID for quick reference |
| `priority` | string | YES | "P0" \| "P1" \| "P2" \| "P3" \| "P4" |

### Assignment Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `assignee` | string | YES | Agent or person responsible (null if unassigned) |
| `claimed_by` | string | YES | Who is actively working on it |
| `claimed_at` | ISO8601 | YES | When it was claimed (null if unclaimed) |

**Valid assignee values:** `pm-agent`, `staff-engineer-agent`, `macos-developer-agent`, `qa-agent`, `security-agent`, `designer-agent`, `human`, `null`

### Sizing Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sprint` | number | YES | Sprint number (1, 2, 3...) |
| `points` | number | YES | Fibonacci: 1, 2, 3, 5, 8, 13, 21 |

**REMOVED in v2.0:** `hours_estimated`, `hours_actual` - Hours live at task level only, not story level. This eliminates double-counting.

#### Points Guidelines (Fibonacci)

| Points | Complexity | Typical Duration |
|--------|------------|------------------|
| 1 | Trivial | < 2 hours |
| 2 | Simple | 2-4 hours |
| 3 | Moderate | 4-8 hours |
| 5 | Complex | 1-2 days |
| 8 | Very Complex | 2-3 days |
| 13 | Large | 3-5 days (consider splitting) |
| 21 | Too Large | > 5 days (must split) |

### Context & Scope Fields

| Field | Type | Required | Min Count | Description |
|-------|------|----------|-----------|-------------|
| `out_of_scope` | string[] | YES | 3 | What this story does NOT cover |

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
| `tasks` | object[] | YES | Child tasks (can start empty, populated as tasks created) |

#### Task Object (within story)

```json
{
  "id": "PROJECT-101-1",
  "claude_task_id": "13",
  "title": "Task: Task title here",
  "status": "pending" | "in-progress" | "done",
  "hours": 2
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | YES | Logical project ID (e.g., PROJECT-101-1). Matches `task_id` on the task's own metadata. |
| `claude_task_id` | string\|null | YES | Claude Code task system ID — use with `TaskGet`/`TaskUpdate`. Set to `null` initially, then populated after `TaskCreate` returns the ID. |
| `title` | string | YES | Task title (must include `Task:` prefix) |
| `status` | string | YES | `"pending"`, `"in-progress"`, or `"done"` |
| `hours` | number | YES | Hours estimate |

### Acceptance Criteria Fields

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `acceptance_criteria` | object[] | YES | 3 |

#### Acceptance Criteria Object (Given/When/Then/Verify)

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
  "Integrate with AppState to transition locked → main"
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

| Field | Type | Required | Min Count | Description |
|-------|------|----------|-----------|-------------|
| `completion_gates` | string[] | YES | 2 | Specific completion criteria |
| `generation_hints` | string[] | YES | 1 | Hints for AI agents |

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
- Epic branch: `epic/PROJECT-XXX-description`
- Story branch: `story/PROJECT-XXX-description` (derived from story_id)

This reduces duplication and prevents stale git state.

### Comments Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `comments` | object[] | YES | Agent communication (can start empty) |

### Timestamp Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `created_at` | ISO8601 | YES | When story was created |
| `created_by` | string | YES | Agent or human who created it |
| `last_updated_at` | ISO8601 | YES | When story was last modified |

---

## Task Metadata (Complete)

Tasks are actual work items under a story. **ALL fields below are REQUIRED.**

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
    "Implement Unlock button with disabled state"
  ],

  "local_checks": [
    "LoginView renders with lock icon, title, and subtitle",
    "SecureField masks password input with bullets",
    "Unlock button is disabled when password is empty"
  ],

  "completion_signal": "PR merged and story acceptance criteria still pass.",
  "validation_hint": "Build succeeds, LoginView renders correctly in preview",

  "ux_flows_refs": ["SM-Login-T3", "IS-001"],

  "ai_execution_hints": [
    "Keep view purely presentational; state/errors should come from ViewModel.",
    "Match UI_SPEC: lock icon header + 'Welcome Back' title.",
    "Use .onSubmit to trigger unlock attempt."
  ],

  "comments": [],

  "created_at": "2026-01-30T10:00:00Z",
  "created_by": "staff-engineer-agent",
  "last_updated_at": "2026-01-30T12:00:00Z"
}
```

---

## Task Fields Reference

### Identification Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | string | YES | Must be `"2.0"` |
| `type` | string | YES | Must be `"task"` |
| `parent` | string | YES | Task ID of parent story |
| `task_id` | string | YES | Format: PROJECT-XXX-N (story ID + number) |
| `story_id` | string | YES | Parent story ID for quick reference |
| `priority` | string | YES | "P0" \| "P1" \| "P2" \| "P3" \| "P4" |

### Assignment Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `assignee` | string | YES | Agent or person responsible (null if unassigned) |
| `claimed_by` | string | YES | Who is actively working on it |
| `claimed_at` | ISO8601 | YES | When it was claimed (null if unclaimed) |

**Valid assignee values:** `pm-agent`, `staff-engineer-agent`, `macos-developer-agent`, `qa-agent`, `security-agent`, `designer-agent`, `human`, `null`

### Sizing Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `hours_estimated` | number | YES | Estimated hours (typically 1-4) |
| `hours_actual` | number | YES | Actual hours (null until complete) |

**Important:** Tasks should be sized to complete in 1-4 hours. If larger, split into multiple tasks.

### Files & Checklist Fields (RENAMED in v2.0)

| Field | Type | Required | Min Count | Description |
|-------|------|----------|-----------|-------------|
| `files` | string[] | YES | 1 | Files to create or modify |
| `checklist` | string[] | YES | 2 | Granular steps within the task |

**Note:** `subtasks` has been RENAMED to `checklist` in v2.0 to better reflect its purpose.

### Local Checks Fields (RENAMED in v2.0)

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `local_checks` | string[] | YES | 3 |

**Note:** `acceptance_criteria` has been RENAMED to `local_checks` in v2.0 for tasks. Stories/Epics still use `acceptance_criteria`.

`local_checks` answer: "What must be true for THIS specific task to be accepted?"

### Completion Signal Fields (NEW in v2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `completion_signal` | string | YES | When is this task done? |

```json
"completion_signal": "PR merged and story acceptance criteria still pass."
```

### Validation Hint Fields (RENAMED in v2.0)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `validation_hint` | string | YES | Quick summary of how to verify task is complete |

**Note:** `verify` has been RENAMED to `validation_hint` in v2.0 for clarity.

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

### Definition of Done (REMOVED in v2.0)

**REMOVED:** `definition_of_done` array is no longer present on tasks. Definition of Done is a repo-level quality gate, not a per-task field. See `CLAUDE.md#quality-gates` or equivalent.

### Comments Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `comments` | object[] | YES | Agent communication (can start empty) |

### Timestamp Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `created_at` | ISO8601 | YES | When task was created |
| `created_by` | string | YES | Agent or human who created it |
| `last_updated_at` | ISO8601 | YES | When task was last modified |

---

## Sub-task Metadata

Sub-tasks are granular work items under a task. Schema unchanged.

```json
{
  "type": "sub-task",
  "parent": "3",
  "task_id": "task-id-here",
  "hours_estimated": 0.5,
  "verify": "xcdatamodeld file exists with entity definitions",
  "comments": [],
  "created_at": "2026-01-30T10:00:00Z",
  "created_by": "macos-developer-agent",
  "claimed_by": "macos-developer-agent",
  "claimed_at": "2026-01-30T10:30:00Z"
}
```

---

## Bug Metadata (Complete)

Bugs track defects found during development or testing. Bugs go through the same review cycle as stories (Code Review → QA → Product Review). **ALL fields below are REQUIRED.**

```json
{
  "schema_version": "2.0",
  "type": "bug",
  "parent": "1",
  "severity": "major",
  "priority": "P1",

  "assignee": null,
  "claimed_by": null,
  "claimed_at": null,

  "approval": "approved",
  "blocked": true,
  "review_stage": null,
  "review_result": null,
  "labels": ["bug"],

  "rca_status": "pending",
  "found_in": "story-id-here",
  "environment": "dev",

  "steps_to_reproduce": [
    "Open the app",
    "Navigate to settings",
    "Click save without changes"
  ],
  "expected_behavior": "App shows 'No changes to save' message",
  "actual_behavior": "App crashes with nil pointer exception",

  "hours_estimated": 1,
  "hours_actual": null,

  "comments": [],

  "created_at": "2026-01-30T10:00:00Z",
  "created_by": "qa-agent",
  "last_updated_at": "2026-01-30T10:00:00Z"
}
```

---

## Bug Fields Reference

### Identification Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | string | YES | Must be `"2.0"` |
| `type` | string | YES | Must be `"bug"` |
| `parent` | string | YES | Task ID of parent epic (null if standalone) |
| `priority` | string | YES | "P0" \| "P1" \| "P2" \| "P3" |

### Severity Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `severity` | string | YES | `"critical"` \| `"major"` \| `"moderate"` \| `"minor"` |

#### Severity-to-Priority Mapping

| Severity | Priority | Meaning |
|----------|----------|---------|
| critical | P0 | Fix immediately, blocks release |
| major | P1 | Fix before next review cycle |
| moderate | P2 | Fix when convenient |
| minor | P3 | Backlog |

### Assignment Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `assignee` | string | YES | Agent or person responsible (null if unassigned) |
| `claimed_by` | string | YES | Who is actively working on it |
| `claimed_at` | ISO8601 | YES | When it was claimed (null if unclaimed) |

### Workflow State Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `approval` | string | YES | `"pending"` \| `"approved"` |
| `blocked` | boolean | YES | `true` (until RCA approved) \| `false` |
| `review_stage` | string \| null | YES | `"code-review"` \| `"qa"` \| `"product-review"` \| `null` |
| `review_result` | string \| null | YES | `"awaiting"` \| `"passed"` \| `"rejected"` \| `null` |
| `labels` | string[] | YES | Categorization tags (typically includes `"bug"`) |

### RCA Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `rca_status` | string | YES | Tracks root cause analysis progress |

#### RCA Status Values

| Value | Meaning |
|-------|---------|
| `"pending"` | Bug created, investigation not started |
| `"investigated"` | Dev agent completed RCA |
| `"needs-more-info"` | Staff engineer wants more investigation |
| `"reviewed"` | Staff engineer approved the RCA |
| `"approved"` | Human approved — ready for fix |

### Bug Detail Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `found_in` | string \| null | YES | Story ID where bug was found, or null |
| `environment` | string | YES | `"dev"` \| `"staging"` \| `"production"` |
| `steps_to_reproduce` | string[] | YES | Ordered reproduction steps (min 1) |
| `expected_behavior` | string | YES | What should happen |
| `actual_behavior` | string | YES | What actually happens |

### Sizing Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `hours_estimated` | number | YES | Estimated hours (null until RCA complete) |
| `hours_actual` | number | YES | Actual hours (null until complete) |

### Comments Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `comments` | object[] | YES | Agent communication (can start empty) |

### Timestamp Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `created_at` | ISO8601 | YES | When bug was created |
| `created_by` | string | YES | Agent or human who reported it |
| `last_updated_at` | ISO8601 | YES | When bug was last modified |

---

## TechDebt Metadata (Complete)

Tech debt items represent code that works today but creates drag on velocity, reliability, or safety over time. TechDebt goes through the same review cycle as stories (Code Review → QA → Product Review). **ALL fields below are REQUIRED.**

```json
{
  "schema_version": "2.0",
  "type": "techdebt",
  "parent": null,

  "debt_type": "quality",
  "debt_category": "force-unwrap",
  "discovered_by": "techdebt-scan",
  "discovered_at": "2026-02-19T10:00:00Z",

  "priority": "P3",

  "assignee": null,
  "claimed_by": null,
  "claimed_at": null,

  "hours_estimated": 2,
  "hours_actual": null,

  "files_affected": ["app/AppName/AppName/Views/LoginView.swift"],
  "regression_risk": "medium",
  "compounding": false,
  "impact_if_deferred": "Force unwraps in auth flow will crash on nil password during edge-case empty keychain state.",
  "business_justification": "Prevents potential crash during first-launch flow; unblocks Swift 6 strict concurrency adoption.",

  "checklist": [
    "Audit all ! usages in the affected file(s)",
    "Replace with guard let / if let / nil coalescing as appropriate"
  ],
  "local_checks": [
    "Zero force unwraps remain in files_affected",
    "Build succeeds with no new warnings",
    "All existing tests pass without modification"
  ],
  "completion_signal": "PR merged, all tests green, no new SwiftLint warnings introduced.",
  "validation_hint": "swiftlint run on affected files, xcodebuild test passes.",
  "ai_execution_hints": [
    "Check for ! in guard conditions, optional chains, and downcasts."
  ],

  "approval": "pending",
  "blocked": false,
  "review_stage": null,
  "review_result": null,
  "labels": ["tech-debt", "quality"],

  "comments": [],
  "created_at": "2026-02-19T10:00:00Z",
  "created_by": "techdebt-scan",
  "last_updated_at": "2026-02-19T10:00:00Z"
}
```

---

## TechDebt Fields Reference

### Debt Classification Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `debt_type` | string | YES | `"architectural"` \| `"quality"` \| `"test-coverage"` \| `"dependency"` \| `"performance"` \| `"documentation"` |
| `debt_category` | string | YES | Specific sub-type (e.g., `"force-unwrap"`, `"mvvm-violation"`, `"missing-tests"`) |
| `discovered_by` | string | YES | `"techdebt-scan"` \| `"code-review"` \| `"incident"` \| `"developer"` \| `"qa"` |
| `discovered_at` | ISO8601 | YES | When this was identified |

### Impact Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `files_affected` | string[] | YES | Files that need to change (min 1) |
| `regression_risk` | string | YES | `"low"` \| `"medium"` \| `"high"` |
| `compounding` | boolean | YES | Does deferred debt generate more debt? |
| `impact_if_deferred` | string | YES | What gets worse if not addressed |
| `business_justification` | string | YES | Why fix it now |

### Sizing Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `hours_estimated` | number | YES | 0.5–4 hours (split if larger) |
| `hours_actual` | number | YES | Actual hours (null until complete) |

### Work Fields

| Field | Type | Required | Min Count |
|-------|------|----------|-----------|
| `checklist` | string[] | YES | 2 |
| `local_checks` | string[] | YES | 3 |
| `completion_signal` | string | YES | — |
| `validation_hint` | string | YES | — |
| `ai_execution_hints` | string[] | RECOMMENDED | — |

---

## Minimum Requirements Summary

### Epic

| Field | Minimum Count |
|-------|---------------|
| `success_metrics.primary` | 3 |
| `success_metrics.secondary` | 2 |
| `acceptance_criteria` | 5 |
| `stories` | 3 |
| `risks` | 3 |
| `out_of_scope` | 3 |
| `definition_of_done.completion_gates` | 4 |
| `definition_of_done.generation_hints` | 2 |
| `execution_plan.phases` | 1 |
| `labels` | 0 |

### Story

| Field | Minimum Count |
|-------|---------------|
| `acceptance_criteria` | 3 |
| `out_of_scope` | 3 |
| `definition_of_done.completion_gates` | 2 |
| `definition_of_done.generation_hints` | 1 |
| `design_assets` | 0 (array required, can be empty) |
| `tasks` | 0 (array required, populated later) |
| `labels` | 0 |

### Task

| Field | Minimum Count |
|-------|---------------|
| `local_checks` | 3 |
| `files` | 1 |
| `checklist` | 2 |
| `labels` | 0 |

### Bug

| Field | Minimum Count |
|-------|---------------|
| `steps_to_reproduce` | 1 |
| `labels` | 0 |
| `comments` | 0 (array required, can start empty) |

### TechDebt

| Field | Minimum Count |
|-------|---------------|
| `files_affected` | 1 |
| `checklist` | 2 |
| `local_checks` | 3 |
| `hours_estimated` | Required (0.5–4, split if larger) |
| `debt_type` | Required (valid value) |
| `debt_category` | Required (specific sub-type) |
| `regression_risk` | Required (`"low"`, `"medium"`, `"high"`) |
| `labels` | Must include `"tech-debt"` |

---

## Workflow State Fields

### Approval Field
| Value | Meaning | Set By | Cleared By |
|-------|---------|--------|------------|
| `"pending"` | Needs human approval | PM Agent (creation) | Human (via /approve-epic) |
| `"approved"` | Human approved, ready to implement | Human (via /approve-epic) | - |

### Blocked Field
| Value | Meaning | Set By | Cleared By |
|-------|---------|--------|------------|
| `true` | Cannot proceed due to dependency | Any Agent | Any Agent |
| `false` | No blockers | Default | - |

### Review Stage Field (Epic, Story, Bug, and TechDebt)
| Value | Meaning | Set By |
|-------|---------|--------|
| `"code-review"` | Ready for or rejected from code review | macOS Dev Agent / Staff Engineer Agent |
| `"qa"` | Ready for or rejected from QA | Staff Engineer Agent / QA Agent |
| `"security"` | Ready for or rejected from security review | macOS Dev Agent / Security Agent |
| `"product-review"` | Ready for or rejected from product review | QA Agent / PM Agent |
| `null` | Not in review (pre-review or completed) | PM Agent (completion) |

### Review Result Field (Epic, Story, Bug, and TechDebt)
| Value | Meaning | Set By |
|-------|---------|--------|
| `"awaiting"` | Waiting for reviewer | Submitting agent |
| `"rejected"` | Reviewer found issues | Reviewing agent |
| `null` | Not in review | PM Agent (completion) |

**Coupling rule:** `review_stage` and `review_result` must both be null or both be non-null.

**Task restriction:** Tasks do NOT have `review_stage` or `review_result` fields.

### Categorization Labels
| Field | Description |
|-------|-------------|
| `labels` | Pure categorization tags. No workflow state. Examples: `["infrastructure", "phase-1", "ui"]`. May be empty. |

---

## Agent Names

Valid values for `assignee`, `created_by`, `claimed_by`, and comment `author`:

- `pm-agent` - Product Manager
- `staff-engineer-agent` - Staff Engineer
- `macos-developer-agent` - macOS Developer
- `qa-agent` - Quality Assurance
- `security-agent` - Security Reviewer
- `build-engineer-agent` - Build/Release Engineer
- `designer-agent` - UI/UX Designer
- `data-architect-agent` - Database/Data Architecture
- `planning-agent` - Planning Agent (epic creation)
- `human` - Human user

---

## Validation Levels

### Required vs Recommended Fields

| Level | Behavior | Examples |
|-------|----------|----------|
| **Required** | Must be present and meet minimum counts. Validation fails without them. | `schema_version`, `completion_signal`, `validation_hint`, `local_checks` (min 3), `checklist` (min 2) |
| **Recommended** | Should be present. Agents prompt for these if empty but don't block validation. | `ai_execution_hints`, `implementation_constraints`, `ai_context` |

**Required fields are enforced at creation time. Recommended fields improve AI execution quality but allow flexibility.**

---

## Validation Rules

### v2.0 Validation

1. **schema_version** must be `"2.0"` for all new items
2. **type** must be: `"epic"`, `"story"`, `"task"`, `"sub-task"`, `"bug"`
3. **priority** must be: `"P0"`, `"P1"`, `"P2"`, `"P3"`, `"P4"`
4. **labels** contains only categorization tags (no workflow state prefixes like "awaiting:" or "rejected:")
5. **parent** required for story, task, sub-task; forbidden for epic
6. **stories** array only present on epics (minimum 3)
7. **acceptance_criteria** required for epics (min 5), stories (min 3)
8. **local_checks** required for tasks (min 3)
9. **definition_of_done** object required for epics and stories (structured format)
10. **definition_of_done** is NOT present on tasks (repo-level quality gate)
11. **out_of_scope** required for epics (min 3) and stories (min 3)
12. **comments** array required, can start empty
13. **created_at** and **last_updated_at** must be valid ISO 8601 format
14. **acceptance_criteria** must use Given/When/Then/Verify format for epics and stories
15. **assignee** required for stories and tasks (can be null)
16. **design_assets** required for stories (can be empty array)
17. **tasks** array required for stories (can be empty, populated as tasks created)
18. **points** required for stories (Fibonacci scale)
19. **hours_estimated** required for tasks (NOT for stories in v2.0)
20. **files** required for tasks (minimum 1)
21. **checklist** required for tasks (minimum 2)
22. **validation_hint** and **completion_signal** required for tasks
23. **estimate** object required for epics (replaces estimated_hours/days/size)
24. **execution_plan** object required for epics (replaces timeline)
25. **epic_id** required for stories
26. **implementation_constraints** recommended for stories (prompt if empty)
27. **ai_context** recommended for stories (prompt if empty)
28. **ai_execution_hints** recommended for tasks (prompt if empty)
29. **approval** must be `"pending"` or `"approved"` for all types
30. **blocked** must be boolean for all types
31. **review_stage** and **review_result** required for epics, stories, bugs, and techdebt, must both be null or both non-null
32. **review_stage** and **review_result** must NOT be present on tasks
33. **review_stage** valid values: `"code-review"`, `"qa"`, `"security"`, `"product-review"`, `"human-uat"` (epic only), or `null`
34. **review_result** valid values: `"awaiting"`, `"passed"`, `"rejected"`, or `null`

---

## Migration from v1.0

### Fields to Remove

| Type | Remove These Fields |
|------|---------------------|
| Epic | `git_setup`, `tech_spec_lines`, `data_schema_lines`, `estimated_hours`, `estimated_days`, `size`, `timeline`, `prd_stories` (move to references) |
| Story | `git`, `hours_estimated`, `hours_actual`, `context` (move to description) |
| Task | `acceptance_criteria` (rename to `local_checks`), `subtasks` (rename to `checklist`), `verify` (rename to `validation_hint`), `definition_of_done` |

### Fields to Add

| Type | Add These Fields |
|------|------------------|
| Epic | `schema_version`, `last_updated_at`, `estimate`, `execution_plan`, `definition_of_done` (structured), `suggested_inputs` |
| Story | `schema_version`, `last_updated_at`, `epic_id`, `implementation_constraints`, `ai_context`, `definition_of_done` (structured) |
| Task | `schema_version`, `last_updated_at`, `completion_signal`, `ai_execution_hints` |

### Fields to Rename

| Type | Old Name | New Name |
|------|----------|----------|
| Task | `acceptance_criteria` | `local_checks` |
| Task | `subtasks` | `checklist` |
| Task | `verify` | `validation_hint` |

---

## UX Flows Integration Fields

These fields connect task metadata to the UX Flows document (`planning/[app]/UX_FLOWS.md`). All are **optional** -- epics without UI work can omit them entirely.

### `ux_flows_ref`

| Property | Value |
|----------|-------|
| **Type** | `string` |
| **Applies To** | Epic, Story |
| **Required** | NO (optional) |
| **Description** | Path to the UX Flows document for this project. Links the epic or story to its UX specification. |
| **Example** | `"planning/cashflow/UX_FLOWS.md"` |

### `journeys`

| Property | Value |
|----------|-------|
| **Type** | `string[]` (array of strings) |
| **Applies To** | Epic, Story |
| **Required** | NO (optional) |
| **Description** | Journey IDs from the UX Flows document that this epic or story covers. Journeys represent end-to-end user flows. |
| **Example** | `["J1", "J3"]` (epic), `["J1"]` (story) |

### `screens`

| Property | Value |
|----------|-------|
| **Type** | `string[]` (array of strings) |
| **Applies To** | Epic |
| **Required** | NO (optional) |
| **Description** | Screen IDs from the UX Flows document that this epic touches. Used at epic level for broad screen coverage mapping. |
| **Example** | `["SCR-01", "SCR-04", "SCR-07"]` |

### `design_scope`

| Property | Value |
|----------|-------|
| **Type** | `string` (enum) |
| **Applies To** | Epic |
| **Required** | NO (optional) |
| **Description** | Indicates the level of design work required for this epic. Determines whether a Design Phase (Phase A) is needed before development. |
| **Valid Values** | `"full_design"` (new screens/flows need full design), `"design_update"` (existing screens need modifications), `"no_design"` (no UI changes, backend/infrastructure only) |
| **Example** | `"full_design"` |

### `design_phase_complete`

| Property | Value |
|----------|-------|
| **Type** | `boolean` |
| **Applies To** | Epic |
| **Required** | NO (optional) |
| **Description** | Whether the Design Phase (Phase A) has been completed. Set to `true` after the designer agent finishes UI specifications. Automatically `true` for epics with `design_scope: "no_design"`. |
| **Example** | `false` (design pending), `true` (design done or not needed) |

### `max_parallel_tasks`

| Property | Value |
|----------|-------|
| **Type** | `integer` |
| **Applies To** | Epic |
| **Required** | NO (optional, default: 2) |
| **Description** | Maximum number of implementation agents to spawn per story during `/build-epic` and `/build-story`. Controls task-level parallelism within a single story. Higher values speed up stories with many independent tasks but increase xcodebuild contention. |
| **Valid Values** | `1` (serial), `2` (default), `3`, `4` (max) |
| **Example** | `3` |

### `ux_screens`

| Property | Value |
|----------|-------|
| **Type** | `string[]` (array of strings) |
| **Applies To** | Story |
| **Required** | NO (optional) |
| **Description** | Screen IDs from the UX Flows document that this story covers. More granular than the epic-level `screens` field. |
| **Example** | `["SCR-01"]` |

### `ux_flows_refs`

| Property | Value |
|----------|-------|
| **Type** | `string[]` (array of strings) |
| **Applies To** | Task |
| **Required** | NO (optional) |
| **Description** | Specific UX Flows specification IDs that this task implements. References state machine transitions (`SM-*`), interaction specs (`IS-*`), journey steps (`J*-S*`), or modal specs from the UX Flows document. |
| **Example** | `["SM-Login-T3", "IS-001", "J1-S2"]` |

### UX Flows Fields Summary

| Field | Type | Applies To | Description |
|-------|------|-----------|-------------|
| `ux_flows_ref` | string | epic, story | Path to UX Flows document |
| `journeys` | string[] | epic, story | Journey IDs (J1, J2...) covered |
| `screens` | string[] | epic | Screen IDs (SCR-01...) touched |
| `design_scope` | enum string | epic | `"full_design"`, `"design_update"`, or `"no_design"` |
| `design_phase_complete` | boolean | epic | Whether Phase A design is done |
| `max_parallel_tasks` | integer | epic | Max task agents per story (default: 2, max: 4) |
| `ux_screens` | string[] | story | Screen IDs this story covers |
| `ux_flows_refs` | string[] | task | Specific spec IDs (SM-*, IS-*, J*-S*) implemented |

---

## Cross-References

- **Epic Template:** `.claude/templates/tasks/epic.md`
- **Story Template:** `.claude/templates/tasks/story.md`
- **Task Template:** `.claude/templates/tasks/task.md`
- **Bug Template:** `.claude/templates/tasks/bug.md`
- **TechDebt Template:** `.claude/templates/tasks/techdebt.md`
- **Progress Tracking:** `.claude/templates/tasks/progress.md`
