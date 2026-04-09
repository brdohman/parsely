---
description: Report a bug found during testing. Creates bug task, runs root cause analysis, then queues for human review before fix.
argument-hint: brief description of the bug (optional — will ask if omitted)
---

# /bug Command

Report a bug, automatically investigate root cause, get staff engineer review, then present findings to human before the fix begins.

For v2.0 schema fields and comment format: see `.claude/templates/tasks/metadata-schema.md` and `.claude/rules/global/task-state-updates.md`.

## Full Lifecycle

```
/bug "description"
  │
  ▼
Step 1: Gather details (severity, context, repro steps)
  │
  ▼
Step 2: REPRODUCTION PLAN CONFIRMATION (human sign-off)
  │
  ▼
Step 3-4: Find context, create bug task
  │
  ▼
Step 5: ROOT CAUSE ANALYSIS (RCA agent)
  │
  ▼
Step 6: RCA REVIEW (Staff Engineer agent)
  │
  ▼
Step 7: HUMAN REVIEW → /build [bug-id] or /fix [bug-id]
  │
  ▼
Full review cycle: Code Review → QA → Product Review → Close
```

---

## Step 1: Gather Bug Details

Use AskUserQuestion to collect:
- **Severity**: Critical / High / Medium / Low
- **Where found**: Story ID or general usage
- **Steps to reproduce** (if not in description)

---

## Step 2: Reproduction Plan Confirmation (REQUIRED)

Synthesize user input into a structured plan and present for confirmation before anything else:

```
┌─────────────────────────────────────────────────────────┐
│ REPRODUCTION PLAN — Please confirm before we proceed     │
├─────────────────────────────────────────────────────────┤
│ Bug: [1-sentence summary]                                │
│ Severity: [severity] | Found in: [story or general]     │
│                                                          │
│ PRECONDITIONS                                            │
│   1. [what must already be true]                         │
│                                                          │
│ STEPS TO REPRODUCE                                       │
│   1. [exact action]                                      │
│   2. [exact action]                                      │
│                                                          │
│ EXPECTED RESULT                                          │
│   [what should happen]                                   │
│                                                          │
│ ACTUAL RESULT                                            │
│   [what actually happens]                                │
│                                                          │
│ ASSUMPTIONS                                              │
│   - [anything inferred, not explicitly stated]           │
└─────────────────────────────────────────────────────────┘
```

Ask: "Does this reproduction plan accurately capture the bug?"
- "Yes, proceed" → continue
- "Mostly right, but..." → update and re-confirm (max 3 rounds)
- "No, let me re-explain" → return to Step 1

The confirmed plan becomes source of truth for `steps_to_reproduce`, `expected_behavior`, `actual_behavior`, and the RCA agent input.

---

## Step 3: Find Context

```
If user provided story ID: TaskGet [story-id]
Otherwise: TaskList → ask user to confirm area
```

---

## Step 4: Create Bug Task

```
TaskCreate:
  subject: "Bug: [brief description]"
  metadata:
    schema_version: "2.0", type: "bug"
    severity: "[critical|major|moderate|minor]"
    priority: "[P0|P1|P2|P3]"
    approval: "approved"
    blocked: true         ← blocked until RCA reviewed
    review_stage: null, review_result: null
    rca_status: "pending"
    found_in: "[story-id or null]"
    steps_to_reproduce: [from confirmed plan]
    expected_behavior: "[from confirmed plan]"
    actual_behavior: "[from confirmed plan]"
    comments: []
```

---

## Step 5: Root Cause Analysis (automatic)

Spawn RCA agent with the bug ID. The agent has its own investigation methodology (reproduce → isolate → classify → blast radius → fix options → prevention). The RCA agent will also visually reproduce the bug via Peekaboo and capture "before" screenshot evidence.

```
subagent_type: "rca"
prompt: "Investigate Bug [bug-id].
  TaskGet [bug-id] for reproduction steps and context.
  Follow your investigation methodology.
  IMPORTANT: Visually reproduce the bug via Peekaboo and capture a 'before' screenshot to:
    tools/third-party-reviews/<branch>/<bug-name>/before-<timestamp>.png
  where <bug-name> is the sanitized bug title (lowercase, hyphens, no spaces).
  Update rca_status to 'investigated' when complete."
```

---

## Step 6: Staff Engineer RCA Review (automatic)

Spawn Staff Engineer to review the RCA:

```
subagent_type: "staff-engineer"
prompt: "REVIEW ROOT CAUSE ANALYSIS for Bug [bug-id]
  TaskGet [bug-id], evaluate: root cause accuracy, fix soundness,
  missed risks, scope assessment.

  If solid: rca_status='reviewed', add review comment (APPROVED)
  If needs more: rca_status='needs-more-info', add review comment"
```

If `needs-more-info`: loop RCA agent with SE's questions. Max 2 rounds.

---

## Step 7: Present to Human

```
┌─────────────────────────────────────────────────────────┐
│ BUG REPORT — ROOT CAUSE ANALYSIS COMPLETE               │
├─────────────────────────────────────────────────────────┤
│ ID: [bug-id]  Title: [description]                      │
│ Severity: [severity] (P[N])  Found in: [story or general]│
├─────────────────────────────────────────────────────────┤
│ ROOT CAUSE                                               │
│ [1-2 sentence summary]                                   │
│ Affected files: • [file1] • [file2]                      │
│ Proposed fix: [brief approach]                           │
│ Estimated effort: [small/medium/large]  Risk: [low/med/high]│
├─────────────────────────────────────────────────────────┤
│ VISUAL EVIDENCE                                          │
│ Before screenshot: tools/third-party-reviews/<branch>/   │
│   <bug-name>/before-*.png                                │
│ [or: "Peekaboo unavailable — code-only analysis"]        │
├─────────────────────────────────────────────────────────┤
│ STAFF ENGINEER ASSESSMENT                                │
│ [recommendation summary]                                 │
└─────────────────────────────────────────────────────────┘
```

AskUserQuestion: "RCA complete. How would you like to proceed?"
- "Approve fix — start /build" → `blocked=false`, `rca_status="approved"`, run /build
- "Approve fix — I'll start it later" → `blocked=false`, `rca_status="approved"`
- "Need more info" → loop investigation
- "Deprioritize / Won't fix" → mark completed with "won't fix" comment

---

## Severity-to-Priority Mapping

| Severity | Priority | Meaning |
|----------|----------|---------|
| Critical | P0 | Fix immediately, blocks release |
| High | P1 | Fix before next review cycle |
| Medium | P2 | Fix when convenient |
| Low | P3 | Backlog |

## RCA Status Field

| Value | Meaning |
|-------|---------|
| `"pending"` | Not started |
| `"investigated"` | Dev agent completed RCA |
| `"needs-more-info"` | SE wants more investigation |
| `"reviewed"` | SE approved |
| `"approved"` | Human approved — ready for fix |

---

## Cross-References

- **Bug template:** `.claude/templates/tasks/bug.md`
- **Fix command:** `.claude/commands/fix.md`
- **Build command:** `.claude/commands/build.md`
