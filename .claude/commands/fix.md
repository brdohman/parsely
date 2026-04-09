---
description: Dev picks up rejected items, fixes issues, and resubmits for code review. Handles items failed at any stage.
argument-hint: [task-id] (optional - fix specific task, or omit to see all rejected items)
---

# /fix

macOS Developer agent picks up items rejected at any review stage, fixes the issues, and resubmits.

> For workflow state fields and comment format: see `.claude/docs/WORKFLOW-STATE.md`
> For v2.0 schema field names: Stories/Epics use `acceptance_criteria`; Tasks use `local_checks`, `checklist`, `validation_hint`, `completion_signal`

## Arguments

- `[task-id]` (optional) — If provided: work on that item. If omitted: show all rejected items.

## Rejection Types

| `review_stage` | Failed At | What To Fix |
|----------------|-----------|-------------|
| `code-review` | Code Review | Architecture, Swift patterns, memory management, concurrency |
| `qa` | QA | Bugs, acceptance criteria, edge cases |
| `security` | Security Review | Keychain usage, data exposure, entitlements |
| `product-review` | Product Review | UX, business logic, user requirements |

## Flow

### If no task-id provided

```
TaskList -> filter metadata.review_result == "rejected"
```

Display grouped by rejection stage with issue summary.

### If task-id provided

1. `TaskGet [task-id]` — read rejection details from `metadata.comments`
2. Note all issues, failed criteria, and steps to reproduce
3. Fix all issues in code
4. **VERIFY THE FIX (MANDATORY)**

## Mandatory Verification Checklist

**Fixes without ALL five elements WILL BE REJECTED at code review. No exceptions.**

```
[x] Regression test — a test that would have FAILED before the fix, now PASSES
[x] Test output — captured output showing the regression test passes
[x] Behavior diff — BEFORE vs AFTER behavior documented
[x] Full test suite — all tests passing
[x] Visual verification — Peekaboo screenshots proving the fix works (or "Peekaboo unavailable")
```

```bash
# Regression test (targeted)
xcodebuild test -scheme AppName -only-testing:AppNameTests/TestClass/testMethod

# Full suite
xcodebuild test -scheme AppName -destination 'platform=macOS'
```

## Visual Verification (Peekaboo)

After the fix builds and tests pass, the developer agent MUST visually verify the fix.

⛔ **You MUST follow the Screenshot Validation Protocol** from `.claude/skills/tooling/peekaboo/SKILL.md`. Every screenshot saved as evidence must be validated via `analyze` to confirm it actually shows the app — not the menu bar, desktop, or a different window.

1. **Check Peekaboo availability:** `mcp__peekaboo__permissions()`
2. **Build and launch the app**
3. **Verify the app has visible windows:**
   ```
   mcp__peekaboo__list(item_type: "application_windows", app: "[AppName]",
     include_window_details: ["ids", "bounds", "off_screen"])
   → At least 1 visible window must exist
   ```
4. **Focus the app window:**
   ```
   mcp__peekaboo__window(action: "focus", app: "[AppName]")
   mcp__peekaboo__sleep(duration: 1)
   ```
5. **Walk the reproduction steps** from the bug's `steps_to_reproduce` using Peekaboo interaction tools
6. **Verify expected behavior** — the bug should no longer reproduce
7. **Capture "after" screenshot** — MUST use `app_target`:
   ```
   mcp__peekaboo__see(app_target: "[AppName]",
     path: "tools/third-party-reviews/<branch>/<bug-name>/after-<timestamp>.png")
   ```
8. **Validate the screenshot** — MUST confirm it shows the app:
   ```
   mcp__peekaboo__analyze(
     image_path: "tools/third-party-reviews/<branch>/<bug-name>/after-<timestamp>.png",
     question: "Does this screenshot show the [AppName] application window with its UI visible? Describe what you see in 1-2 sentences. If this only shows a menu bar, desktop, or a different app, say INVALID.")
   → If INVALID: retry from step 4 (max 2 retries), then report validation failure
   → If valid: proceed
   ```
9. **Write a verification summary** to the bug's evidence directory:
   ```
   tools/third-party-reviews/<branch>/<bug-name>/verification.md
   ```
   Contents:
   ```markdown
   # Bug Fix Verification: [bug title]

   **Bug ID:** [bug-id]
   **Fix commit:** [short-hash]
   **Verified:** [ISO8601 timestamp]

   ## Reproduction Steps Walked
   1. [step] — Result: [what happened]
   2. [step] — Result: [what happened]

   ## Before (from RCA)
   ![before](before-*.png)

   ## After (post-fix)
   ![after](after-*.png)

   ## Verdict
   Bug no longer reproduces. Expected behavior confirmed.
   ```

**`<bug-name>`** = same directory name used by the RCA agent. Read the bug task's evidence path from the RCA investigation comment, or derive from the bug title (lowercase, hyphens, no spaces).

**Fallback:** If Peekaboo is unavailable, note in the fix comment: "Visual verification skipped — Peekaboo unavailable. Fix verified via tests only." This will be flagged during code review as degraded verification.

## Resubmit After Fix

```
TaskGet [task-id]   # read before write

TaskUpdate [task-id]
  metadata.review_stage: "code-review"
  metadata.review_result: "awaiting"
  metadata.comments: [...existing, {
    "id": "C[N]", "timestamp": "[ISO8601]", "author": "macos-developer-agent", "type": "fix",
    "content": "FIXED AND RESUBMITTED\n\n**Original rejection:** [code-review|qa|security|product-review]\n\n**Issues fixed:**\n1. [Issue]: Problem: [...] Fix: [...]\n\n**Regression test:** [test name] — PASSES\n**Behavior diff:** BEFORE: [...] AFTER: [...]\n**Full test suite:** [X/X] passed\n**Visual verification:** [path to evidence dir] — before/after screenshots + verification.md\n\n**Ready for code review.**"
  }]
```

Output:
```
Fixed issues for [task-id]
Resubmitted for Code Review (review_stage: code-review, review_result: awaiting)

Fixed: [list]
Verification: regression test PASSED, full suite [X/X] passed

Next: Code Review -> QA -> Product Review
```

## Verification Rejection Policy

If a fix lacks verification evidence, the Staff Engineer MUST reject immediately with:
```
REJECTION REASON: Missing verification evidence

Required elements (check what's missing):
[ ] Regression test code
[ ] Test output showing it passes
[ ] Behavior diff (BEFORE/AFTER)
[ ] Full test suite results
[ ] Visual verification (Peekaboo before/after screenshots + verification.md)
```

Do not review the code itself until verification evidence is provided.

**Degraded verification (no Peekaboo):** If the fix comment states "Peekaboo unavailable", the Staff Engineer should note this in their review and recommend manual visual verification before the bug is closed.

## Rules

1. **Verification is mandatory** — no exceptions
2. **Always restart at Code Review** — regardless of which stage rejected
3. **Address ALL issues** — not partial fixes
4. **Map 1:1 to the rejection** — each fix comment item addresses a rejection item
5. **Prove it works before submitting** — run the tests, capture output
