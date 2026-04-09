---
disable-model-invocation: true
description: Scan all Stories and Epics for workflow state inconsistencies (field coupling, comment/field mismatch). Suggests fixes.
argument-hint: [epic-id] (optional, audits all if omitted)
---

# Workflow Audit Command

Scan all Stories and Epics for workflow state inconsistencies and suggest fixes.

## Usage

```
/workflow-audit [epic-id] [--fix]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `[epic-id]` | No | Audit only items under specific epic |
| `--fix` | No | Auto-fix issues without prompting |

## Description

This command scans all Stories and Epics for workflow field inconsistencies. With dedicated metadata fields (`approval`, `blocked`, `review_stage`, `review_result`), most invalid states from the old label system are now structurally impossible. This audit catches the remaining edge cases that can still occur.

## What It Checks

### 1. Field Coupling Violation (Invalid)
`review_stage` and `review_result` must both be null or both be non-null. If one is set and the other is null, the state is inconsistent.

- Invalid: `review_stage: "code-review", review_result: null`
- Invalid: `review_stage: null, review_result: "rejected"`
- Valid: `review_stage: "qa", review_result: "awaiting"`
- Valid: `review_stage: null, review_result: null`

### 2. Comment/Field Mismatch
The current workflow fields should match what the latest review comment indicates:
- "CODE REVIEW PASSED" should mean `review_stage: "qa"` (not `"code-review"`)
- "QA FAILED" should mean `review_result: "rejected"` (not `"awaiting"`)

### 3. Completed Items with Active Review Fields
Items with `status: "completed"` should have `review_stage: null` and `review_result: null`. A completed item still showing an active review stage is inconsistent.

### 4. Approval Inconsistencies
Parent-child approval must be consistent:
- If a parent (Epic/Story) has `approval: "approved"`, all children should also be `approval: "approved"`
- If a child has `approval: "approved"` but its parent is still `approval: "pending"`, something went wrong

### 5. Invalid Field Values
Fields must contain only valid values:
- `approval`: `"pending"` or `"approved"`
- `blocked`: `true` or `false`
- `review_stage`: `"code-review"`, `"qa"`, `"security"`, `"product-review"`, or `null`
- `review_result`: `"awaiting"`, `"passed"`, `"rejected"`, or `null`

## Workflow Fields Reference

| Field | Type | Valid Values | Applies To |
|-------|------|-------------|------------|
| `approval` | string | `"pending"`, `"approved"` | All (Epic, Story, Task) |
| `blocked` | boolean | `true`, `false` | All (Epic, Story, Task) |
| `review_stage` | string \| null | `"code-review"`, `"qa"`, `"security"`, `"product-review"`, `null` | Story, Epic only |
| `review_result` | string \| null | `"awaiting"`, `"passed"`, `"rejected"`, `null` | Story, Epic only |

**Tasks do NOT have `review_stage` or `review_result`** — they complete directly after implementation.

## Execution Flow

```
1. Get all items via TaskList
2. Filter by epic-id if provided
3. For each item:
   a. Read workflow fields from metadata
   b. Check for inconsistencies (5 checks above)
   c. If issues found, read comments to determine correct state
   d. Generate fix suggestion based on latest comment
