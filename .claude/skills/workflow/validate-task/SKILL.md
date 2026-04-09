---
name: validate-task
description: "Validate task/story/epic/bug/techdebt metadata against schema v2.0. Run after TaskCreate or TaskUpdate to verify compliance. Returns pass/fail with actionable details."
context: fork
disable-model-invocation: true
allowed-tools: [TaskGet, TaskList, Read]
---

# Task Validation

## What This Validates

Schema v2.0 compliance for all task types (epic, story, task, bug, techdebt):
- Required fields present with correct format
- Array minimums met (`local_checks` ≥ 3, `checklist` ≥ 2, `acceptance_criteria` ≥ 3/5)
- Workflow fields valid (`approval`, `blocked`, `review_stage`, `review_result`)
- `schema_version: "2.0"` on all items
- `last_updated_at` present and ISO 8601
- `epic_id` present on stories
- Tasks do NOT have `review_stage`/`review_result`
- Subject format matches type (`Epic: `, `Story: `, `Task: `, `Bug: `, `TechDebt: `)
- v2.0 field names used (not v1.0 aliases: `local_checks` not `acceptance_criteria` on tasks, `checklist` not `subtasks`, `validation_hint` not `verify`, `execution_plan` not `timeline`)
- Parent-child links are bidirectional (story references task IDs; epic references story IDs)

## How to Use

```
/validate-task <id>          # Validate a single item
/validate-task <id> --tree   # Validate an entire epic hierarchy (epic + all stories + all tasks)
```

## Output Format

Return structured PASS/FAIL:
- Overall result
- Per-field status with specific issue if failed
- List of required fixes

Do not return "validation complete" without actionable details.

## References

- For v2.0 field definitions and minimums: see `.claude/templates/tasks/metadata-schema.md`
- For type-specific templates: see `.claude/templates/tasks/epic.md`, `story.md`, `task.md`, `bug.md`, `techdebt.md`
- For workflow field rules: see `.claude/rules/global/task-state-updates.md`
