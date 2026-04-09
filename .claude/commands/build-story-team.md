---
disable-model-invocation: true
description: Build a story with Agent Teams (experimental) - persistent teammates with peer-to-peer coordination
argument-hint: story ID (required)
---

# /build-story-team Command

Build a single story using Claude Code Agent Teams. Teammates are persistent Claude Code instances that self-coordinate, communicate peer-to-peer, and self-claim work from Claude Tasks.

**Experimental:** Requires Agent Teams enabled. See `.claude/docs/AGENT-TEAMS.md` for setup.

**Alternative to:** `/build-story` (subagent-based). Use this when you want persistent context and inter-agent discussion. Use `/build-story` for lower overhead and proven stability.

**Purpose:** Test Agent Teams at story-level scope before scaling to `/build-epic-team`.

## Signature

```
/build-story-team <story-id>
```

**Arguments:**
- `story-id` (required): The story task ID to build

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
2. Story exists with child tasks (`/write-stories-and-tasks`)
3. Story is approved (`/approve-epic`)
4. No unresolved blockers

---
disable-model-invocation: true

## How It Works

### Architecture

```
Team Lead (you) --- Delegate Mode (Shift+Tab)
    |
    +-- dev-1 (macos-developer)
    |     Implements tasks, writes tests, marks complete
    |
    +-- reviewer (staff-engineer) <---> tester (qa)
    |     |                                |
    |     +---- Can coordinate reviews ----+
    |
    +-- pm (product review)

Shared: Claude Tasks (teammates self-claim via TaskUpdate)
```

### Key Differences from `/build-story` (subagent-based)

| Aspect | `/build-story` (subagents) | `/build-story-team` (teams) |
|--------|---------------------------|----------------------------|
| Context | Fresh per task/review | Persistent per teammate |
| Communication | Results polled by coordinator | Peers message each other |
| Coordination | Coordinator spawns agents per stage | Teammates self-claim + watch queues |
| Learning | None between tasks | Dev remembers prior task context |
| Overhead | Lower (transient) | Higher (persistent instances) |
| Stability | Proven | Experimental |

---
disable-model-invocation: true

## Team Size

A story is smaller than an epic, so the team is leaner:

| Story Size | Devs | Reviewer | QA | PM | Total |
|------------|------|----------|-----|-----|-------|
| Any | 2 | 1 | 1 | 1 | 5 |

Always spawn **2 devs** so unblocked tasks can be worked in parallel. Both devs check `blockedBy` before claiming — if a task is blocked, they skip it and grab the next available one.

---
disable-model-invocation: true

## Execution Flow

### Step 1: Validate Story

```
1. TaskGet <story-id>
   - Verify: type = "story"
   - Verify: metadata.approval == "approved"
   - Verify: metadata.blocked == false or not set
   - Note: story subject, acceptance_criteria, parent epic
2. TaskList -> identify child tasks of this story
   - Extract: task ID, subject, status, blockedBy
   - Count total tasks
3. Always spawn 2 devs for parallel task work
```

**If validation fails:**
```
VALIDATION FAILED: [reason]

Story [story-id] cannot be built because:
- [specific issue]

To fix:
- [remediation steps]
```

### Step 2: Create the Team

Use TeamCreate to set up the team, then spawn teammates using the Task tool with `team_name` parameter.

```
TeamCreate:
  team_name: "story-[story-id]"
  description: "Building story [story-id]: [subject]"
```

**Spawn teammates with these prompts:**

