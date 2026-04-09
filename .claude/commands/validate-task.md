---
disable-model-invocation: true
description: Validate task metadata against schema v2.0. Returns structured PASS/FAIL report. Use --tree to validate entire epic hierarchy.
argument-hint: <task-id> [--tree]
---

# Validate Task Command

Validate an epic, story, task, bug, or techdebt against the v2.0 metadata schema. Returns a structured PASS/FAIL report. Optionally validates an entire tree (epic + all children).

## Usage

```
/validate-task <id> [--tree]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<id>` | Yes | Claude Tasks ID of the epic, story, task, bug, or techdebt to validate |
| `--tree` | No | If target is an epic, also validate all child stories and tasks. If target is a story, also validate all child tasks. |

## Description

This command reads a task via `TaskGet`, determines its type from `metadata.type`, then runs the matching validation checklist from `.claude/skills/workflow/validate-task/SKILL.md`. It checks every required field, minimum counts, prohibited fields, and workflow state validity.

## Agent Instructions

When `/validate-task` is invoked:

### Step 1: Load Validation Rules

Read the validation skill and schema:
- `.claude/skills/workflow/validate-task/SKILL.md` (validation checklists)
- `.claude/templates/tasks/metadata-schema.md` (prohibited fields, valid values)

### Step 2: Fetch the Target

```
TaskGet { id: "<id>" }
```

Determine the type from `metadata.type` ("epic", "story", "task", "bug", or "techdebt").

### Step 3: Run Validation Checks

For the target item, run ALL checks from the matching checklist in the skill file. Track each check as PASS or FAIL with details.

#### Checks for ALL Types

**Prohibited fields:**
- FAIL if `metadata.status` exists (status is top-level only)
- FAIL if `metadata.labels` contains workflow state values (e.g., `awaiting:*`, `rejected:*`, `approved`, `blocked`)

**Required fields:**
- FAIL if `metadata.schema_version` is missing or not `"2.0"`
- FAIL if `metadata.approval` is missing or not in `["pending", "approved"]`
- FAIL if `metadata.blocked` is missing or not in `[true, false]`
- FAIL if `metadata.last_updated_at` is missing or not ISO8601

**Subject format:**
- Epic: must start with `Epic: `
- Story: must start with `Story: `
- Task: must start with `Task: `
- Bug: must start with `Bug: `
- TechDebt: must start with `TechDebt: `

#### Epic-Specific Checks

- `review_stage` present (can be `null`)
- `review_result` present (can be `null`)
- `estimate` object with `primary_unit`, `value`, `notes`
- `execution_plan` object with `shape`, `phases[]`, `notes`
- `definition_of_done` object with `purpose`, `completion_gates` (min 4), `quality_gates_source`, `generation_hints` (min 2)
- `acceptance_criteria` array (min 5), each with `id`, `title`, `given`, `when`, `then`, `verify`
- `success_metrics.primary` (min 3), `success_metrics.secondary` (min 2)
- `risks` array (min 3), each with `id`, `description`, `probability`, `impact`, `mitigation`
- `stories` or `stories_outline` array (min 3)
- `out_of_scope` array (min 3)
- `labels` array (min 2 categorization tags)
- Description has `## Problem Statement`, `## Solution`, `## Outcome to be Achieved`

#### Story-Specific Checks

- `epic_id` present
- `review_stage` present (can be `null`)
- `review_result` present (can be `null`)
- `acceptance_criteria` array (min 3) with Given/When/Then/Verify
- `out_of_scope` array (min 3)
- `definition_of_done` object with `completion_gates` (min 2), `generation_hints` (min 1)
- Description has `## Summary`, `## User Story`, `## Context`, `## Technical Approach`, `## Dependencies`

#### Task-Specific Checks

