---
name: workflow-state
description: "How to transition workflow state between review stages. Rules for setting review_stage and review_result fields on Stories and Epics."
disable-model-invocation: true
allowed-tools: [TaskGet, TaskUpdate]
---

# Workflow State Transitions

## How to Transition

Set `review_stage` and `review_result` directly in the same `TaskUpdate` call. No helper function needed. Always include a structured comment in the same call.

```
Submit for code review:   review_stage: "code-review",    review_result: "awaiting"
Pass code review:         review_stage: "qa",              review_result: "awaiting"
Fail code review:         review_stage: "code-review",     review_result: "rejected"
Pass QA:                  review_stage: "product-review",  review_result: "awaiting"
Fail QA:                  review_stage: "qa",              review_result: "rejected"
Pass product review:      review_stage: null,              review_result: null  (+ status: "completed")
Fail product review:      review_stage: "product-review",  review_result: "rejected"
Fix and resubmit:         review_stage: "code-review",     review_result: "awaiting"
```

## Key Rules

1. **Any rejection restarts at code-review.** After fixing, always set `review_stage: "code-review"`, regardless of which stage rejected.

2. **Both fields must be set together.** `review_stage` and `review_result` are always paired. Never set one without the other.

3. **Tasks never get review fields.** Only Stories and Epics go through the review cycle. Tasks complete directly.

4. **Read before write.** Always call `TaskGet` before `TaskUpdate` to preserve the existing `comments` array.

5. **Every transition requires a comment.** Include a structured comment in the same `TaskUpdate` call.

## Consistency Rules

```
VALID:    review_stage: "qa",    review_result: "awaiting"
VALID:    review_stage: null,    review_result: null
INVALID:  review_stage: "qa",    review_result: null    (unpaired)
INVALID:  review_stage: null,    review_result: "awaiting"  (unpaired)
```

## See Also

- Complete state machine, field definitions, lifecycle diagrams: `.claude/docs/WORKFLOW-STATE.md`
- Comment templates by stage: skill `review-cycle`
- Protocol details (read-before-write, comment format): `.claude/rules/global/task-state-updates.md`