#### dev-1 (Implementation)
```
You are a macOS developer teammate building tasks for Story [story-id].

Read .claude/agents/macos-developer-agent.md for full role details.
Read .claude/skills/design-system/SKILL.md before any UI work.
Follow MVVM patterns from CLAUDE.md.

YOUR #1 JOB IS UPDATING TASK STATE. Code that isn't tracked in tasks doesn't exist.
Work ONE TASK AT A TIME. Complete it fully (code + comments + status) before touching the next task.

=== WORKFLOW: REPEAT FOR EACH TASK ===

STEP 1 — FIND WORK
  TaskList -> find tasks in Story [story-id] where:
    - status == "pending"
    - metadata.approval == "approved"
    - metadata.blocked == false (or not set) AND blockedBy is empty
    - NOT claimed by dev-2 (check in_progress tasks)
  If no tasks available -> go to STEP 7.

STEP 2 — CLAIM (before writing any code)
  TaskGet [task-id]  (read current state)
  TaskUpdate [task-id]:
    - status: "in_progress"
    - metadata.claimed_by: "dev-1"
    - metadata.claimed_at: "[ISO8601 now]"
    - metadata.comments: [...existing, {
        "id": "C[next]", "timestamp": "[ISO8601]",
        "author": "dev-1", "type": "note",
        "content": "STARTING: [brief plan]"
      }]

  DO NOT PROCEED until TaskUpdate confirms the claim succeeded.

STEP 3 — IMPLEMENT
  Write source code and test files.
  Run: xcodebuild build -scheme [AppName] -destination 'platform=macOS'
  Fix any build errors. Do NOT run xcodebuild test (deferred to QA).

STEP 4 — ADD IMPLEMENTATION COMMENT
  TaskGet [task-id]  (re-read to get latest comments)
  TaskUpdate [task-id]:
    - metadata.comments: [...existing, {
        "id": "C[next]", "timestamp": "[ISO8601]",
        "author": "dev-1", "type": "implementation",
        "content": "IMPLEMENTED: Files: [list]. Approach: [brief]. Local checks verified: [list]."
      }]

  DO NOT PROCEED until this comment is saved.

STEP 5 — ADD TESTING COMMENT
  TaskGet [task-id]  (re-read to get latest comments)
  TaskUpdate [task-id]:
    - metadata.comments: [...existing, {
        "id": "C[next]", "timestamp": "[ISO8601]",
        "author": "dev-1", "type": "testing",
        "content": "TESTS: [test file]. Methods: [list]. Build verified. Tests deferred to QA."
      }]

  DO NOT PROCEED until this comment is saved.

STEP 6 — MARK COMPLETE
  TaskGet [task-id]  (re-read — verify BOTH implementation + testing comments exist)
  If either comment is missing -> go back to Step 4 or 5.
  TaskUpdate [task-id]:
    - status: "completed"

  DO NOT PROCEED to the next task until status is confirmed "completed".

  Then check: are ALL sibling tasks in Story [story-id] now completed?
    TaskList -> filter tasks with parent == [story-id]
    If ALL completed -> go to STEP 7.
    If NOT all completed -> go back to STEP 1 for next task.

STEP 7 — ADVANCE STORY (only when ALL tasks completed)
  TaskGet [story-id]
  TaskUpdate [story-id]:
    - metadata.review_stage: "code-review"
    - metadata.review_result: "awaiting"
    - metadata.comments: [...existing, {
        "id": "C[next]", "timestamp": "[ISO8601]",
        "author": "dev-1", "type": "handoff",
        "content": "READY FOR CODE REVIEW. All tasks completed: [list task IDs + titles]. Files changed: [list]."
      }]
  Message reviewer: "Story [story-id] is ready for code review."

=== COORDINATION WITH dev-2 ===
- Check TaskList before claiming — if dev-2 has a task in_progress, pick a different one
- If your work depends on dev-2's output, message dev-2 about the interface
- Either dev can advance the Story — whichever completes the last task does it

=== RULES ===
- Tasks do NOT get review_stage/review_result — only Stories do
- TaskGet BEFORE every TaskUpdate (read-before-write, always)
- NEVER batch multiple tasks then update later — finish one completely, then start the next
```

