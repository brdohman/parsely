---
disable-model-invocation: true
description: Build epic with Agent Teams (experimental) - persistent teammates with peer-to-peer coordination
argument-hint: epic ID (required)
---

# /build-epic-team Command

Build an epic using Claude Code Agent Teams. Teammates are persistent Claude Code instances that self-coordinate, communicate peer-to-peer, and self-claim work from Claude Tasks.

**Experimental:** Requires Agent Teams enabled. See `.claude/docs/AGENT-TEAMS.md` for setup.

**Alternative to:** `/build-epic` (subagent-based). Use this when you want persistent context and inter-agent discussion. Use `/build-epic` for lower overhead and proven stability.

## Signature

```
/build-epic-team <epic-id>
```

**Arguments:**
- `epic-id` (required): The epic task ID to build

---
disable-model-invocation: true

## Prerequisites

1. Agent Teams enabled in `~/.claude/settings.json`:
   ```json
   {
     "env": {
       "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
     }
   }
   ```
2. Epic exists with stories and tasks (`/write-stories-and-tasks`)
3. Epic is approved (`/approve-epic`)
4. No unresolved blockers

---
disable-model-invocation: true

## How It Works

### Architecture

```
Team Lead (you) ─── Delegate Mode (Shift+Tab)
    │
    ├── dev-1 (macos-developer) ◄──► dev-2 (macos-developer)
    │        │                              │
    │        └──── Can discuss implementation ───┘
    │
    ├── reviewer (staff-engineer) ◄──► tester (qa)
    │        │                              │
    │        └──── Can coordinate reviews ──┘
    │
    └── pm (product review)

Shared: Claude Tasks (teammates self-claim via TaskUpdate)
```

### Key Differences from `/build-epic`

| Aspect | `/build-epic` (subagents) | `/build-epic-team` (teams) |
|--------|---------------------------|----------------------------|
| Context | Fresh per task | Persistent per teammate |
| Communication | Results return to coordinator | Peers message each other |
| Coordination | Coordinator assigns all work | Teammates self-claim |
| Learning | None between tasks | Teammate remembers codebase |
| Overhead | Lower (transient) | Higher (persistent instances) |
| Stability | Proven | Experimental |

---
disable-model-invocation: true

## Execution Flow

### Step 1: Validate Epic

Same as `/build-epic`:
```
1. TaskGet <epic-id>
2. Verify: type = "epic", has children, metadata.approval == "approved"
3. Count total tasks
```

### Step 2: Create the Team

Spawn teammates using natural language. Each teammate gets:
- The project CLAUDE.md (automatic)
- Their role-specific agent definition
- The epic context and task list

**Spawn teammates with these prompts:**

#### dev-1 (Implementation)
```
You are a macOS developer teammate. Your role:
- Self-claim Tasks with approval == "approved" from Epic [epic-id] via TaskUpdate
- Implement following MVVM patterns in CLAUDE.md
- Read .claude/agents/macos-developer-agent.md for full role details
- Read .claude/skills/design-system/SKILL.md before any UI work
- Coordinate with dev-2 on shared interfaces
- When Task complete: add implementation + testing comments, mark completed
- When all Tasks in a Story complete: set Story review_stage: "code-review", review_result: "awaiting"
- Message reviewer when Story is ready for review

CRITICAL RULES:
- Check metadata.approval == "approved" before starting any Task
- Add BOTH implementation and testing comments before marking complete
- Tasks do NOT get review_stage/review_result fields - only Stories do
- Run tests and wait for results before marking complete
```

#### dev-2 (Implementation)
```
Same as dev-1, plus:
- Coordinate with dev-1 to avoid working on the same Task
- If dev-1 is working on a ViewModel, pick a complementary Task (View, Service, etc.)
- Discuss interface contracts with dev-1 when your work depends on theirs
```

#### reviewer (Code Review)
```
You are a Staff Engineer teammate. Your role:
- Watch for Stories with review_stage == "code-review" AND review_result == "awaiting" in Epic [epic-id]
- Read .claude/agents/staff-engineer-agent.md for full role details
- Review ALL code from ALL child Tasks in a Story together
- If PASS: set review_stage: "qa", review_result: "awaiting", add review comment
- If FAIL: set review_result: "rejected" (review_stage stays "code-review"), add detailed rejection comment
- Message the dev who wrote the code when rejecting, explain why
- Coordinate with tester on what to watch for

CRITICAL RULES:
- Review at Story level, not Task level
- Update review_stage and review_result fields (not labels)
- Every state change needs a comment
```

