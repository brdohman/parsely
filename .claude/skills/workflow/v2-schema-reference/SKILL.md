---
name: v2-schema-reference
description: Canonical v2.0 metadata schema field reference for epics, stories, and tasks. Use when creating or validating task metadata.
user-invocable: false
---

# v2.0 Schema Field Reference

For complete schema details, read `.claude/templates/tasks/metadata-schema.md`.

## Task Fields (type: "task")

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `schema_version` | `"2.0"` | YES | Schema version |
| `type` | `"task"` | YES | Item type |
| `parent` | string | YES | Parent story task ID |
| `task_id` | string | YES | Logical ID (e.g., PROJECT-101-1) |
| `story_id` | string | YES | Parent story logical ID |
| `priority` | string | YES | `"P0"`–`"P4"` |
| `approval` | string | YES | `"pending"` or `"approved"` |
| `blocked` | boolean | YES | `true` or `false` |
| `local_checks` | string[] | YES (min 3) | Verification criteria |
| `checklist` | string[] | YES (min 2) | Implementation steps |
| `completion_signal` | string | YES | When is this task done |
| `validation_hint` | string | YES | Quick verification method |
| `ai_execution_hints` | string[] | NO | Guidance for AI agents |
| `files` | string[] | NO | Expected file paths |
| `hours_estimated` | number | NO | Estimated hours |
| `comments` | object[] | YES | Structured comment array |
| `last_updated_at` | string | YES | ISO8601 timestamp |

**Tasks do NOT have:** `review_stage`, `review_result`, `definition_of_done`, `acceptance_criteria`, `subtasks`, `verify`

## Story Fields (type: "story")

Key fields beyond task fields: `epic_id`, `acceptance_criteria` (Given/When/Then/Verify array), `ai_context`, `implementation_constraints`, `definition_of_done` (structured object), `review_stage`, `review_result`, `out_of_scope`.

## Epic Fields (type: "epic")

Key fields beyond story fields: `execution_plan` (precedence phases), `estimate` (primary_unit/value/notes), `success_metrics`, `risks`, `stories` (outline array), `suggested_inputs`, `references`.

**Removed in v2.0:** `git_setup`, `timeline`, `estimated_hours`, `estimated_days`, `size`, `tech_spec_lines`, `data_schema_lines`
