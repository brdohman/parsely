# Bug Report Template (v2.0)

## Prerequisites

Before creating a bug:
1. Verify the behavior is actually a bug (not working-as-designed)
2. Check existing bugs to avoid duplicates
3. Reproduce the issue and document steps

## TaskCreate Template

```json
TaskCreate {
  subject: "Bug: [brief description of the defect]",
  description: "## Summary\n[1-2 sentence description]\n\n## Steps to Reproduce\n1. [Step 1]\n2. [Step 2]\n3. [Step 3]\n\n## Expected Behavior\n[What should happen]\n\n## Actual Behavior\n[What actually happens]\n\n## Severity\n[Critical|High|Medium|Low]\n\n## Discovery Context\n[Where/how this was found — QA, user report, code review, etc.]",
  parentId: "[story-id or epic-id if applicable]",
  metadata: {
    schema_version: "2.0",
    type: "bug",
    priority: "P1",
    approval: "pending",
    blocked: false,
    review_stage: null,
    review_result: null,

    severity: "high",
    discovered_from: "[task-id or story-id where bug was found]",
    discovered_by: "[agent-name]-agent",

    steps_to_reproduce: [
      "Step 1: [action]",
      "Step 2: [action]",
      "Step 3: [observe failure]"
    ],
    expected_behavior: "[What should happen]",
    actual_behavior: "[What actually happens]",

    environment: {
      macos_version: "macOS 26.0+",
      app_version: "[version or commit]"
    },

    affected_files: ["path/to/suspected/file.swift"],
    regression: false,

    rca_status: "pending",

    local_checks: [
      "Bug no longer reproduces with fix applied",
      "Regression test exists and passes",
      "No other behavior affected by the fix"
    ],
    completion_signal: "Bug no longer reproduces AND regression test passes",

    blocks: [],
    blockedBy: [],
    labels: ["bug"],
    comments: [],
    created_at: "[ISO8601]",
    last_updated_at: "[ISO8601]"
  }
}
```

## Severity Guide

| Severity | Criteria | Priority | Example |
|----------|----------|----------|---------|
| **Critical** | Core functionality broken, data loss, crash | P0 | App crashes on launch, data corruption |
| **High** | Major feature broken, no workaround | P1 | Cannot save transactions, sync fails silently |
| **Medium** | Feature impaired but workaround exists | P2 | Filter doesn't reset on account switch (manual reset works) |
| **Low** | Minor cosmetic or edge case | P3 | Tooltip shows wrong text, rare edge case |

## Bug Workflow

```
/bug [description]
  → Bug task created (approval: "pending")
  → RCA agent investigates (rca_status: "pending" → "investigated")
  → Staff Engineer reviews RCA findings
  → Human approves fix approach
  → macOS Dev implements fix via /fix
  → Full review cycle: code-review → qa → product-review
```

## Required Fields Checklist

- [ ] `schema_version: "2.0"`
- [ ] `type: "bug"`
- [ ] `approval: "pending"`
- [ ] `blocked: false`
- [ ] `review_stage: null`, `review_result: null`
- [ ] `steps_to_reproduce` (array, min 2 steps)
- [ ] `expected_behavior` and `actual_behavior`
- [ ] `severity` (critical/high/medium/low)
- [ ] `local_checks` (min 3)
- [ ] `completion_signal`
- [ ] `rca_status: "pending"`
- [ ] `labels: ["bug"]`

## Anti-Patterns

- Do NOT create bugs without reproduction steps
- Do NOT set `approval: "approved"` on bugs — human must approve the fix approach after RCA
- Do NOT skip RCA — even "obvious" bugs benefit from root cause analysis
- Do NOT set `rca_status` to anything other than `"pending"` at creation time
