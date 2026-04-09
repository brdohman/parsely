---
description: PM reviews Stories/Epics that passed QA. Verify user requirements, UX, business logic for entire phase/feature. Final gate before closing.
argument-hint: [story-id|epic-id] (optional - review specific Story/Epic, or omit to see queue)
---

# /product-review

PM agent (or human) reviews Stories/Epics against user requirements and business logic.

## Scope

- **Story Review:** Verify user requirements for that phase/component are fully met
- **Epic Review:** Verify the entire feature meets all requirements end-to-end

## Review Cycle Position

```
macOS Dev -> Code Review -> QA -> Product Review -> CLOSED
                                  [YOU ARE HERE]
```

**Receives from:** QA Agent (via `review_stage: "product-review"`, `review_result: "awaiting"`)
**On PASS:** Clear review fields, mark Story/Epic completed
**On FAIL:** Back to macOS Dev (via `review_result: "rejected"`)

## Arguments

- `[id]` (optional) - Specific Story or Epic to review
  - If provided: Review that Story/Epic
  - If omitted: Show queue of items needing product review

## Focus Areas

When reviewing, verify:
- [ ] Meets ALL user requirements for the Story/Epic scope
- [ ] UX is correct and intuitive across all components
- [ ] Business logic is sound for all functionality
- [ ] Edge cases make sense from user perspective
- [ ] Feature/phase is ready for users
- [ ] No unexpected side effects
- [ ] All components work together as expected

## Delegation

**MUST delegate to PM agent** with this explicit spawn prompt:

```
subagent_type: "pm"
model: "opus", mode: "bypassPermissions"
prompt: "PRODUCT REVIEW for [id].

  0. CHECK APP IS RUNNING (before any Peekaboo work):
     Use mcp__peekaboo__app(command: 'list') to see running apps.
     Look for the app under review in the list.
     If NOT running:
       → Use AskUserQuestion: 'The app needs to be running for visual review.
         Please build and run it in Xcode (Cmd+R), then confirm here.'
       → Wait for user confirmation before proceeding.
     If running: proceed.

  1. TaskGet [id] — get story/epic details
  2. TaskList — find all child stories/tasks
  3. Review ALL acceptance_criteria + local_checks + QA comments
  4. Verify requirements met, UX correct, business logic sound

  ⛔ MANDATORY: PEEKABOO SCREENSHOTS FOR UI STORIES
  ⛔ MUST follow Screenshot Validation Protocol (.claude/skills/tooling/peekaboo/SKILL.md)
  Before you can PASS this review, you MUST:
  a. Create screenshot directory:
     BRANCH=$(git branch --show-current | tr '/' '-' | tr ' ' '-')
     mkdir -p tools/third-party-reviews/${BRANCH}/peekaboo
  b. For EACH UI screen changed:
     1. Verify app has windows:
        mcp__peekaboo__list(item_type: 'application_windows', app: '[app name]',
          include_window_details: ['ids', 'bounds', 'off_screen'])
     2. Focus the app window:
        mcp__peekaboo__window(action: 'focus', app: '[app name]')
        mcp__peekaboo__sleep(duration: 1)
     3. Capture with app_target:
        mcp__peekaboo__see(app_target: '[app name]',
          path: 'tools/third-party-reviews/${BRANCH}/peekaboo/[ScreenName]-[state].png')
     4. VALIDATE the screenshot (MANDATORY — do NOT skip):
        mcp__peekaboo__analyze(
          image_path: 'tools/third-party-reviews/${BRANCH}/peekaboo/[ScreenName]-[state].png',
          question: 'Does this show the [app name] application window with UI visible? Describe briefly. Say INVALID if not.')
        → If INVALID: re-focus and retry (max 2x), then report failure
  c. Create manifest: tools/third-party-reviews/${BRANCH}/peekaboo/manifest.md
     with a table: Screenshot | Screen | State | Journey | Validated
     (Validated column = 'Yes' only if analyze confirmed the screenshot shows the app)
  d. Run: .claude/scripts/verify-review-artifacts.sh --level story --peekaboo
     If this fails, you CANNOT pass the review.

  If Peekaboo MCP is unavailable, note it in your comment but DO NOT skip — report
  'Peekaboo unavailable' so the coordinator can handle it.

  5. Make decision: PASS or FAIL
  Follow the full /product-review protocol for TaskUpdate format.

  Return: PASS or FAIL with summary"
```

---

## Flow

### If no id provided:

Use `TaskList` to find Stories/Epics awaiting product review:

```
TaskList -> filter where:
  - metadata.type is "story" OR metadata.type is "epic"
  - metadata.review_stage == "product-review" AND metadata.review_result == "awaiting"
```

Display:
```
Product Review Queue (2 items):

1. [story-abc] Phase 1: Core Data Model Setup
   Type: story | Priority: P1 | Tasks: 5 | QA Passed: 2024-01-16

2. [epic-def] User Authentication Feature
   Type: epic | Priority: P0 | Stories: 3 | QA Passed: 2024-01-15

Run /product-review [id] to review a specific Story or Epic.
```

