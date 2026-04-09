# Task Completion & Review Cycle

> **Protocols for TaskUpdate calls:** `.claude/rules/global/task-state-updates.md` — the 6 protocols (read-before-write, claim, complete, parent advancement, dependency unblocking, comment format).

## When This Applies

When any agent works on, completes, or reviews a task/story/epic.

## State Machine

> For the complete state machine, field definitions, and lifecycle diagrams, see `.claude/docs/WORKFLOW-STATE.md`.

**Tasks do NOT have review fields.** They only have `approval` and `blocked`.

---

## Review Stage Workflows

Each stage follows: TaskGet → review → TaskUpdate (with comment). Always follow Protocol 1 (read before write) and Protocol 6 (comment format) from `task-state-updates.md`.

### Code Review (staff-engineer-agent)

```
PASSED:
  review_stage: "qa", review_result: "awaiting"
  comment type: "review" — "CODE REVIEW PASSED\n\nChecked:\n- [x] Architecture\n- [x] Standards\n- [x] Security"

FAILED:
  review_stage: "code-review", review_result: "rejected"
  comment type: "rejection" — "REJECTED - CODE REVIEW\n\nIssues:\n1. [description]"
```

### QA Review (qa-agent + visual-qa-agent)

**Two agents run at QA stage for UI stories** (stories with `ux_screens` populated):
- **qa-agent**: headless tests (xcodebuild test), acceptance criteria verification
- **visual-qa-agent**: launches app via Peekaboo, tests EARS specs, walks journeys, screenshots

Both run in parallel. Both must PASS for the story to advance. Non-UI stories only run qa-agent.

```
PASSED (both agents, Epic):
  review_stage: "security", review_result: "awaiting"
  comment type: "review" — "QA PASSED\n\nAC verification:\n- [x] Criteria 1: [how verified]\n\nVisual QA: [X]/[Y] EARS specs verified, [X]/[Y] journeys walked\n\nRouting to Security Audit (epic-level mandatory gate)."

PASSED (both agents, Story/Bug/TechDebt):
  review_stage: "product-review", review_result: "awaiting"
  comment type: "review" — "QA PASSED\n\nAC verification:\n- [x] Criteria 1: [how verified]\n\nVisual QA: [X]/[Y] EARS specs verified, [X]/[Y] journeys walked"

FAILED (either agent):
  review_stage: "qa", review_result: "rejected"
  comment type: "rejection" — "REJECTED - QA\n\nIssues:\n1. [steps to reproduce]\n\n[If visual-qa failed: Visual failures:\n1. EARS spec [ID]: expected [X], observed [Y]]"
```

### Security Audit (security-audit lead agent, orchestrated by /security-audit)

```
PASSED:
  review_stage: "product-review", review_result: "awaiting"
  comment type: "review" — "SECURITY AUDIT PASSED\n\nFindings consolidated from 3 sub-agents:\n- Static: [summary]\n- Reasoning: [summary]\n- Platform: [summary]\n\nSeverity: [none|low|medium]\nDecision: PASS"

FAILED:
  review_stage: "security", review_result: "rejected"
  comment type: "rejection" — "SECURITY AUDIT REJECTED\n\nBlocking findings:\n1. [Severity]: [description]\n\nBugs created: [task-ids]"
```

### Product Review (pm-agent)

```
PASSED:
  review_result: "passed"
  comment type: "review" — "PRODUCT REVIEW PASSED\n\nVerification:\n- [x] Requirements met\n- [x] UX correct"
  → STOP for human verification (Epic: human-uat gate)

FAILED:
  review_stage: "product-review", review_result: "rejected"
  comment type: "rejection" — "REJECTED - PRODUCT REVIEW\n\nIssues:\n1. [description]"
```

### Fixing Rejections (macos-developer-agent)

```
After fixing all issues from rejection comments:
  review_stage: "code-review", review_result: "awaiting"
  comment type: "fix" — "FIXED AND RESUBMITTED\n\nIssues addressed:\n- [issue]: [how fixed]"
```

**Full cycle always restarts from code-review after any rejection.**

### Epic Completion (pm-agent)

```
1. Verify all child stories are completed
2. Add review comment: "EPIC COMPLETE\n\nChild stories: [X/Y]\nDoD: [checklist]"
3. STOP for human UAT
4. After human approval: status → "completed"
```

---

## Verification Checklist

Before completing ANY story/epic:
1. All acceptance criteria verified with `[x]` in a comment
2. At least one review comment exists at each passed stage
3. No open rejection comments without corresponding fix comments
4. `review_result` is not `"rejected"`
5. `blocked` is `false`

## Anti-Patterns

- Complete without implementation + testing comments (see Protocol 3)
- Skip TaskGet before TaskUpdate (see Protocol 1)
- Use labels for workflow state (use `review_stage`/`review_result`)
- Deploy items with `review_result: "rejected"`
- Skip parent advancement after last sibling task (see Protocol 4)
