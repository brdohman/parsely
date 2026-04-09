---
name: plan-tasks
description: "Create epics, stories, and tasks with schema v2.0 compliance. Guidance for breaking epics into stories, stories into tasks. Use during /epic or /write-stories-and-tasks."
allowed-tools: [Read, TaskCreate, TaskUpdate, TaskGet]
---

# Task Planning Rule

## When This Applies
When creating tasks using TaskCreate during planning phases.

**Schema Version:** 2.0 (AI-first schema)

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
1. **schema_version** - Must be `"2.0"`
2. **Descriptive title** following template format (prefix required)
3. **Description** - NEVER omit this
4. **Appropriate type**: epic, story, task, bug, chore
5. **Priority**: P0-P4 (in metadata)
6. **last_updated_at** - ISO8601 timestamp

### Epics MUST Also Have:
- `execution_plan` - AI-oriented sequencing (replaces `timeline`)
- `estimate` - Unified estimate object (replaces `estimated_hours`/`estimated_days`/`size`)
- `acceptance_criteria` - Minimum 5 items (Given/When/Then/Verify format)
- `definition_of_done` - Structured object with `completion_gates` and `generation_hints`

### Stories MUST Also Have:
- **Parent ID** - points to epic
- **epic_id** - Parent epic ID for quick reference
- `acceptance_criteria` - Minimum 3 items (Given/When/Then/Verify format)
- `definition_of_done` - Structured object
- `implementation_constraints` - (Recommended) Technical constraints
- `ai_context` - (Recommended) Context for AI agents

### Tasks MUST Also Have:
- **Parent ID** - points to story
- `local_checks` - Minimum 3 items (replaces `acceptance_criteria`)
- `checklist` - Minimum 2 items (replaces `subtasks`)
- `completion_signal` - When is this task done?
- `validation_hint` - How to verify (replaces `verify`)
- `ai_execution_hints` - (Recommended) Hints for AI execution

**Note:** Tasks do NOT have `definition_of_done` - that is a repo-level quality gate.

### Template Usage
Before creating any task, read the appropriate template:
- Epic: `.claude/templates/tasks/epic.md`
- Story: `.claude/templates/tasks/story.md`
- Task: `.claude/templates/tasks/task.md`
- Metadata Schema: `.claude/templates/tasks/metadata-schema.md`

## Validation Levels

| Level | Behavior | Examples |
|-------|----------|----------|
| **Required** | Must be present and meet minimum counts. Validation fails without them. | `schema_version`, `completion_signal`, `validation_hint`, `local_checks` (min 3), `checklist` (min 2) |
| **Recommended** | Should be present. Agents prompt for these if empty but don't block validation. | `ai_execution_hints`, `implementation_constraints`, `ai_context` |

## Validation Checklist

Before using TaskCreate, verify:
- [ ] `schema_version: "2.0"` is set
- [ ] Correct type: epic (top), story (phase), task (work)
- [ ] Title follows template format with correct prefix
- [ ] Description has all required sections
- [ ] For Tasks: `local_checks` (min 3), `checklist` (min 2), `completion_signal`, `validation_hint`
- [ ] For Stories: `acceptance_criteria` (min 3), `epic_id`, `definition_of_done`
- [ ] For Epics: `acceptance_criteria` (min 5), `execution_plan`, `estimate`, `definition_of_done`
- [ ] Parent is set (for stories -> epic, tasks -> story)
- [ ] Priority is justified (P0-P4)

## Anti-Patterns (DO NOT)

X TaskCreate with type: "epic" for a phase
  Wrong type: phases should be type: "story"

X TaskCreate with only title and type
  Missing: description, required fields, parent

X TaskCreate with vague title and minimal description
  Too vague: title unclear, description lacks structure

X Use old v1.0 field names for tasks
  Wrong: `acceptance_criteria`, `subtasks`, `verify`, `definition_of_done`
  Correct: `local_checks`, `checklist`, `validation_hint` (no DoD on tasks)

X Skip `schema_version`
  All v2.0 items MUST have `schema_version: "2.0"`

## Correct Patterns

### Epic (top-level):
```json
{
  "title": "Epic: PROJECT-100 - [Descriptive Name]",
  "type": "epic",
  "description": "## Problem Statement\n...\n\n## Solution\n...\n\n## Outcome to be Achieved\n...",
  "metadata": {
    "schema_version": "2.0",
    "id": "PROJECT-100",
    "type": "epic",
    "priority": "P1",
    "goal": "One-line goal statement",
    "approval": "pending",
    "blocked": false,
    "review_stage": null,
    "review_result": null,
    "labels": ["infrastructure"],
    "acceptance_criteria": [...],
    "execution_plan": {...},
    "estimate": {...},
    "definition_of_done": {...}
  }
}
```