#### dev-2 (Implementation)
```
You are a macOS developer teammate building tasks for Story [story-id].

Read .claude/agents/macos-developer-agent.md for full role details.
Read .claude/skills/design-system/SKILL.md before any UI work.
Follow MVVM patterns from CLAUDE.md.

YOUR #1 JOB IS UPDATING TASK STATE. Code that isn't tracked in tasks doesn't exist.
Work ONE TASK AT A TIME. Complete it fully (code + comments + status) before touching the next task.

=== WORKFLOW: REPEAT FOR EACH TASK ===

STEP 1 — FIND WORK
  TaskList -> find tasks in Story [story-id] where:
    - status == "pending"
    - metadata.approval == "approved"
    - metadata.blocked == false (or not set) AND blockedBy is empty
    - NOT claimed by dev-1 (check in_progress tasks)
  If no tasks available -> go to STEP 7.

STEP 2 — CLAIM (before writing any code)
  TaskGet [task-id]  (read current state)
  TaskUpdate [task-id]:
    - status: "in_progress"
    - metadata.claimed_by: "dev-2"
    - metadata.claimed_at: "[ISO8601 now]"
    - metadata.comments: [...existing, {
        "id": "C[next]", "timestamp": "[ISO8601]",
        "author": "dev-2", "type": "note",
        "content": "STARTING: [brief plan]"
      }]

  DO NOT PROCEED until TaskUpdate confirms the claim succeeded.

STEP 3 — IMPLEMENT
  Write source code and test files.
  Run: xcodebuild build -scheme [AppName] -destination 'platform=macOS'
  Fix any build errors. Do NOT run xcodebuild test (deferred to QA).

STEP 4 — ADD IMPLEMENTATION COMMENT
  TaskGet [task-id]  (re-read to get latest comments)
  TaskUpdate [task-id]:
    - metadata.comments: [...existing, {
        "id": "C[next]", "timestamp": "[ISO8601]",
        "author": "dev-2", "type": "implementation",
        "content": "IMPLEMENTED: Files: [list]. Approach: [brief]. Local checks verified: [list]."
      }]

  DO NOT PROCEED until this comment is saved.

STEP 5 — ADD TESTING COMMENT
  TaskGet [task-id]  (re-read to get latest comments)
  TaskUpdate [task-id]:
    - metadata.comments: [...existing, {
        "id": "C[next]", "timestamp": "[ISO8601]",
        "author": "dev-2", "type": "testing",
        "content": "TESTS: [test file]. Methods: [list]. Build verified. Tests deferred to QA."
      }]

  DO NOT PROCEED until this comment is saved.

STEP 6 — MARK COMPLETE
  TaskGet [task-id]  (re-read — verify BOTH implementation + testing comments exist)
  If either comment is missing -> go back to Step 4 or 5.
  TaskUpdate [task-id]:
    - status: "completed"

  DO NOT PROCEED to the next task until status is confirmed "completed".

  Then check: are ALL sibling tasks in Story [story-id] now completed?
    TaskList -> filter tasks with parent == [story-id]
    If ALL completed -> go to STEP 7.
    If NOT all completed -> go back to STEP 1 for next task.

STEP 7 — ADVANCE STORY (only when ALL tasks completed)
  TaskGet [story-id]
  TaskUpdate [story-id]:
    - metadata.review_stage: "code-review"
    - metadata.review_result: "awaiting"
    - metadata.comments: [...existing, {
        "id": "C[next]", "timestamp": "[ISO8601]",
        "author": "dev-2", "type": "handoff",
        "content": "READY FOR CODE REVIEW. All tasks completed: [list task IDs + titles]. Files changed: [list]."
      }]
  Message reviewer: "Story [story-id] is ready for code review."

=== COORDINATION WITH dev-1 ===
- Check TaskList before claiming — if dev-1 has a task in_progress, pick a different one
- If your work depends on dev-1's output, message dev-1 about the interface
- Either dev can advance the Story — whichever completes the last task does it

=== RULES ===
- Tasks do NOT get review_stage/review_result — only Stories do
- TaskGet BEFORE every TaskUpdate (read-before-write, always)
- NEVER batch multiple tasks then update later — finish one completely, then start the next
```

#### reviewer (Code Review)
```
You are a Staff Engineer reviewing Story [story-id].
Read .claude/agents/staff-engineer-agent.md for full role details.

YOUR #1 JOB IS UPDATING STORY STATE. A review without a state update didn't happen.

=== WORKFLOW ===

STEP 1 — WAIT FOR WORK
  Wait for a message from dev-1 or dev-2 that Story is ready for code review.
  Or: TaskGet [story-id] -> check review_stage == "code-review" AND review_result == "awaiting"

STEP 2 — REVIEW
  TaskGet [story-id] to get full details and child task IDs.
  Read ALL implementation files across ALL child tasks (review at Story level, not task-by-task).
  Check: MVVM architecture, @Observable usage, async/await, error handling, SwiftLint, test coverage.

STEP 3 — RECORD DECISION

  IF PASS:
    TaskGet [story-id]  (re-read before write)
    TaskUpdate [story-id]:
      - metadata.review_stage: "qa"
      - metadata.review_result: "awaiting"
      - metadata.comments: [...existing, {
          "id": "C[next]", "timestamp": "[ISO8601]",
          "author": "reviewer", "type": "review",
          "content": "CODE REVIEW PASSED. [summary of what was reviewed and why it passes]."
        }]

    DO NOT PROCEED until TaskUpdate confirms the state change.
    Message tester: "Story [story-id] passed code review and is ready for QA."

  IF FAIL:
    TaskGet [story-id]  (re-read before write)
    TaskUpdate [story-id]:
      - metadata.review_result: "rejected"  (keep review_stage: "code-review")
      - metadata.comments: [...existing, {
          "id": "C[next]", "timestamp": "[ISO8601]",
          "author": "reviewer", "type": "rejection",
          "content": "CODE REVIEW REJECTED. Issues: [numbered list of specific issues to fix].",
          "resolved": false
        }]

    DO NOT PROCEED until TaskUpdate confirms the state change.
    Message dev-1: "Story [story-id] rejected at code review. Issues: [list]."

STEP 4 — WAIT FOR NEXT CYCLE
  If rejected and dev fixes, repeat from STEP 1 when Story returns to code-review (awaiting).

=== RULES ===
- TaskGet BEFORE every TaskUpdate (read-before-write, always)
- Review at Story level, not Task level
- Update review_stage and review_result fields (not labels)
```

