# Task Planning Rule

## When This Applies
When creating tasks using TaskCreate during planning phases.

## Task Type Hierarchy

```
Epic (top-level initiative)
  Story (phase/component)
    Task (actual work item)
```

**Critical:** Phases are `type: "story"`, NOT `type: "epic"`.

- **Epic**: Top-level initiative (e.g., "Infrastructure: Migrate to Production")
- **Story**: A phase or component under an epic (e.g., "Phase 1: Database Setup")
- **Task**: Actual work item under a story (e.g., "Create tables")

## Requirements

### All Items MUST Have:
1. **Descriptive title** following template format
2. **Description** - NEVER omit this
3. **Appropriate type**: epic, story, task, bug, techdebt
4. **Priority**: P0-P4 (in metadata)
5. **Schema version**: `schema_version: "2.0"` in metadata
6. **Workflow fields**: `approval`, `blocked` in metadata

### Stories MUST Also Have:
7. **Parent ID** - points to epic
8. **`epic_id`** - quick reference to parent epic in metadata
9. **Review fields**: `review_stage`, `review_result` in metadata

### Tasks MUST Also Have:
7. **Parent ID** - points to story
8. **`local_checks`** - at least 3 verification checks (replaces `acceptance_criteria`)
9. **`checklist`** - at least 2 granular steps (replaces `subtasks`)
10. **`completion_signal`** - when is this task done

### Task Tiers

Tasks have two tiers. The planning agent assigns tier during breakdown.

**Standard tasks** (default): Full v2.0 schema. Use for tasks touching 2+ files, requiring design decisions, or needing execution hints.

**Micro tasks** (`task_tier: "micro"`): Minimal schema. Use for single-file changes, simple additions, or tasks where the description IS the implementation plan. Micro tasks require only: `schema_version`, `type`, `priority`, `approval`, `blocked`, `local_checks` (min 2), `completion_signal`, `comments`. They skip: `ai_execution_hints`, `ai_context`, `implementation_constraints`, `definition_of_done`, `checklist`, `validation_hint`.

### Template Usage
Before creating any task, read the appropriate template:
- Epic: `.claude/templates/tasks/epic.md`
- Story: `.claude/templates/tasks/story.md`
- Task: `.claude/templates/tasks/task.md`
- Bug: `.claude/templates/tasks/bug.md`
- TechDebt: `.claude/templates/tasks/techdebt.md`

## Validation Checklist

Before using TaskCreate, verify:
- [ ] `schema_version: "2.0"` is set in metadata
- [ ] Correct type: epic (top), story (phase), task (work)
- [ ] Title follows template format
- [ ] Description has all required sections
- [ ] `approval: "pending"` is set (human must approve before work starts)
- [ ] `blocked: false` is set (or `true` with `blockedBy` references)
- [ ] Parent is set (for stories -> epic, tasks -> story)
- [ ] Priority is justified
- [ ] Tasks have `local_checks` (min 3), `checklist` (min 2), `completion_signal`
- [ ] Stories/Epics have `review_stage: null`, `review_result: null`
- [ ] Labels contain only categorization tags (not workflow state)

## Anti-Patterns (DO NOT)

X TaskCreate with type: "epic" for a phase
  Wrong type: phases should be type: "story"

X TaskCreate with only title and type
  Missing: description, schema_version, workflow fields, parent

X TaskCreate with vague title and minimal description
  Too vague: title unclear, description lacks structure

X Using labels for workflow state (e.g., `labels: ["awaiting:qa"]`)
  Wrong: use `review_stage` and `review_result` fields instead

## Correct Patterns

Epic (top-level):
```
TaskCreate: {
  title: "Epic: [Name]",
  type: "epic",
  description: "## Objective\n[description]\n\n## Success Criteria\n...",
  metadata: {
    schema_version: "2.0",
    type: "epic",
    priority: "P1",
    approval: "pending",
    blocked: false,
    review_stage: null,
    review_result: null,
    execution_plan: "[AI-oriented sequencing]",
    estimate: { primary_unit: "points", value: 21, notes: "..." },
    definition_of_done: {
      completion_gates: ["Gate 1", "Gate 2"],
      quality_gates_source: "CLAUDE.md#quality-gates"
    },
    labels: [],
    comments: []
  }
}
```

Story (phase under epic):
```
TaskCreate: {
  title: "Story: [Name]",
  type: "story",
  description: "[description]",
  parentId: "<epic-id>",
  metadata: {
    schema_version: "2.0",
    type: "story",
    epic_id: "<epic-logical-id>",
    priority: "P2",
    approval: "pending",
    blocked: false,
    review_stage: null,
    review_result: null,
    labels: [],
    comments: []
  }
}
```

Task (work under story):
```
TaskCreate: {
  title: "Task: [Task name]",
  type: "task",
  description: "[what/why/how]",
  parentId: "<story-id>",
  metadata: {
    schema_version: "2.0",
    type: "task",
    priority: "P2",
    approval: "pending",
    blocked: false,
    local_checks: [
      "Check 1 - specific and testable",
      "Check 2 - specific and testable",
      "Check 3 - specific and testable"
    ],
    checklist: [
      "Step 1",
      "Step 2"
    ],
    validation_hint: "How to verify this task",
    completion_signal: "When is this task done",
    labels: [],
    comments: []
  }
}
```

Micro Task (single-file, simple work):
```
TaskCreate: {
  title: "Task: Add accessibility label to save button",
  type: "task",
  description: "## What\nAdd .accessibilityLabel to Save button in AccountDetailView.\n\n## Why\nVoiceOver cannot identify the button.",
  parentId: "<story-id>",
  metadata: {
    schema_version: "2.0",
    type: "task",
    task_tier: "micro",
    priority: "P3",
    approval: "pending",
    blocked: false,
    local_checks: [
      "Save button has .accessibilityLabel(\"Save account changes\")",
      "VoiceOver reads the label correctly in Accessibility Inspector"
    ],
    completion_signal: "Build succeeds and label verified in preview",
    labels: [],
    comments: []
  }
}
```

## Workflow Reminder

1. Read template first
2. Draft description with all sections
3. Write specific local_checks (for tasks, min 3)
4. Determine correct parent (story -> epic, task -> story)
5. Include all v2.0 schema fields (schema_version, approval, blocked, etc.)
6. Use TaskCreate with all required fields
7. Verify with TaskGet after creation