### Story (phase under epic):
```json
{
  "title": "Story: [Descriptive Name]",
  "type": "story",
  "description": "## Summary\n...\n\n## User Story\nAs a... I want... So that...",
  "parentId": "<epic-task-id>",
  "metadata": {
    "schema_version": "2.0",
    "type": "story",
    "parent": "<epic-task-id>",
    "story_id": "PROJECT-101",
    "epic_id": "PROJECT-100",
    "approval": "pending",
    "blocked": false,
    "review_stage": null,
    "review_result": null,
    "labels": ["phase-1"],
    "acceptance_criteria": [...],
    "definition_of_done": {...}
  }
}
```

### Task (work under story):
```json
{
  "title": "Task: [Action Verb] [Description]",
  "type": "task",
  "description": "## What\n[1-2 sentences]\n\n## Why\n[context]\n\n## How\n[approach]",
  "parentId": "<story-task-id>",
  "metadata": {
    "schema_version": "2.0",
    "type": "task",
    "parent": "<story-task-id>",
    "task_id": "PROJECT-101-1",
    "story_id": "PROJECT-101",
    "approval": "pending",
    "blocked": false,
    "labels": ["implementation"],
    "files": [...],
    "checklist": [...],
    "local_checks": [...],
    "completion_signal": "...",
    "validation_hint": "..."
  }
}
```

## Comment Format

All comments must use the structured format:

```json
{
  "id": "C1",
  "timestamp": "2026-01-30T10:00:00Z",
  "author": "macos-developer-agent",
  "type": "note",
  "content": "Comment text here"
}
```

**Valid comment types:** `question`, `decision`, `blocker`, `note`, `review`, `handoff`, `approval`, `rejection`

**Valid author values:** `pm-agent`, `staff-engineer-agent`, `macos-developer-agent`, `qa-agent`, `security-agent`, `build-engineer-agent`, `designer-agent`, `data-architect-agent`, `planning-agent`, `human`

## Workflow State Fields

Workflow state is tracked in dedicated metadata fields, not labels.

### `approval` Field (All Types)
- `"pending"` - Needs human approval
- `"approved"` - Work can begin

### `blocked` Field (All Types)
- `true` - Blocked by external factor
- `false` - No blockers

### `review_stage` Field (Stories/Epics Only -- NOT Tasks)
- `"code-review"` - Ready for Staff Engineer review
- `"qa"` - Ready for QA testing
- `"security"` - Ready for security review
- `"product-review"` - Ready for PM sign-off
- `null` - Not in review (initial or completed)

### `review_result` Field (Stories/Epics Only -- NOT Tasks)
- `"awaiting"` - Waiting for reviewer
- `"rejected"` - Reviewer found issues
- `null` - Not in review (initial or completed)

### `labels` Field (All Types)
- **Categorization tags only** (e.g., `["infrastructure", "phase-1", "ui"]`)
- No workflow state in labels

## Field Renames in v2.0

For tasks, these fields have been renamed:

| Old Name (v1.0) | New Name (v2.0) | Notes |
|-----------------|-----------------|-------|
| `acceptance_criteria` | `local_checks` | Tasks only; Stories/Epics keep `acceptance_criteria` |
| `subtasks` | `checklist` | Granular steps within task |
| `verify` | `validation_hint` | How to verify completion |
| `definition_of_done` | (removed) | Tasks don't have DoD; it's repo-level |

For epics, these fields have been changed:

| Old Name (v1.0) | New Name (v2.0) | Notes |
|-----------------|-----------------|-------|
| `timeline` | `execution_plan` | AI-oriented sequencing |
| `size`, `estimated_hours`, `estimated_days` | `estimate` | Unified estimate object |
| `git_setup` | (removed) | Git commands are standard |
| `tech_spec_lines`, `data_schema_lines` | `references` | Section anchors, not lines |

## Workflow Reminder

1. Read template and metadata-schema first
2. Ensure `schema_version: "2.0"` is set
3. Draft description with all required sections
4. For Tasks: Write `local_checks` (min 3), `checklist` (min 2), `completion_signal`, `validation_hint`
5. For Stories: Write `acceptance_criteria` (min 3), set `epic_id`, add `definition_of_done`
6. For Epics: Write `acceptance_criteria` (min 5), `execution_plan`, `estimate`, `definition_of_done`
7. Determine correct parent (story -> epic, task -> story)
8. Use TaskCreate with all required fields
9. Verify with TaskGet after creation
