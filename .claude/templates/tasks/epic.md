# Epic Template (v2.0)

Epics are top-level initiatives that group related stories together. They represent significant business outcomes or project phases.

**Schema Version:** 2.0 (AI-first schema)

---

## CRITICAL: Before Creating an Epic

You MUST have completed these steps:

1. **Read `planning/progress.md`** to determine which phase to plan
2. **Read ALL planning documents:**
   - `planning/docs/PRD.md`
   - `planning/docs/TECHNICAL_SPEC.md`
   - `planning/docs/UI_SPEC.md` (if applicable)
   - `planning/docs/DATA_SCHEMA.md` (if applicable)
   - `planning/docs/IMPLEMENTATION_GUIDE.md`
3. **Completed PM Review** (clarifying questions answered)
4. **Completed Staff Engineer Review** (risks identified)

If using `/epic` command, these steps are automated.

---

## Title Format

**REQUIRED PREFIX:** All epic subjects MUST begin with `Epic: `

**EXACT format:** `Epic: [PROJECT]-[PHASE]00 - [Descriptive Title]`

Examples:
- `Epic: MYAPP-100 - Project Foundation & Core Data Setup`
- `Epic: MYAPP-200 - Login & Onboarding UI`
- `Epic: TRACKER-100 - Data Sync Infrastructure`

**Note:** The `Epic:` prefix is mandatory. Tasks without this prefix will fail validation.

---

## Description Format

```markdown
## Problem Statement
When [context from PRD],
As a [role from PRD], I want [goal from phase scope],
So that [benefit from PRD],
But currently [current state/gap].

## Solution
[Synthesized from TECHNICAL_SPEC and IMPLEMENTATION_GUIDE - 1-3 sentences]

## Outcome to be Achieved
After completing this epic, [stakeholders] will have [concrete deliverables].
[Specific measurable outcomes].
```

---

## Complete Metadata Structure (v2.0)

Every epic MUST include ALL of these fields.

**Key v2.0 Changes:**
- `schema_version`: Required, must be "2.0"
- `estimate`: Replaces `estimated_hours`, `estimated_days`, and `size`
- `execution_plan`: Replaces `timeline`
- `definition_of_done`: Now a structured object, not an array
- `references`: Simplified - no more line number references
- `last_updated_at`: Required timestamp
- `suggested_inputs`: Optional field for fields to populate later
- **REMOVED:** `git_setup`, `tech_spec_lines`, `data_schema_lines`