4. Report all issues with suggested fixes
5. If --fix flag, apply corrections automatically
```

## Agent Instructions

When `/workflow-audit` is invoked:

### Step 1: Gather All Items

```
TaskList
```

Filter results:
- If `[epic-id]` provided: Only items where `metadata.parent == epic-id` or `id == epic-id`
- Otherwise: All items with `metadata.type` in ["epic", "story"]

### Step 2: Check Each Item

For each item, run these checks:

```python
def audit_item(item):
    issues = []
    meta = item.metadata
    item_type = meta.type

    # Check 1: Field coupling violation (Stories/Epics only)
    if item_type in ["story", "epic"]:
        stage = meta.get("review_stage")
        result = meta.get("review_result")
        stage_set = stage is not None
        result_set = result is not None
        if stage_set != result_set:
            issues.append({
                "problem": "Field coupling violation",
                "detail": f"review_stage={stage}, review_result={result} — both must be null or both non-null"
            })

    # Check 2: Comment/field mismatch
    mismatch = check_comment_field_mismatch(item)
    if mismatch:
        issues.append(mismatch)

    # Check 3: Completed items with active review fields
    if item.status == "completed" and item_type in ["story", "epic"]:
        if meta.get("review_stage") is not None or meta.get("review_result") is not None:
            issues.append({
                "problem": "Completed item has active review fields",
                "detail": f"review_stage={meta.review_stage}, review_result={meta.review_result}"
            })

    # Check 4: Approval inconsistency (checked at tree level, see Step 3)

    # Check 5: Invalid field values
    if meta.get("approval") not in ["pending", "approved"]:
        issues.append({
            "problem": "Invalid approval value",
            "detail": f"approval={meta.approval} — must be 'pending' or 'approved'"
        })

    if item_type in ["story", "epic"]:
        valid_stages = ["code-review", "qa", "security", "product-review", None]
        valid_results = ["awaiting", "rejected", None]
        if meta.get("review_stage") not in valid_stages:
            issues.append({
                "problem": "Invalid review_stage value",
                "detail": f"review_stage={meta.review_stage}"
            })
        if meta.get("review_result") not in valid_results:
            issues.append({
                "problem": "Invalid review_result value",
                "detail": f"review_result={meta.review_result}"
            })

    return issues
```

### Step 3: Check Approval Consistency Across Tree

```python
def check_approval_consistency(all_items):
    issues = []
    for item in all_items:
        if item.metadata.get("parent"):
            parent = find_item(all_items, item.metadata.parent)
            if parent:
                # Child approved but parent pending
                if item.metadata.approval == "approved" and parent.metadata.approval == "pending":
                    issues.append({
                        "item": item,
                        "problem": "Approval inconsistency",
                        "detail": f"Child approved but parent {parent.id} is still pending"
                    })
                # Parent approved but child still pending
                if parent.metadata.approval == "approved" and item.metadata.approval == "pending":
                    issues.append({
                        "item": item,
                        "problem": "Approval inconsistency",
                        "detail": f"Parent {parent.id} is approved but child is still pending"
                    })
    return issues
```

### Step 4: Determine Correct State from Comments

```python
def determine_correct_fields(item):
    comments = item.metadata.comments or []
    item_type = item.metadata.type

    # Find latest review comment
    review_comments = [c for c in comments if c.type == "review"]
    if not review_comments:
        if item.metadata.approval == "approved":
            return {"review_stage": None, "review_result": None}
        return {"approval": "pending", "review_stage": None, "review_result": None}

    latest = sorted(review_comments, key=lambda c: c.timestamp)[-1]
    content = latest.content.upper()

    if "CODE REVIEW PASSED" in content:
        return {"review_stage": "qa", "review_result": "awaiting"}
    elif "CODE REVIEW REJECTED" in content or "CODE REVIEW FAILED" in content:
        return {"review_stage": "code-review", "review_result": "rejected"}
    elif "QA PASSED" in content:
        return {"review_stage": "product-review", "review_result": "awaiting"}
    elif "QA REJECTED" in content or "QA FAILED" in content:
        return {"review_stage": "qa", "review_result": "rejected"}
    elif "SECURITY APPROVED" in content:
        return {"review_stage": "product-review", "review_result": "awaiting"}
    elif "SECURITY REJECTED" in content:
        return {"review_stage": "security", "review_result": "rejected"}
    elif "PRODUCT REVIEW PASSED" in content or "APPROVED" in content:
        return {"review_stage": None, "review_result": None}
    elif "PRODUCT REVIEW REJECTED" in content:
        return {"review_stage": "product-review", "review_result": "rejected"}
    elif "IMPL COMPLETE" in content or "Ready for code review" in content.lower():
        return {"review_stage": "code-review", "review_result": "awaiting"}

    # Could not determine — flag for manual review
    return None
```

### Step 5: Generate Report

```
Workflow Audit Results
======================

Scope: [All items | Epic: {epic-id}]
Items scanned: X
Issues found: Y

---
disable-model-invocation: true

ISSUES FOUND (Y):

