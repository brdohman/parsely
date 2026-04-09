---
name: workflow-comments
description: "Comment structure and rules for task workflow updates. Use when adding any comment to a task during implementation, review, or fix cycles."
allowed-tools: [TaskGet, TaskUpdate]
---

# Workflow Comments

## Comment Types

| Type | When Used | Who Writes It |
|------|-----------|---------------|
| `note` | General observation, starting claim | Any agent |
| `implementation` | Task work complete | macos-developer-agent, data-architect-agent |
| `testing` | Test results documented | macos-developer-agent, qa-agent |
| `handoff` | Story ready for next stage | macos-developer-agent |
| `review` | Stage passed (code-review, qa, product-review) | staff-engineer-agent, qa-agent, pm-agent |
| `rejection` | Stage failed — issues found | staff-engineer-agent, qa-agent, pm-agent, security-agent |
| `fix` | Rejection issues addressed, resubmitting | macos-developer-agent |

## Comment Structures

### Base comment (all non-rejection types)

```json
{
  "id": "C3",
  "timestamp": "2026-02-21T10:00:00Z",
  "author": "macos-developer-agent",
  "type": "implementation",
  "content": "IMPLEMENTATION COMPLETE\n\nFiles changed:\n- app/MyApp/MyApp/Views/ItemView.swift\n\nBuild: passed, Tests: 12/12"
}
```

### Trackable comment (rejection only)

```json
{
  "id": "C4",
  "timestamp": "2026-02-21T11:00:00Z",
  "author": "staff-engineer-agent",
  "type": "rejection",
  "content": "REJECTED - CODE REVIEW\n\n1. Force unwrap on line 42 of ItemView.swift — use guard let",
  "resolved": false,
  "resolved_by": null,
  "resolved_at": null
}
```

The `resolved` fields exist only on rejections — they are actionable items to track. When the developer fixes the issues, the reviewer sets `resolved: true`, `resolved_by`, and `resolved_at`.

## Key Rules

1. **Read before write** — always call `TaskGet` first; `comments` is append-only, spread existing array
2. **Sequential IDs** — read existing comments, use next number (if C3 exists, use C4)
3. **Every workflow field change requires a comment** — `review_stage`, `review_result`, `blocked`, `approval` changes must have a comment in the same `TaskUpdate`
4. **ISO 8601 timestamps** — use full datetime with timezone: `2026-02-21T10:00:00Z`
5. **Structured objects only** — never use plain string comments

## Cross-References

- For stage-specific comment templates: see skill `review-cycle`
- For comment field reference and Protocol 6: see `.claude/rules/global/task-state-updates.md`