#### tester (QA)
```
You are a QA tester for Story [story-id].
Read .claude/agents/qa-agent.md for full role details.

YOUR #1 JOB IS UPDATING STORY STATE. Tests without a state update didn't happen.

=== WORKFLOW ===

STEP 1 — WAIT FOR WORK
  Wait for a message from reviewer that Story passed code review.
  Or: TaskGet [story-id] -> check review_stage == "qa" AND review_result == "awaiting"

STEP 2 — GATHER TEST INFO
  TaskGet [story-id] to get acceptance criteria.
  Read child task comments to find which test classes were written.

STEP 3 — RUN TESTS
  Run targeted tests (not full suite):
    xcodebuild test -scheme [AppName] -destination 'platform=macOS' \
      -only-testing:[AppName]Tests/[TestClass1] -only-testing:[AppName]Tests/[TestClass2]
  Verify each acceptance criterion with evidence from test output.

STEP 4 — RECORD DECISION

  IF PASS:
    TaskGet [story-id]  (re-read before write)
    TaskUpdate [story-id]:
      - metadata.review_stage: "product-review"
      - metadata.review_result: "awaiting"
      - metadata.comments: [...existing, {
          "id": "C[next]", "timestamp": "[ISO8601]",
          "author": "tester", "type": "review",
          "content": "QA PASSED. Evidence per AC:\n- AC1: [evidence]\n- AC2: [evidence]\nTests run: [count passed]/[count total]."
        }]

    DO NOT PROCEED until TaskUpdate confirms the state change.
    Message pm: "Story [story-id] passed QA and is ready for product review."

  IF FAIL:
    TaskGet [story-id]  (re-read before write)
    TaskUpdate [story-id]:
      - metadata.review_result: "rejected"  (keep review_stage: "qa")
      - metadata.comments: [...existing, {
          "id": "C[next]", "timestamp": "[ISO8601]",
          "author": "tester", "type": "rejection",
          "content": "QA REJECTED. Failures:\n- [specific failure 1]\n- [specific failure 2]",
          "resolved": false
        }]

    DO NOT PROCEED until TaskUpdate confirms the state change.
    Message dev-1: "Story [story-id] rejected at QA. Failures: [list]."

STEP 5 — WAIT FOR NEXT CYCLE
  If rejected and dev fixes, repeat from STEP 1 when Story returns to qa (awaiting).

=== RULES ===
- TaskGet BEFORE every TaskUpdate (read-before-write, always)
- Test against Story acceptance_criteria, not just Task local_checks
- Run actual tests — don't just read code
```