1. Story: Account Management [id: 5]
   Problem: Comment/field mismatch
   Current: review_stage="code-review", review_result="awaiting"
   Latest comment: "CODE REVIEW PASSED" by staff-engineer-agent (2026-02-01)
   Suggested fix: review_stage="qa", review_result="awaiting"

2. Epic: Cashflow MVP [id: 1]
   Problem: Completed item has active review fields
   Current: review_stage="product-review", review_result="awaiting"
   Suggested fix: review_stage=null, review_result=null

3. Story: User Authentication [id: 8]
   Problem: Field coupling violation
   Current: review_stage="qa", review_result=null
   Suggested fix: review_stage="qa", review_result="awaiting"

4. Task: Create DB Models [id: 15]
   Problem: Approval inconsistency
   Current: approval="pending"
   Detail: Parent Story [id: 3] is approved but child is still pending
   Suggested fix: approval="approved"

---
disable-model-invocation: true

NO ISSUES (X items):
- Epic: Infrastructure Setup [id: 2] - fields valid
- Story: Database Layer [id: 3] - fields valid
...

---
disable-model-invocation: true

Run /workflow-audit --fix to auto-correct issues.
```

### Step 6: Apply Fixes (if --fix)

For each issue, apply the suggested fix:

```
TaskUpdate {
  id: "[item-id]",
  metadata: {
    review_stage: [corrected_value],
    review_result: [corrected_value],
    comments: [
      ...existing_comments,
      {
        "id": "WA-[N]",
        "timestamp": "[current-iso-timestamp]",
        "author": "workflow-audit",
        "type": "correction",
        "content": "## WORKFLOW CORRECTION\n\n**Issue:** [problem description]\n**Previous state:** review_stage=[old], review_result=[old]\n**Corrected state:** review_stage=[new], review_result=[new]\n**Basis:** [explanation citing specific comment]"
      }
    ]
  }
}
```

Output after fixes:

```
Workflow Audit - Fixes Applied
==============================

Fixed 4 issues:

1. Story: Account Management [id: 5]
   Fixed: Comment/field mismatch
   Before: review_stage="code-review", review_result="awaiting"
   After:  review_stage="qa", review_result="awaiting"

2. Epic: Cashflow MVP [id: 1]
   Fixed: Completed item has active review fields
   Before: review_stage="product-review", review_result="awaiting"
   After:  review_stage=null, review_result=null

3. Story: User Authentication [id: 8]
   Fixed: Field coupling violation
   Before: review_stage="qa", review_result=null
   After:  review_stage="qa", review_result="awaiting"

4. Task: Create DB Models [id: 15]
   Fixed: Approval inconsistency
   Before: approval="pending"
   After:  approval="approved"

All issues resolved. Run /workflow-audit to verify.
```

## Examples

### Audit All Items
```
/workflow-audit
```

### Audit Specific Epic
```
/workflow-audit CASHFLOW-100
```

### Audit and Auto-Fix
```
/workflow-audit --fix
```

### Audit Specific Epic and Auto-Fix
```
/workflow-audit CASHFLOW-100 --fix
```

## Common Issues and Causes

| Issue | Common Cause | Prevention |
|-------|--------------|------------|
| Field coupling violation | Partial field update (set stage but forgot result) | Always set `review_stage` and `review_result` together |
| Comment/field mismatch | Fields not updated after review comment added | Use `/code-review`, `/qa`, `/product-review` commands which set both |
| Completed with review fields | Status set to completed without clearing review fields | Use Pattern H: set both to null when completing |
| Approval inconsistency | `/approve-epic` not run after planning | Run `/approve-epic` to approve the entire plan |

## Integration with Other Commands

- Run `/workflow-audit` before `/backup` to ensure clean state
- Run `/workflow-audit` after `/hydrate` to verify restored state
- Run `/workflow-audit --fix` if review cycle seems stuck

## Related Documentation

- `.claude/docs/WORKFLOW-STATE.md` - Complete workflow state machine
- `.claude/skills/workflow/workflow-state/SKILL.md` - Workflow transition patterns
- `.claude/templates/tasks/metadata-schema.md` - Valid metadata structure