### If id provided:

1. **Get Story/Epic details**
   ```
   TaskGet [id]
   ```

2. **Understand full scope**
   - For Story: Review the Story description and all child Tasks
   - For Epic: Review the Epic, all Stories, and all Tasks

3. **Review against requirements**
   - Check original acceptance criteria (Stories/Epics use structured `acceptance_criteria`, Tasks use `local_checks`)
   - Read QA PASSED comment for what was tested
   - Verify UX matches expectations for the entire scope
   - Confirm business logic is correct across all components
   - Test the feature/phase yourself if needed

4. **Journey Verification via Peekaboo (MANDATORY for UI stories)**

   ⛔ **Every UI screen changed in this story/epic MUST have a screenshot saved to disk.** This is a hard gate — product review cannot pass without screenshot evidence.

   **Setup:**
   ```bash
   BRANCH=$(git branch --show-current | tr '/' '-' | tr ' ' '-')
   SCREENSHOT_DIR="tools/third-party-reviews/${BRANCH}/peekaboo"
   mkdir -p "$SCREENSHOT_DIR"
   ```

   **For each UI screen changed:**
   ```
   mcp__peekaboo__image:
     app_target: "[app name]"
     path: "tools/third-party-reviews/${BRANCH}/peekaboo/[screen-name]-[state]"
     format: "png"
   ```

   **Naming convention:** `[ScreenName]-[state].png`
   - `LoginView-idle.png`, `LoginView-error.png`
   - `DashboardView-loaded.png`, `DashboardView-empty.png`
   - `SettingsView-default.png`

   **Journey walkthroughs:** If the epic/story references a UX Flows document (`planning/notes/[epic-name]/ux-flows.md`):
   - For each journey (J1, J2...) in the UX Flows: walk the scenario via Peekaboo, verifying each step matches the Gherkin specification
   - Save a screenshot at each key journey milestone
   - Reference spec IDs (SM-*, IS-*, J*) in review comments when noting pass/fail
   - Check traceability table (Section 9) completeness

   **After all screenshots captured, create a verification manifest:**
   ```bash
   # List all screenshots with what they verify
   cat > "$SCREENSHOT_DIR/manifest.md" << 'EOF'
   # Peekaboo Screenshot Manifest

   | Screenshot | Screen | State | Journey | Verified |
   |---|---|---|---|---|
   | LoginView-idle.png | LoginView | idle | J1-S1 | Pass |
   | LoginView-error.png | LoginView | error | J1-S3 | Pass |
   | DashboardView-loaded.png | DashboardView | loaded | J2-S1 | Pass |
   EOF
   ```

   **If Peekaboo unavailable:** Note "Peekaboo unavailable — screenshot evidence deferred to Human UAT" in review comment. This does NOT block product review, but the coordinator will flag it.

   **PM comment template:** Include screenshot count and journey verification:
   ```
   "Journey verification: J1 pass (3 screenshots), J2 pass (2 screenshots).
    Screenshots: [N] saved to tools/third-party-reviews/[branch]/peekaboo/
    Traceability: X/Y specs linked."
   ```

5. **Verify screenshot evidence**

   ```bash
   .claude/scripts/verify-review-artifacts.sh --level story
   ```
   This now also checks for Peekaboo screenshots in the review directory. If UI screens were changed but no screenshots exist, verification fails.

6. **Make decision: PASS or FAIL**

### PASS - Product Review Approved (Final)

Update Story/Epic:
- Clear `review_stage` to `null` and `review_result` to `null`
- Add review comment to metadata.comments
- Set status to "completed"

For Stories, also update all child Tasks to completed (if not already).

```
TaskUpdate [id]
  status: "completed"
  metadata.review_stage: null
  metadata.review_result: null
  metadata.comments: [...existing comments, {
    "id": "[generated-uuid]",
    "timestamp": "[ISO 8601 timestamp]",
    "author": "pm-agent",
    "type": "product-review-passed",
    "content": "PRODUCT REVIEW PASSED\n\n**Scope reviewed:** [Story/Epic] with [N] tasks\n**Review date:** [current date]\n\n**Story/Epic-level verification:**\n- [x] Meets all user requirements for this scope\n- [x] UX is correct across all components\n- [x] Business logic is sound\n- [x] Ready for users\n\n**Components verified:**\n- [task-abc]: [Brief confirmation]\n- [task-def]: [Brief confirmation]\n- [task-ghi]: [Brief confirmation]\n\n**User experience:**\n- Flow is intuitive: [Yes/No + notes]\n- Error handling user-friendly: [Yes/No + notes]\n- Matches design expectations: [Yes/No + notes]\n\n**Notes:**\n[Any observations or follow-up items to track separately]",
  }]
```

