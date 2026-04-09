---
name: claude-tasks
description: "Claude Code's built-in task management system. Provides persistent memory via TaskCreate, TaskUpdate, TaskGet, TaskList tools with hierarchical organization and dedicated workflow state fields."
---

# Claude Code Tasks Skill

Claude Code Tasks is the built-in task management system using Claude's native tools. It provides persistent memory across sessions with a three-level hierarchy: Epic > Story > Task.

## Tool Reference

### TaskCreate
Creates a new epic, story, or task. Requires `title`, `type`, `description`, and `metadata` with `schema_version: "2.0"`, `approval`, `blocked`, and type-appropriate workflow fields. Stories and epics also need `review_stage` and `review_result`.

### TaskUpdate
Updates any field on an existing task. Always call `TaskGet` first to read current metadata before writing — `metadata.comments` is append-only and will be overwritten if you do not spread the existing array.

### TaskGet
Retrieves a single task by ID. Returns all fields including `metadata.approval`, `metadata.review_stage`, `metadata.review_result`, `metadata.comments`, `blockedBy`, and `blocks`. Use before every `TaskUpdate`.

### TaskList
Finds tasks matching filter criteria. Common filters: `{ approval: "approved", status: "pending" }` for available work; `{ review_stage: "code-review", review_result: "awaiting" }` for review queues; `{ review_result: "rejected" }` for items needing fixes.

## Type Hierarchy

```
Epic  (type: "epic")   — top-level initiative
  Story (type: "story") — phase or component under epic
    Task  (type: "task")  — individual work item under story
```

Stories are `type: "story"`, NOT `type: "epic"`.

## See Also

- **Workflow state fields and review cycle:** see skill `agent-shared-context`
- **Comment templates by stage:** see skill `review-cycle`
- **v2.0 schema field reference:** see `.claude/templates/tasks/metadata-schema.md`
- **Task state protocols (claim, complete, advance, unblock):** see `.claude/rules/global/task-state-updates.md`
- **Full planning rules and TaskCreate patterns:** see `.claude/rules/workflow/task-planning.md`
- **Full how-to:** see `.claude/HOW-TO.md`