```json
{
  "schema_version": "2.0",
  "id": "PROJECT-100",
  "type": "epic",
  "phase": "phase-1",
  "project": "project-name",
  "priority": "P1",
  "goal": "One-line goal statement that describes what this epic achieves",
  "test_criteria": "How to verify the epic is complete (specific testable statement)",

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

  // UX Flows Integration (optional — omit for non-UI epics)
  "ux_flows_ref": "planning/[app]/UX_FLOWS.md",    // Path to UX Flows doc for this project
  "journeys": ["J1", "J3"],                         // Journey IDs from UX Flows this epic covers
  "screens": ["SCR-01", "SCR-04"],                   // Screen IDs from UX Flows this epic touches
  "design_scope": "full_design",                     // full_design | design_update | no_design
  "design_phase_complete": false,                    // Set true after Phase A (Design) completes; auto-true for no_design

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
    },
    {
      "id": "AC2",
      "title": "Second criterion",
      "given": "...",
      "when": "...",
      "then": "...",
      "verify": "..."
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
        "Task: Task 2 description",
        "Task: Task 3 description"
      ]
    },
    {
      "id": "PROJECT-102",
      "claude_task_id": "4",
      "title": "Story: Second story",
      "description": "...",
      "points": 3,
      "hours": 4,
      "tasks": ["Task: ..."]
    }
  ],

  "risks": [
    {
      "id": "R1",
      "description": "Risk description",
      "probability": "medium",
      "impact": "high",
      "mitigation": "Mitigation strategy"
    },
    {
      "id": "R2",
      "description": "...",
      "probability": "low",
      "impact": "medium",
      "mitigation": "..."
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
      },
      {
        "phase": "execution-2",
        "intent": "UI layer",
        "stories": ["PROJECT-103"],
        "deliverables": ["Main views implemented"]
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

## Validation Checklist (v2.0)

**Before creating the epic, verify ALL of these:**

### Identification (5 checks)
- [ ] `schema_version` is "2.0"
- [ ] `id` follows PROJECT-X00 format (e.g., MYAPP-100)
- [ ] `type` is "epic"
- [ ] `phase` matches IMPLEMENTATION_GUIDE phase (e.g., "phase-1")
- [ ] `project` matches project code (e.g., "myapp")

### Description (3 checks)
- [ ] Has Problem Statement with When/As/I want/So that/But currently
- [ ] Has Solution section (1-3 sentences)
- [ ] Has Outcome section with concrete deliverables

### Planning Doc References (2 checks)
- [ ] `references` object has section anchors (NOT line numbers)
- [ ] `references.notes` explains the approach

### Sizing (4 checks)
- [ ] `estimate.primary_unit` is "points", "hours", or "days"
- [ ] `estimate.value` is a reasonable number
- [ ] `story_count` matches stories array length
- [ ] `complexity` is S/M/L/XL

### Success Metrics (2 checks)
- [ ] At least 3 primary metrics
- [ ] At least 2 secondary metrics

### Acceptance Criteria (3 checks)
- [ ] At least 5 acceptance criteria
- [ ] Each has id, title, given, when, then, verify
- [ ] Given/When/Then are specific, not vague

### Stories (4 checks)
- [ ] At least 3 stories
- [ ] Each story has id in PROJECT-1XX format
- [ ] Each story has points and hours
- [ ] Each story has at least 3 tasks

### Risks (3 checks)
- [ ] At least 3 risks identified
- [ ] Each has probability and impact
- [ ] Each has mitigation strategy

### Execution Plan (3 checks)
- [ ] `execution_plan.shape` defined
- [ ] `execution_plan.phases` array with at least 1 phase
- [ ] `execution_plan.notes` explains AI sequencing approach

### Definition of Done (4 checks)
- [ ] `definition_of_done.purpose` explains why
- [ ] `definition_of_done.completion_gates` has at least 4 items
- [ ] `definition_of_done.quality_gates_source` references repo location
- [ ] `definition_of_done.generation_hints` has at least 2 items

### Workflow Fields (5 checks)
- [ ] `approval` is "pending" (initial state)
- [ ] `blocked` is false (unless dependencies unmet)
- [ ] If `blocked` is true: `blockedBy` array contains the Claude task IDs of blocking items AND `dependencies.internal` lists the epic display IDs (e.g., `["PROJECT-700"]`)
- [ ] `review_stage` is null (initial state)
- [ ] `review_result` is null (initial state)

### Git & Labels (3 checks)
- [ ] Branch name follows epic/PROJECT-XXX-description format
- [ ] `base_branch` is set (default: "main"; set to parent epic branch if building on uncommitted work)
- [ ] Labels contain only categorization tags (no workflow state)

### Timestamps (2 checks)
- [ ] `created_at` is valid ISO 8601
- [ ] `last_updated_at` is valid ISO 8601

---

## Minimum Requirements Summary

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
| `labels` | 0 (categorization tags only) |

---

## Priority Guidelines

| Priority | Meaning | When to Use |
|----------|---------|-------------|
| P0 | Critical blocker | Drop everything, business-critical |
| P1 | Must have | Required for current milestone |
| P2 | Should have | Default priority, important but not urgent |
| P3 | Nice to have | Can be deferred if needed |
| P4 | Backlog | Someday/maybe, future consideration |

---

## TaskCreate Usage (v2.0)

```typescript
await TaskCreate({
  subject: "Epic: PROJECT-100 - Foundation & Core Data Setup",
  description: `## Problem Statement
When building a new macOS application,
As a developer, I want a solid foundation with Core Data persistence,
So that user data is stored reliably from the start,
But currently there is no project structure or data layer.

## Solution
Build the core infrastructure with Core Data stack,
MVVM architecture, and seeded default data.

## Outcome to be Achieved
After completing this epic, the development team will have a working
Core Data stack with all entities created and default data seeded.`,
  activeForm: "Building foundation infrastructure",
  metadata: {
    schema_version: "2.0",
    id: "PROJECT-100",
    type: "epic",
    phase: "phase-1",
    project: "project-name",
    priority: "P1",
    goal: "Establish Core Data foundation",
    test_criteria: "All entities created, CRUD operations working",
    created_at: "2026-01-30T10:00:00Z",
    created_by: "claude",
    planned_by: "claude",
    last_updated_at: "2026-01-30T10:00:00Z",
    story_count: 3,
    complexity: "L",
    risk_level: "medium",
    sprint: 1,
    estimate: {
      primary_unit: "points",
      value: 21,
      notes: "Use story points as the primary estimate."
    },
    approval: "pending",
    blocked: false,
    review_stage: null,
    review_result: null,
    labels: ["infrastructure", "phase-1"],
    branch: "epic/PROJECT-100-foundation",
    base_branch: "main",
    ux_flows_ref: "planning/project-name/UX_FLOWS.md",
    journeys: ["J1", "J3"],
    screens: ["SCR-01", "SCR-04"],
    design_scope: "full_design",
    design_phase_complete: false,
    references: {
      prd_stories: ["O1", "X1"],
      tech_spec_sections: ["Architecture", "Data Models"],
      data_schema_sections: ["Entities"],
      notes: "Prefer stable section anchors over line numbers."
    },
    external_deps: ["macOS 26.0+"],
    blocks_epics: ["PROJECT-200"],
    dependencies: {
      external: [{ name: "Alamofire", version: "5.x", purpose: "Networking" }],
      internal: [],
      blocks_epics: ["PROJECT-200"]
    },
    success_metrics: {
      primary: ["Core Data stack initializes", "All entities created", "CRUD working"],
      secondary: ["Performance acceptable", "Memory efficient"]
    },
    acceptance_criteria: [
      { id: "AC1", title: "Core Data init", given: "App launches", when: "Init completes", then: "Store ready", verify: "Unit test" },
      { id: "AC2", title: "...", given: "...", when: "...", then: "...", verify: "..." },
      { id: "AC3", title: "...", given: "...", when: "...", then: "...", verify: "..." },
      { id: "AC4", title: "...", given: "...", when: "...", then: "...", verify: "..." },
      { id: "AC5", title: "...", given: "...", when: "...", then: "...", verify: "..." }
    ],
    stories: [
      { id: "PROJECT-101", task_id: "3", title: "Story: Core Data Setup", description: "...", points: 5, hours: 6, tasks: ["Task: A", "Task: B", "Task: C"] },
      { id: "PROJECT-102", task_id: "4", title: "Story: ...", description: "...", points: 3, hours: 4, tasks: ["Task: A", "Task: B", "Task: C"] },
      { id: "PROJECT-103", task_id: "5", title: "Story: ...", description: "...", points: 5, hours: 6, tasks: ["Task: A", "Task: B", "Task: C"] }
    ],
    risks: [
      { id: "R1", description: "Migration complexity", probability: "medium", impact: "high", mitigation: "Use lightweight migration" },
      { id: "R2", description: "...", probability: "low", impact: "medium", mitigation: "..." },
      { id: "R3", description: "...", probability: "low", impact: "low", mitigation: "..." }
    ],
    execution_plan: {
      shape: "precedence_phases",
      phases: [
        { phase: "execution-1", intent: "Core infrastructure", stories: ["PROJECT-101"], deliverables: ["Core Data working"] },
        { phase: "execution-2", intent: "Remaining features", stories: ["PROJECT-102", "PROJECT-103"], deliverables: ["All features"] }
      ],
      notes: "AI-oriented sequencing: precedence-driven phases."
    },
    out_of_scope: ["iCloud sync", "Multi-window", "Export/import"],
    definition_of_done: {
      purpose: "Stop condition for AI + humans.",
      completion_gates: ["All AC pass", "E2E flow works", "Out of scope items not implemented", "No P0/P1 bugs"],
      quality_gates_source: "CLAUDE.md#quality-gates",
      generation_hints: ["Derive checklist from AC", "Require evidence per story"]
    },
    suggested_inputs: [],
    comments: [],
    restored_from: null,
    original_task_id: null
  }
});
```

---

## Anti-Patterns

| DO NOT | DO INSTEAD |
|--------|------------|
| Create epics for small, single-task work | Use task or story type |
| Use vague objectives like "Improve the app" | Be specific: "Reduce launch time to <2s" |
| Skip out-of-scope section | Always define boundaries |
| Use unmeasurable success metrics | Make metrics specific and verifiable |
| Use simple string array for definition_of_done | Use structured object with purpose, completion_gates, quality_gates_source, generation_hints |
| Use fewer than 5 acceptance criteria | Expand to cover all behaviors |
| Skip Given/When/Then/Verify format | Always use structured AC |
| Include `git_setup` object | REMOVED in v2.0 - git commands are standard |
| Include `timeline` array with calendar days | Use `execution_plan` with precedence phases |
| Include `tech_spec_lines` or `data_schema_lines` | Use section anchors in `references` instead |
| Include `estimated_hours`, `estimated_days`, `size` | Use unified `estimate` object |
| Create without reading templates first | Read metadata-schema.md first |
| Skip PM and Staff Engineer review | Complete both reviews |

---

## v2.0 Migration Notes

If converting a v1.0 epic to v2.0:

### Remove These Fields
- `git_setup`
- `tech_spec_lines`
- `data_schema_lines`
- `estimated_hours`
- `estimated_days`
- `size`
- `timeline`
- `prd_stories` (move to `references.prd_stories`)
- `tech_spec_sections` (move to `references.tech_spec_sections`)

### Add These Fields
- `schema_version: "2.0"`
- `last_updated_at`
- `estimate` object
- `execution_plan` object
- `definition_of_done` as structured object
- `suggested_inputs` array (can be empty)

### Transform These Fields
- `definition_of_done` from string array to structured object
- `timeline` calendar days to `execution_plan` precedence phases

---

## Comments System

Epics include a `comments` array for agent communication:

```json
{
  "comments": [
    {
      "id": "C1",
      "timestamp": "2026-01-30T10:15:00Z",
      "author": "pm-agent",
      "type": "question",
      "content": "What are the data retention requirements?",
      "resolved": true,
      "resolved_by": "human",
      "resolved_at": "2026-01-30T10:17:00Z"
    }
  ]
}
```

**Comment Types:** question, decision, blocker, note, review, planning

**Comment Authors:** pm-agent, staff-engineer-agent, qa-agent, macos-developer-agent, planning-agent, human

---

## Cross-References

- **Metadata Schema:** `.claude/templates/tasks/metadata-schema.md`
- **Progress Tracking:** `.claude/templates/tasks/progress.md`
- **Story Template:** `.claude/templates/tasks/story.md`
- **Task Template:** `.claude/templates/tasks/task.md`
- **/epic Command:** `.claude/commands/epic.md`
