---
disable-model-invocation: true
description: Auto-fix workflow field inconsistencies found by /workflow-audit. Fixes field coupling, stale review states, and missing metadata.
argument-hint: [--all] (fix all issues) or [task-id] (fix specific item)
---

# Workflow Fix Command

Auto-fix workflow field inconsistencies found by `/workflow-audit`.

## Usage

```
/workflow-fix [issue-id]    # Fix specific item
/workflow-fix --all         # Fix all issues found by audit
/workflow-fix --dry-run     # Show what would be fixed without making changes
```

## Description

This command automatically corrects workflow field inconsistencies in the task system. It reads comment history to determine the correct state and sets the metadata fields (`review_stage`, `review_result`, `approval`) directly. No array manipulation needed — just set scalar field values.

## How It Fixes

### Field Coupling Violation
**Issue:** `review_stage` is set but `review_result` is null (or vice versa)
**Fix:** Read latest comment to determine the correct paired values

Example:
- State: `review_stage: "qa", review_result: null`
- Latest comment: "CODE REVIEW PASSED" at 2026-02-01T10:00:00Z
- Result: `review_stage: "qa", review_result: "awaiting"`

### Comment/Field Mismatch
**Issue:** Fields don't match what the latest review comment indicates
**Fix:** Set fields to match the comment's indicated state

Example:
- State: `review_stage: "code-review", review_result: "awaiting"`
- Latest comment: "CODE REVIEW PASSED" at 2026-02-01T10:00:00Z
- Result: `review_stage: "qa", review_result: "awaiting"`

### Completed Items with Active Review Fields
**Issue:** Item has `status: "completed"` but review fields are still set
**Fix:** Clear review fields (set both to null)

Example:
- State: `review_stage: "product-review", review_result: "awaiting"`, status: completed
- Result: `review_stage: null, review_result: null`

### Approval Inconsistencies
**Issue:** Parent approved but child still pending (or vice versa)
**Fix:** Propagate approval from parent to child

Example:
- Parent Story: `approval: "approved"`
- Child Task: `approval: "pending"`
- Result: Child Task `approval: "approved"`

### Invalid Field Values
**Issue:** Field contains a value not in the valid set
**Fix:** Read comments to determine correct value, or flag for manual review

## Fix Process

```
1. Run /workflow-audit internally to identify all issues
2. For each issue:
   a. Read full task with TaskGet
   b. Parse all comments to find latest relevant action
   c. Determine correct field values based on:
      - Comment type (review, fix, implementation)
      - Comment content (PASSED, FAILED, COMPLETE)
      - Comment timestamp
   d. Set corrected field values directly
   e. Add corrective comment documenting the fix
3. Report all fixes made
```

## Comment Analysis Rules

| Comment Content Pattern | Correct Field State |
|------------------------|---------------------|
| "CODE REVIEW PASSED" | `review_stage: "qa", review_result: "awaiting"` |
| "CODE REVIEW REJECTED" | `review_stage: "code-review", review_result: "rejected"` |
| "QA PASSED" | `review_stage: "product-review", review_result: "awaiting"` |
| "QA FAILED" | `review_stage: "qa", review_result: "rejected"` |
| "SECURITY APPROVED" | `review_stage: "product-review", review_result: "awaiting"` |
| "SECURITY REJECTED" | `review_stage: "security", review_result: "rejected"` |
| "PRODUCT REVIEW PASSED" | `review_stage: null, review_result: null` (completed) |
| "PRODUCT REVIEW REJECTED" | `review_stage: "product-review", review_result: "rejected"` |
| "IMPL COMPLETE" / "Ready for code review" | `review_stage: "code-review", review_result: "awaiting"` |
| "Issues addressed" / "Ready for code review" (fix) | `review_stage: "code-review", review_result: "awaiting"` |

## Corrective Comment Format

When fixing fields, add a structured comment documenting the correction:

```json
{
  "id": "WF-[N]",
  "timestamp": "[ISO 8601 timestamp]",
  "author": "workflow-fix",
  "type": "correction",
  "content": "## WORKFLOW CORRECTION\n\n**Issue:** [Description of the inconsistency]\n**Previous state:** approval=[val], review_stage=[val], review_result=[val]\n**Corrected state:** approval=[val], review_stage=[val], review_result=[val]\n**Basis:** [Explanation citing specific comment]",
}
```

## Arguments

| Argument | Description |
|----------|-------------|
| `[issue-id]` | Fix only the specified task/story/epic |
| `--all` | Fix all issues found by workflow-audit |
| `--dry-run` | Show what would be fixed without making changes |

If no argument provided, runs in `--dry-run` mode for safety.

## Output Format

### Dry Run Output

```
Workflow Fix Preview (dry-run):

Would fix 3 issues:

1. Story: Account Management [id: 5]
   Current:  review_stage="code-review", review_result="awaiting"
   Would be: review_stage="qa", review_result="awaiting"
   Basis: CODE REVIEW PASSED comment at 2026-02-01T10:00:00Z

2. Story: User Authentication [id: 8]
   Current:  review_stage="qa", review_result=null
   Would be: review_stage="qa", review_result="awaiting"
   Basis: Field coupling violation — review_result must match review_stage

3. Epic: Cashflow MVP [id: 1]
   Current:  review_stage="product-review", review_result="awaiting" (status: completed)
   Would be: review_stage=null, review_result=null
   Basis: Item is completed — review fields should be cleared

Run /workflow-fix --all to apply these fixes.
```

