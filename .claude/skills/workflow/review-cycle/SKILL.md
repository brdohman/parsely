---
name: review-cycle
description: Canonical review cycle state machine, transition rules, and comment templates for all workflow stages. Use when advancing workflow state or writing review comments.
user-invocable: false
---

# Review Cycle Reference

## State Machine

> For the complete state machine, field definitions, and lifecycle diagrams, see `.claude/docs/WORKFLOW-STATE.md`.

**Key rule:** ANY rejection at ANY stage → Dev fixes → restart at `code-review` (full cycle restarts).

## Comment Templates by Stage

### STARTING (Dev claiming task)
```
STARTING: [brief plan]. Expected files: [list].
```
Type: `note`

### TASK COMPLETED (Dev finishing task — NO review fields on task)
```
TASK COMPLETE

**Files changed:** [list]
**Checklist completed:** [x] each item
**Local checks verified:** [x] each check
**Completion signal met:** [how]
```
Type: `implementation`

### READY FOR CODE REVIEW (Dev submitting story)
```
READY FOR CODE REVIEW

**Tasks completed:** [x] each task
**All files changed:** [consolidated list]
**Testing done:** [summary]
```
Type: `handoff`

### CODE REVIEW PASSED / QA PASSED / PRODUCT REVIEW PASSED
```
[STAGE] PASSED

**What was checked:** [x] checklist items
**Notes:** [observations]
```
Type: `review`

### REJECTED (any stage)
```
REJECTED - [STAGE]

**Issues found:**
1. **[title]** — Description, expected, actual, severity
**Next action:** Dev to fix and resubmit for code-review.
```
Type: `rejection` (uses trackable format with `resolved`, `resolved_by`, `resolved_at`)

### FIXED AND RESUBMITTED (Dev after rejection)
```
FIXED AND RESUBMITTED

**Issues addressed:**
- [issue]: [how fixed]
**Verification evidence:** [test output, behavior diff]
```
Type: `fix`
