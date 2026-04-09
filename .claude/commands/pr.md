---
description: Create GitHub PR. Enforces pre-merge gate. Shows tasks included. Delegates to DevOps agent.
argument-hint: target branch (default: main)
disable-model-invocation: true
---

# /pr

Create pull request with pre-merge gate.

## Delegation

**IMMEDIATELY delegate to Build Engineer agent.**

## Flow

1. **Pre-merge Gate**:
   - Checkpoint completed since last change?
   - Integration tests pass?
   - Coverage meets threshold (80%)?

2. **If gate PASSES**:
   - Gather tasks in branch from commit messages:
     ```bash
     git log origin/main..HEAD --oneline | grep -oE 'task-[0-9]+'
     ```
   - Use `TaskGet` to fetch details for each task
   - Create PR with task summary

3. **Create PR**:
   ```bash
   gh pr create --title "[Title]" --body "[Body]"
   ```

## PR Description Template

```markdown
## Summary
[Auto-generated from commits]

## Tasks Included
- [task-42] Create user service
- [task-43] Add API routes
- [task-44] Build dashboard

## Business Rules
- BR-USER-001: User creation flow
- BR-SYNC-001: Data sync timing

## Test Coverage
- 87% overall
- All critical rules covered

## Checklist
- [ ] TypeScript compiles
- [ ] Lint passes
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] E2E tests pass (if UI changes)
- [ ] Security review (if auth changes)
```

## Output Format

```
Pre-merge gate passed

PR created:
  Title: feat(dashboard): add user dashboard
  URL: https://github.com/[repo]/pull/123

Tasks Included:
- [task-42] Create user service
- [task-43] Add API routes
- [task-44] Build dashboard

Waiting for:
- CodeRabbit review
- CI checks

After merge, run `/deploy` to ship.
```

## GitHub CLI Commands

```bash
gh pr create --title "[title]" --body "[body]"
gh pr view
gh pr checks
```

## Task Tool Usage

```typescript
// Extract task IDs from commits
// git log origin/main..HEAD --oneline | grep -oE 'task-[0-9]+'

// For each task ID, get full details
TaskGet({ task_id: "task-42" })
TaskGet({ task_id: "task-43" })

// Verify tasks are in correct state for PR
// Should have approval == "approved" and parent story review_stage == "code-review"

// After PR creation, update tasks with PR reference
TaskUpdate({
  task_id: "task-42",
  metadata: {
    pr_number: 123,
    pr_url: "https://github.com/org/repo/pull/123"
  }
})
```

## Task State Verification

Before creating PR, verify all included tasks:
1. Have `approval: "approved"` (work was authorized)
2. Are not blocked (`blocked: false`)
3. Parent stories have no unresolved rejections (`review_result != "rejected"`)

```typescript
// Check task state
TaskList()
// Filter for tasks in this branch
// Verify task fields:
// - approval == "approved"
// - blocked == false
// Verify parent story fields:
// - review_result is not "rejected"
// - review_stage is at appropriate stage
```
