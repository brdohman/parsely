---
name: epic-notes
description: "Persistent notes pattern for complex epics with 3+ stories. Creates planning/notes/<epic>/ with context.md, decisions.md, open-questions.md, progress.md. Maintains context across sessions."
allowed-tools: [Write, Edit, Bash, Read]
---

# Notes Directory Pattern

## Purpose

Maintain persistent context for complex tasks across sessions. Notes survive context clearing and session restarts.

---

## Directory Structure

```
planning/notes/
├── [feature-or-epic-name]/
│   ├── context.md          # Background, goals, constraints
│   ├── decisions.md        # Architectural and design decisions made
│   ├── open-questions.md   # Unresolved questions and blockers
│   └── progress.md         # What's done, what's next
```

---

## When to Use Notes

| Situation | Action |
|-----------|--------|
| Starting a complex epic (3+ stories) | Create notes directory |
| Making an architectural decision | Add to decisions.md |
| Encountering ambiguity | Add to open-questions.md |
| Completing a milestone | Update progress.md |
| Before running /clear | Update all notes files |

---

## File Templates

### context.md

```markdown
# [Feature/Epic Name] Context

## Goal
[What we're trying to achieve]

## Background
[Why this is needed, user stories, business context]

## Constraints
- [Technical constraint 1]
- [Business constraint 1]
- [Timeline constraint 1]

## Key Stakeholders
- [Who cares about this and why]

## Related Documents
- planning/docs/PRD.md - Section [X]
- planning/docs/TECHNICAL_SPEC.md - Section [Z]

## Last Updated
[Date] by [agent/human]
```

### decisions.md

```markdown
# [Feature/Epic Name] Decisions

## Decision Log

### [Date] - [Decision Title]
**Context:** [Why this decision was needed]
**Options Considered:**
1. [Option A] - [Pros/Cons]
2. [Option B] - [Pros/Cons]

**Decision:** [What was decided]
**Rationale:** [Why this option was chosen]
**Decided By:** [human/agent-name]

---

### [Date] - [Next Decision]
...
```

### open-questions.md

```markdown
# [Feature/Epic Name] Open Questions

## Unresolved

### Q1: [Question]
**Context:** [Why this matters]
**Blocking:** [What can't proceed until answered]
**Options:**
- [Option A]
- [Option B]
**Owner:** [Who should answer this]

---

## Resolved

### Q1: [Question] - RESOLVED [Date]
**Answer:** [The answer]
**Decided By:** [Who]
**Applied To:** [Where this was implemented]
```

### progress.md

```markdown
# [Feature/Epic Name] Progress

## Current Status
[One sentence summary]

## Completed
- [x] [Milestone 1] - [Date]
- [x] [Milestone 2] - [Date]

## In Progress
- [ ] [Current work item]
  - Started: [Date]
  - Blocker: [If any]

## Next Up
- [ ] [Next milestone]
- [ ] [Following milestone]

## Session Handoff Notes
[Notes for resuming work after /clear or new session]

## Last Updated
[Date] by [agent/human]
```

---

## Agent Responsibilities

### When Starting Work on a Task

```
1. Check if planning/notes/[epic-name]/ exists
2. If exists:
   - Read all notes files
   - Resume with full context
3. If not exists and epic is complex:
   - Create notes directory
   - Initialize context.md from epic description
```

### When Making Decisions

```
1. Document in decisions.md BEFORE implementing
2. Include rationale
3. Reference the task ID if applicable
```

### When Blocked

```
1. Add to open-questions.md
2. Set owner (who should answer)
3. List what's blocked
4. Continue with non-blocked work
```

### Before Completing Session

```
1. Update progress.md with current state
2. Add session handoff notes
3. Move resolved questions to "Resolved" section
4. Commit notes if significant changes
```

---

## Integration with /backup and /hydrate

Notes directories persist on disk and don't need backup/hydrate.

However, when running `/backup`:
- The backup script should also snapshot notes to the backup directory

When running `/hydrate`:
- Check for notes directories and inform the user

---

## Creating Notes Directory

```bash
# Create notes for a new epic
mkdir -p planning/notes/[epic-name]

# Initialize with templates (agent does this automatically)
touch planning/notes/[epic-name]/context.md
touch planning/notes/[epic-name]/decisions.md
touch planning/notes/[epic-name]/open-questions.md
touch planning/notes/[epic-name]/progress.md
```

---

## Example

For an epic "user-authentication":

```
planning/notes/user-authentication/
├── context.md
│   Goal: Implement secure login with biometrics
│   Constraints: No external auth providers, local only
│
├── decisions.md
│   2026-01-15: Use Keychain for credential storage
│   Rationale: Apple best practice, secure enclave
│
├── open-questions.md
│   Q1: What happens on failed biometric 3x? - RESOLVED
│   Answer: Fall back to password entry
│
└── progress.md
│   Completed: Login view, ViewModel, Keychain service
│   In Progress: Biometric authentication
│   Next: Session timeout handling
```

---

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Skip notes for "simple" 5+ story epics | Always create notes for 3+ stories |
| Put decisions only in task comments | Duplicate important decisions to notes |
| Leave open-questions unowned | Assign every question an owner |
| Forget to update before /clear | Make it a habit: notes before clear |