- `story_id` present
- NO `review_stage` or `review_result` fields (tasks don't have these)
- `local_checks` array (min 3) — FAIL if `acceptance_criteria` used instead
- `checklist` array (min 2) — FAIL if `subtasks` used instead
- `completion_signal` string present
- `validation_hint` string present — FAIL if `verify` used instead
- `files` array (min 1)
- Description has `## What`, `## Why`, `## How`

#### Bug-Specific Checks

- `severity` present and valid (`"critical"`, `"major"`, `"moderate"`, `"minor"`)
- `priority` present and matches severity mapping (critical→P0, major→P1, moderate→P2, minor→P3)
- `rca_status` present and valid (`"pending"`, `"investigated"`, `"needs-more-info"`, `"reviewed"`, `"approved"`)
- `review_stage` present (can be `null`)
- `review_result` present (can be `null`)
- `found_in` present (string or null)
- `environment` present and valid (`"dev"`, `"staging"`, `"production"`)
- `steps_to_reproduce` array (min 1)
- `expected_behavior` string present
- `actual_behavior` string present
- `hours_estimated` present (number or null)
- `hours_actual` present (number or null)
- Description has `## Bug Report` section

#### TechDebt-Specific Checks

- `debt_type` present and valid (`"architectural"`, `"quality"`, `"test-coverage"`, `"dependency"`, `"performance"`, `"documentation"`)
- `debt_category` present and specific (not just "other")
- `discovered_by` present and valid (`"techdebt-scan"`, `"code-review"`, `"incident"`, `"developer"`, `"qa"`)
- `discovered_at` present and ISO8601
- `files_affected` array (min 1)
- `regression_risk` present and valid (`"low"`, `"medium"`, `"high"`)
- `compounding` present (boolean)
- `impact_if_deferred` string present
- `business_justification` string present
- `hours_estimated` present (0.5-4, split if larger)
- `checklist` array (min 2)
- `local_checks` array (min 3)
- `completion_signal` string present
- `validation_hint` string present
- `review_stage` present (can be `null`)
- `review_result` present (can be `null`)
- `labels` must include `"tech-debt"`
- Description has `## Current State`, `## Desired State`, `## Why Now`, `## Regression Risk`

### Step 4: Tree Validation (if --tree)

If `--tree` is specified:

1. If target is an **epic**: use `TaskList` to find all items where `metadata.parent == <epic-task-id>` (stories), then find all items where `metadata.parent` matches any story task ID (tasks). Validate each.

2. If target is a **story**: use `TaskList` to find all items where `metadata.parent == <story-task-id>` (tasks). Validate each.

3. Also check **cross-item consistency**:
   - Parent-child approval alignment (parent approved = all children approved)
   - Story count in epic matches actual story count
   - Task references in story match actual tasks

### Step 5: Generate Report

```
Schema Validation Report
========================

Target: [Epic|Story|Task]: [subject] (id: [id])
Mode: [Single item | Tree (N items)]
Result: [PASS | FAIL (X issues)]

---
disable-model-invocation: true

CHECKS PASSED (N):
  [x] schema_version is "2.0"
  [x] approval field present and valid ("pending")
  [x] blocked field present and valid (false)
  [x] No prohibited metadata.status field
  [x] Labels contain no workflow state
  [x] review_stage present (null)
  [x] review_result present (null)
  [x] estimate object valid
  [x] execution_plan valid with 3 phases
  [x] acceptance_criteria: 8 items (min 5)
  [x] risks: 4 items (min 3)
  [x] stories_outline: 4 items (min 3)
  [x] out_of_scope: 6 items (min 3)
  [x] definition_of_done valid with 5 gates
  [x] success_metrics: 4 primary, 3 secondary
  [x] Subject starts with "Epic: "
  [x] Description has Problem/Solution/Outcome sections
  ...

CHECKS FAILED (X):
  [ ] metadata.status found ("ready") — PROHIBITED, remove this field
  [ ] labels contain "awaiting:approval" — workflow state in labels is prohibited
  [ ] acceptance_criteria missing "verify" on AC3
  ...

---
disable-model-invocation: true

TREE RESULTS (if --tree):
  Epic: CASHFLOW-200 — PASS (0 issues)
  Story: CASHFLOW-201 — PASS (0 issues)
  Story: CASHFLOW-202 — FAIL (1 issue)
    [ ] missing epic_id field
  Story: CASHFLOW-203 — PASS (0 issues)
  Story: CASHFLOW-204 — PASS (0 issues)
  Task: Create AppState class — PASS (0 issues)
  Task: Build SidebarView — FAIL (2 issues)
    [ ] local_checks has 2 items (min 3)
    [ ] missing completion_signal

Cross-Item Checks:
  [x] All children match parent approval state
  [x] Story count matches (4 stories, epic says 4)
  [ ] Story CASHFLOW-202 tasks array is empty — update after creating tasks

---
disable-model-invocation: true

Summary: 18 items validated, 2 failed, 16 passed
Required fixes: 3 (see CHECKS FAILED above)
```

## Examples

### Validate a Single Epic
```
/validate-task 31
```

### Validate Epic and All Children
```
/validate-task 31 --tree
```

### Validate a Single Story
```
/validate-task 45
```

### Validate a Story and Its Tasks
```
/validate-task 45 --tree
```

### Validate a Bug
```
/validate-task 52
```

### Validate a TechDebt Item
```
/validate-task 60
```

## When to Run

| Situation | Command |
|-----------|---------|
| After `/epic` creates an epic | `/validate-task <epic-id>` |
| After `/write-stories-and-tasks` | `/validate-task <epic-id> --tree` |
| After `/hydrate` restores from backup | `/validate-task <epic-id> --tree` |
| Before `/approve-epic` | `/validate-task <epic-id> --tree` |
| After `/bug` creates a bug | `/validate-task <bug-id>` |
| Spot-checking a single item | `/validate-task <id>` |

## Related Commands

| Command | Relationship |
|---------|-------------|
| `/workflow-audit` | Checks workflow **state consistency** (field coupling, comment/field mismatch). Validate-task checks **schema compliance**. |
| `/validate-task` | Checks **metadata structure** (required fields, minimums, prohibited fields). Complementary to workflow-audit. |

## Related Documentation

- `.claude/skills/workflow/validate-task/SKILL.md` - Validation checklists
- `.claude/templates/tasks/metadata-schema.md` - Complete schema with prohibited fields
- `.claude/templates/tasks/epic.md` - Epic template
- `.claude/templates/tasks/story.md` - Story template
- `.claude/templates/tasks/task.md` - Task template
- `.claude/templates/tasks/bug.md` - Bug template
- `.claude/templates/tasks/techdebt.md` - TechDebt template
