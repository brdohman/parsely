---
name: complete-task
description: "Steps to mark a task completed with required comments, then check parent story advancement. Enforces completion gate: implementation + testing comments required."
disable-model-invocation: true
allowed-tools: [TaskGet, TaskUpdate]
---

# Task Completion

> **Canonical reference:** Protocols 3 and 4 in `.claude/rules/global/task-state-updates.md`. This skill is a quick-reference summary.

## The 3 Steps

### Step 1: Add implementation + testing comments

Before setting `status: "completed"`, verify `metadata.comments` contains BOTH:

| Comment | `type` field | Required |
|---------|-------------|----------|
| What was built, files changed, `local_checks` verified | `"implementation"` | Always |
| Test file, test cases, coverage | `"testing"` | Unless `testable: false` |

If either is missing — HARD STOP. Do not set status to completed.

### Step 2: Set status to completed

In a single `TaskUpdate` call, set `status: "completed"` and include both comments.
Tasks do NOT get `review_stage` or `review_result` — only Stories and Epics use those fields.

### Step 3: Check parent story advancement

After completing a task:
1. Call `TaskGet` on the parent story
2. Check if ALL sibling tasks are `status: "completed"`
3. If yes — submit the story for code review: set `review_stage: "code-review"`, `review_result: "awaiting"`, add a `"handoff"` comment

## See Also

- Protocol 3 (complete with comments): `.claude/rules/global/task-state-updates.md`
- Protocol 4 (parent advancement): `.claude/rules/global/task-state-updates.md`
- Comment format and field reference: skill `agent-shared-context`