### Actual Fix Output

```
Workflow Fix Results:

Fixed 3 issues:

1. Story: Account Management [id: 5]
   Before: review_stage="code-review", review_result="awaiting"
   After:  review_stage="qa", review_result="awaiting"
   Basis: CODE REVIEW PASSED comment at 2026-02-01T10:00:00Z

2. Story: User Authentication [id: 8]
   Before: review_stage="qa", review_result=null
   After:  review_stage="qa", review_result="awaiting"
   Basis: Field coupling violation — inferred from review_stage value

3. Epic: Cashflow MVP [id: 1]
   Before: review_stage="product-review", review_result="awaiting"
   After:  review_stage=null, review_result=null
   Basis: Item is completed — review fields cleared

All workflow fields now consistent.
```

### No Issues Output

```
Workflow Fix Results:

No workflow issues found. All items have consistent field state.

Run /workflow-audit for detailed workflow status.
```

## Implementation

```
# Step 1: Run workflow audit to find issues
issues = run_workflow_audit()

if issues.empty:
    output "No workflow issues found"
    return

# Step 2: Filter issues based on arguments
if specific_id:
    issues = issues.filter(id == specific_id)
elif not --all:
    # Default to dry-run
    dry_run = true

# Step 3: Process each issue
for issue in issues:
    task = TaskGet(issue.id)

    # Analyze comments to determine correct field state
    correct_fields = analyze_comments(task.metadata.comments)

    if correct_fields is None:
        output "MANUAL REVIEW REQUIRED for [task.id] — cannot determine state"
        continue

    if dry_run:
        output preview of change
        continue

    # Build corrective comment
    correction_comment = {
        "id": generate_comment_id("WF", task),
        "timestamp": current_iso_timestamp(),
        "author": "workflow-fix",
        "type": "correction",
        "content": format_correction_content(
            issue.description,
            current_fields,
            correct_fields,
            basis
        )
    }

    # Apply fix — just set the fields directly
    TaskUpdate({
        id: issue.id,
        metadata: {
            review_stage: correct_fields.review_stage,
            review_result: correct_fields.review_result,
            approval: correct_fields.approval,  # only if changed
            comments: [...task.metadata.comments, correction_comment]
        }
    })

    output fix result

# Step 4: Summary
output summary of all fixes
```

## Safety Features

1. **Default dry-run**: Running without arguments shows preview only
2. **Comment audit trail**: Every fix is documented with a correction comment
3. **Basis citation**: Each fix cites the specific comment used to determine correct state
4. **No data loss**: Original field values are recorded in the correction comment
5. **Manual review fallback**: Ambiguous cases are flagged rather than auto-fixed

## Edge Cases

### No Comments to Analyze
If an item has field issues but no comments to determine correct state:
- Flag as "MANUAL REVIEW REQUIRED"
- Do not auto-fix
- Output: "Cannot determine correct state — no comment history"

### Ambiguous Comment History
If comments are contradictory or unclear:
- Flag as "MANUAL REVIEW REQUIRED"
- Do not auto-fix
- Output: "Ambiguous comment history — manual review needed"

### Completed Items with Review Fields
If an item is marked completed but still has review fields set:
- Set `review_stage: null, review_result: null`
- Basis: "Item is completed — review fields should be cleared"

### Field Coupling with No Comment Context
If `review_stage` is set but `review_result` is null (with no comments to clarify):
- Default `review_result` to `"awaiting"` (most likely state when stage is set)
- Document the assumption in the correction comment

## Related Commands

- `/workflow-audit` - Find workflow issues (run this first)
- `/status` - Check overall project state
- `/approve-epic` - Approve an epic and all its stories/tasks for implementation

## Example Session

```
User: /workflow-fix --dry-run

Claude: Workflow Fix Preview (dry-run):

Would fix 2 issues:

1. Story: Database Migration [id: 7]
   Current:  review_stage="code-review", review_result="awaiting"
   Would be: review_stage="qa", review_result="awaiting"
   Basis: CODE REVIEW PASSED comment at 2026-02-01T10:00:00Z

2. Story: API Integration [id: 9]
   Current:  review_stage="qa", review_result=null
   Would be: review_stage="qa", review_result="awaiting"
   Basis: Field coupling violation — review_result must match review_stage

Run /workflow-fix --all to apply these fixes.

User: /workflow-fix --all

Claude: Workflow Fix Results:

Fixed 2 issues:

1. Story: Database Migration [id: 7]
   Before: review_stage="code-review", review_result="awaiting"
   After:  review_stage="qa", review_result="awaiting"
   Basis: CODE REVIEW PASSED comment at 2026-02-01T10:00:00Z

2. Story: API Integration [id: 9]
   Before: review_stage="qa", review_result=null
   After:  review_stage="qa", review_result="awaiting"
   Basis: Field coupling violation — inferred from review_stage value

All workflow fields now consistent.
```