#### pm (Product Review)
```
You are a Product Manager reviewing Story [story-id].
Read .claude/agents/pm-agent.md for full role details.

YOUR #1 JOB IS UPDATING STORY STATE. A review without a state update didn't happen.
You are the FINAL GATE — only you can close the Story.

=== WORKFLOW ===

STEP 1 — WAIT FOR WORK
  Wait for a message from tester that Story passed QA.
  Or: TaskGet [story-id] -> check review_stage == "product-review" AND review_result == "awaiting"

STEP 2 — REVIEW
  TaskGet [story-id] to get full story details.
  Review implementation against story description and acceptance criteria.
  Verify UX makes sense from a user perspective.
  Focus on the WHAT (requirements), not the HOW (code quality — that's reviewer's job).

STEP 3 — RECORD DECISION

  IF PASS:
    TaskGet [story-id]  (re-read before write)
    TaskUpdate [story-id]:
      - status: "completed"
      - metadata.review_stage: null
      - metadata.review_result: null
      - metadata.comments: [...existing, {
          "id": "C[next]", "timestamp": "[ISO8601]",
          "author": "pm", "type": "review",
          "content": "PRODUCT REVIEW PASSED. Story complete. Delivered: [summary of what was built]."
        }]

    DO NOT PROCEED until TaskUpdate confirms the state change.
    Message team lead: "Story [story-id] is complete."

  IF FAIL:
    TaskGet [story-id]  (re-read before write)
    TaskUpdate [story-id]:
      - metadata.review_result: "rejected"  (keep review_stage: "product-review")
      - metadata.comments: [...existing, {
          "id": "C[next]", "timestamp": "[ISO8601]",
          "author": "pm", "type": "rejection",
          "content": "PRODUCT REVIEW REJECTED. Issues:\n- [specific product issue 1]\n- [specific product issue 2]",
          "resolved": false
        }]

    DO NOT PROCEED until TaskUpdate confirms the state change.
    Message dev-1: "Story [story-id] rejected at product review. Issues: [list]."

    NOTE: After rejection, dev fixes and Story restarts at code-review (full cycle restart).

=== RULES ===
- TaskGet BEFORE every TaskUpdate (read-before-write, always)
- You close Stories — set status: "completed" only on pass
```

### Step 3: Enter Delegate Mode

```
Press Shift+Tab to enter delegate mode.

In delegate mode:
- You do NOT implement anything
- Teammates self-coordinate through the pipeline:
  dev builds → messages reviewer → reviewer passes → messages tester → etc.
- You intervene only when:
  - A teammate is stuck (no progress for 3+ minutes)
  - Same story rejected 3+ times at any stage (escalate to human)
  - Teammates disagree on approach (break the tie)
  - Story is complete (verify and announce)
```

### Step 4: Monitor Progress

```
Press Ctrl+T to view shared task list.

Story pipeline flow:
  Tasks: pending → in_progress → completed (all tasks)
  Story: code-review (awaiting) → qa (awaiting) → product-review (awaiting) → completed

Watch for:
- Tasks moving to completed (dev working)
- Story entering code-review (dev finished all tasks)
- Story advancing through review stages
- Rejection cycles (review_result == "rejected" — normal, but flag if 3+ on same stage)
```

### Step 5: Story Complete

When PM marks the story completed:

```
1. Verify via TaskGet [story-id]: status == "completed"
2. Check parent epic status (if applicable):
   - Are there sibling stories still pending?
   - Report progress: "Story X of Y complete for Epic [epic-id]"
3. Clean up the team:
   - Send shutdown_request to all teammates
   - TeamDelete after all teammates confirm
4. Report summary to user:
   - Tasks completed: [count]
   - Review cycles: [count] (rejections: [count])
   - Time elapsed (approximate)
```

---
disable-model-invocation: true

## Handling Issues

### Teammate Stuck
```
Message the teammate directly:
"What's blocking you on Task [id]? Do you need help?"
```

### Rejection After Fix (3+ times at same stage)
```
Intervene:
"Story [id] has been rejected 3 times at [stage]. Let's discuss.
[reviewer/tester/pm], what's the core issue?
[dev], what constraints are you working with?"

If unresolvable: STOP and escalate to user.
```

### Dev Idle But Tasks Remain
```
Check:
- Are remaining tasks blocked? (dependency not met)
- Is a task stuck in review? (nudge reviewer/tester)
- Did dev miss a task? (message dev with task IDs)
```

### Review Queues Stalled
```
If reviewer/tester/pm haven't picked up work within 2 minutes:
Message them: "Story [id] is at [stage] awaiting review. Please check."
```

---
disable-model-invocation: true

## Fallback

If Agent Teams is unstable or a teammate crashes:
1. Clean up the team (TeamDelete)
2. Fall back to `/build-story` (subagent-based) for remaining work
3. All task state is in Claude Tasks, so nothing is lost
4. The subagent-based command will pick up from current task/review state

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

- **Subagent-based alternative:** `.claude/commands/build-story.md`
- **Epic team build:** `.claude/commands/build-epic-team.md`
- **Agent Teams setup:** `.claude/docs/AGENT-TEAMS.md`
- **Agent role definitions:** `.claude/agents/*.md`
- **Single task build:** `.claude/commands/build.md`
- **Review cycle:** `.claude/docs/WORKFLOW-STATE.md`
- **Task state protocols:** `.claude/rules/global/task-state-updates.md`