Output:
```
Product review PASSED for [story-abc] "Phase 1: Core Data Model Setup"
Story COMPLETED with 5 tasks

Summary:
- Implementation: Complete
- Code Review: Passed
- QA: Passed (12 acceptance criteria verified)
- Product Review: Passed

This Story is now complete.
```

For Epic completion:
```
Product review PASSED for [epic-def] "User Authentication Feature"
Epic COMPLETED

Stories completed: 3
- Phase 1: Core Data Model Setup (5 tasks)
- Phase 2: API Integration (3 tasks)
- Phase 3: UI Implementation (4 tasks)

Total tasks: 12

Summary:
- Implementation: Complete
- Code Review: Passed
- QA: Passed
- Product Review: Passed

This Epic is now complete. Feature is ready for release.
```

### FAIL - Product Review Rejected

Update Story/Epic metadata:
- Set `review_result` to `"rejected"` (review_stage stays `"product-review"`)
- Add rejection comment to metadata.comments

```
TaskUpdate [id]
  metadata.review_stage: "product-review"
  metadata.review_result: "rejected"
  metadata.comments: [...existing comments, {
    "id": "[generated-uuid]",
    "timestamp": "[ISO 8601 timestamp]",
    "author": "pm-agent",
    "type": "product-review-rejected",
    "content": "REJECTED - PRODUCT REVIEW\n\n**Scope reviewed:** [Story/Epic] with [N] tasks\n**Rejection date:** [current date]\n**Rejection stage:** Product Review\n\n**Issues found:**\n\n1. **[Issue title]**\n   - Task: [task-id] (or Story-level or Epic-level)\n   - Description: [What's wrong from user/business perspective]\n   - Expected: [What should happen]\n   - Actual: [What happens now]\n   - Severity: [Blocker | Major | Minor]\n   - User impact: [How this affects users]\n\n2. **[Issue title]**\n   - Task: [task-id]\n   - Description: [What's wrong]\n   - Expected: [What should happen]\n   - Actual: [What happens now]\n   - Severity: [Blocker | Major | Minor]\n   - User impact: [How this affects users]\n\n**Criteria not fully met:**\n- [ ] Story AC [id]: [Why it doesn't meet the bar]\n- [ ] Task [task-id] local_checks[N]: [Why it doesn't meet the bar]\n\n**UX concerns:**\n- [Any UX issues observed across the Story/Epic]\n\n**Tasks requiring fixes:**\n- [task-abc]: [Brief description of needed fix]\n- [task-def]: [Brief description of needed fix]\n\n**Next action:** macOS Dev to fix issues in affected tasks and resubmit Story for code review.",
  }]
```

Output:
```
Product review FAILED for [story-abc] "Phase 1: Core Data Model Setup"
Returned to Dev (review_stage: product-review, review_result: rejected)

Issues found:
1. [Major] task-123: Error message is too technical for end users
2. [Minor] task-124: Success state doesn't provide confirmation feedback
3. [Major] Story-level: Navigation flow is confusing between steps

User impact:
- Users may be confused by error messages
- Users won't know their action succeeded
- Users may get lost in the multi-step flow

Next: macOS Developer Agent will fix affected tasks and resubmit Story via /fix
```

## Field Reference

| Fields | Meaning | Your Action |
|--------|---------|-------------|
| `review_stage: "product-review"`, `review_result: "awaiting"` | Ready for you | Review the Story/Epic |
| `review_stage: "product-review"`, `review_result: "rejected"` | Back to dev | You set this on FAIL |
| `review_stage: null`, `review_result: null` (completed) | Review passed | You clear fields and complete on PASS |

## Task Tool Reference

```
# Find Stories/Epics needing product review
TaskList -> filter:
  - metadata.type in ["story", "epic"]
  - metadata.review_stage == "product-review" AND metadata.review_result == "awaiting"

# Get Story/Epic details with comments
TaskGet [id]

# Find child tasks of a Story
TaskList -> filter metadata.parent = [story-id]

# Find child Stories of an Epic
TaskList -> filter metadata.parent = [epic-id] AND metadata.type = "story"

# PASS - complete the Story/Epic
TaskUpdate [id]
  - Set metadata.review_stage to null
  - Set metadata.review_result to null
  - Set status to "completed"
  - Add comment to metadata.comments (8-field structured format)

# Also complete all child tasks (for Story)
For each task in Story:
  TaskUpdate [task-id]
    - Set status to "completed" (if not already)

# FAIL - return to dev
TaskUpdate [id]
  - Keep metadata.review_stage as "product-review"
  - Set metadata.review_result to "rejected"
  - Add comment to metadata.comments (8-field structured format)
```

## Never

- Approve work that doesn't meet user requirements
- Skip reviewing the QA PASSED comment
- Approve without checking ALL criteria (Story `acceptance_criteria` AND Task `local_checks`)
- Close Stories/Epics without proper review comment
- Approve Epic without verifying all Stories work together
- Skip testing the actual feature yourself for important releases