#### tester (QA)
```
You are a QA teammate. Your role:
- Watch for Stories with review_stage == "qa" AND review_result == "awaiting" in Epic [epic-id]
- Read .claude/agents/qa-agent.md for full role details
- Test ALL acceptance criteria from the Story
- Run xcodebuild test and verify results
- If PASS: set review_stage: "product-review", review_result: "awaiting"
- If FAIL: set review_result: "rejected" (review_stage stays "qa") with specific failures
- Message reviewer if you find architectural issues worth flagging

CRITICAL RULES:
- Test against Story acceptance_criteria, not just Task local_checks
- Run actual tests, don't just read code
- Every state change needs a comment
```

#### pm (Product Review)
```
You are a Product Manager teammate. Your role:
- Watch for Stories with review_stage == "product-review" AND review_result == "awaiting" in Epic [epic-id]
- Read .claude/agents/pm-agent.md for full role details
- Verify user requirements and UX make sense
- If PASS: set review_stage: null, review_result: null, mark Story completed, add closure comment
- If FAIL: set review_result: "rejected" (review_stage stays "product-review") with specific issues
- Final gate - only you can close Stories

CRITICAL RULES:
- You are the last gate before closure
- Verify the WHAT (requirements), not the HOW (code quality - that's reviewer's job)
- Every state change needs a comment
```

### Step 3: Enter Delegate Mode

```
Press Shift+Tab to enter delegate mode.

In delegate mode:
- You do NOT implement anything
- Teammates self-coordinate
- You intervene only when:
  - A teammate is stuck (no progress for 2+ minutes)
  - Same task rejected 3+ times (escalate to human)
  - Teammates disagree on approach (break the tie)
  - Epic is complete (verify and announce)
```

### Step 4: Monitor Progress

```
Press Ctrl+T to view shared task list.

Watch for:
- Tasks flowing through pipeline: approval == "approved" → in_progress → completed
- Stories advancing: review_stage code-review → qa → product-review → completed
- Rejection cycles (review_result == "rejected", normal, but flag if 3+ on same item)
- All queues empty = check if epic is done
```

### Step 5: Epic Complete

When all Stories are completed:

```
1. Verify via TaskList: all tasks status = "completed"
2. Update epic status to "completed"
3. Clean up the team (natural language: "clean up the team")
4. Report summary to user
```

---
disable-model-invocation: true

## Team Size Guidelines

| Epic Size | Devs | Reviewer | QA | PM | Total |
|-----------|------|----------|-----|-----|-------|
| Small (5-8 tasks) | 1 | 1 | 1 | 1 | 4 |
| Medium (9-15 tasks) | 2 | 1 | 1 | 1 | 5 |
| Large (16+ tasks) | 2 | 1 | 1 | 1 | 5 |

More than 2 devs risks merge conflicts and coordination overhead.

---
disable-model-invocation: true

## Handling Issues

### Teammate Stuck
```
Message the teammate directly:
"What's blocking you on Task [id]? Do you need help?"
```

### Circular Rejections (3+ on same item)
```
Intervene:
"Task [id] has been rejected 3 times. Let's discuss the approach
before another attempt. [reviewer], what's the core issue?
[dev], what constraints are you working with?"
```

### No Work Available But Epic Not Done
```
Check for:
- Blocked tasks (dependency not met)
- Tasks stuck in review (nudge reviewer/tester)
- Tasks in progress but stalled (nudge dev)
```

---
disable-model-invocation: true

## Fallback

If Agent Teams is unstable or a teammate crashes:
1. Clean up the team
2. Fall back to `/build-epic` (subagent-based) for remaining work
3. All task state is in Claude Tasks, so nothing is lost

---
disable-model-invocation: true

## Known Limitations (Experimental)

- No session resumption for in-process teammates
- Task status can lag between teammates (may need manual nudges)
- One team per session
- No nested teams
- Lead is fixed (can't transfer leadership)
- Split panes require tmux or iTerm2

---
disable-model-invocation: true

## Cross-References

- **Subagent-based alternative:** `.claude/commands/build-epic.md`
- **Agent Teams setup:** `.claude/docs/AGENT-TEAMS.md`
- **Agent role definitions:** `.claude/agents/*.md`
- **Single task build:** `.claude/commands/build.md`
- **Review cycle:** `.claude/docs/WORKFLOW-STATE.md`
