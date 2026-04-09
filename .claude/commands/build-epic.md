---
description: Autonomously build an entire epic — coordinator manages all tasks and reviews directly
argument-hint: epic ID (required)
---

# /build-epic Command

Build an entire epic by managing tasks and reviews directly from the coordinator. Independent stories within the same dependency wave run in parallel; waves are sequential.

## Signature

```
/build-epic <epic-id>
```

---

## Architecture: Coordinator-Managed (Flat)

The coordinator spawns ALL agents (task + review). No intermediate story coordinators.

- **Flat orchestration** — Coordinator spawns task agents + review agents directly
- **Task-based polling** — Agents update task metadata; coordinator polls via task CLI
- **Build-only agents** — Task agents run build verification only (prefer Xcode MCP when available). QA runs tests at story level
- **Parallel stories within waves** — Independent stories dispatched concurrently; tasks up to `max_parallel_tasks` per story (default: 2, max: 4)
- **Compaction gates** — After each wave, suggest `/compact` if context is large

Sub-agents CANNOT spawn sub-sub-agents. TaskOutput returns ~8k tokens per call — never use it.

For workflow state field values: see `.claude/rules/global/task-state-updates.md` and `.claude/docs/WORKFLOW-STATE.md`.

---

## Agent Strategy: Foreground (No Polling)

```
✅ All agents run in FOREGROUND (no run_in_background). They return their result directly.
⛔ NEVER use TaskOutput — ~8k tokens per call.

IMPLEMENTATION: Spawn Task tool without run_in_background → returns ONE-LINE summary
REVIEWS:        Spawn Task tool without run_in_background → returns "PASS" or "FAIL"
PARALLEL TASKS: Spawn 2 Task tools in the SAME message → both return concurrently

CONTEXT CHECKS (when needed):
  .claude/scripts/task summary              (overview, ~150 tokens)
  .claude/scripts/task field <id> <path>    (any field, ~50 tokens)
  .claude/scripts/task check <id>           (status, ~50 tokens)
```

---

## Execution Flow

> THE LOOP DOES NOT END WHEN TASKS ARE IMPLEMENTED. Each story goes through: Implementation → Code Review → QA → Product Review.

### Pre-Flight: MCP Detection (MANDATORY)

Before starting any work, detect MCP availability. This determines the build/test commands for ALL spawn prompts.

```bash
# Step 1: Full dependency check
.claude/scripts/check-mcp-deps.sh build-epic

# Step 2: Detect Xcode MCP specifically
if .claude/scripts/detect-xcode-mcp.sh >/dev/null 2>&1; then
  XCODE_MCP=true
else
  XCODE_MCP=false
fi
```

**Act on the exit code of check-mcp-deps.sh:**
- **Exit 1 (any tool missing):** HARD STOP. Show the full output including install commands. Do NOT proceed until the user fixes all missing dependencies and re-runs the check.
- **Exit 0:** All dependencies available, continue normally.

All CLI tools (gitleaks, swiftlint, jq) and MCP servers (Xcode, Peekaboo, Aikido, Trivy) are required. This prevents agents from building tasks only to have commits, reviews, or QA blocked downstream.

**Store XCODE_MCP for all spawn prompts.** The coordinator decides build/test method once; agents receive the concrete command:

| XCODE_MCP | Build command | Test command |
|---|---|---|
| `true` | `mcp__xcode__BuildProject` | `mcp__xcode__RunSomeTests` / `mcp__xcode__RunAllTests` |
| `false` | `xcodebuild build -scheme [AppName] -destination 'platform=macOS'` | `xcodebuild test -scheme [AppName] -destination 'platform=macOS'` |

**Agents receive ONE concrete command — not an if/else.** The coordinator decides; agents execute.

### Step 0: Ensure Epic Branch (MANDATORY)

1. Read epic metadata: `TaskGet <epic-id>` — extract `metadata.branch` field
2. If `metadata.branch` is empty/null, construct: `epic/<epic-id>-<slugified-name>`
3. **Run the branch setup script:**
   ```bash
   .claude/scripts/ensure-epic-branch.sh <branch-name>
   ```
4. Verify: `git branch --show-current` must return the epic branch
5. If verification fails → HARD STOP, do not proceed to Step 1

### Step 1: Validate Epic

```
TaskGet <epic-id>
Verify: type="epic", has child stories, approval=="approved"
Collect story IDs and blockedBy relationships
```

### Step 2: Build Dependency Graph

```
Wave 1: Stories with NO blockers
Wave 2: Stories blocked by Wave 1
Wave 3: Stories blocked by Wave 2
...
```

**Within a wave:** Process UI/surface stories before infrastructure/database stories (surfaces first).

### Step 3: Design Phase (Conditional)

## Phase A: Design (Conditional)

### Step A0: Design Scope Classification

Read epic metadata fields: `design_scope`, `screens`, `journeys`.

| Classification | Condition | Behavior |
|---|---|---|
| **FULL_DESIGN** | `design_scope: "full_design"` OR epic has `screens` entries and new features | Full: user Q&A, UX Flows authored, design specs created |
| **DESIGN_UPDATE** | `design_scope: "design_update"` OR epic modifies existing screens | Partial: update existing UX Flows sections, minimal user Q&A |
| **NO_DESIGN** | `design_scope: "no_design"` AND epic has zero UI tasks (no Views, no ViewModels with UI state) | Skip A1-A3, log "DESIGN PHASE SKIPPED: [reason]" comment on epic, set `design_phase_complete: true`, proceed to Phase B |

⛔ **NO_DESIGN requires ALL of these:** backend-only, no new views, no modified views, no new screens. If ANY task creates or modifies a `.swift` file in `Views/` or `Components/`, the epic is NOT no_design. Default to DESIGN_UPDATE when uncertain.

Classification heuristics (when `design_scope` not set):
- Epic has `screens` entries → FULL_DESIGN
- Epic creates ANY new views or modifies existing views → DESIGN_UPDATE (minimum)
- Epic description says "refactor/migrate/upgrade/optimize" with no screen refs AND no view files → NO_DESIGN
- Uncertain → DESIGN_UPDATE (cheaper than FULL, safer than NO)
- **Never classify as NO_DESIGN if the epic has UI tasks.** A team view, a settings screen, a dashboard, a list view, any visible UI = at least DESIGN_UPDATE.

### Step A1: Load or Create UX Flows

- Read epic's `ux_flows_ref` field
- If it points to a per-epic doc that EXISTS (e.g., `planning/notes/[epic-name]/ux-flows.md`):
  → Use it. Created during `/epic` and human-approved. Proceed to A2.
- If `ux_flows_ref` is empty or doc doesn't exist (fallback for manually created epics):
  → Create `planning/notes/[epic-name]/` directory
  → Spawn designer to create Level 1 doc from template + project-level baseline at `planning/[app-name]/UX_FLOWS.md`
  → Set `ux_flows_ref` on epic to `planning/notes/[epic-name]/ux-flows.md`

### Step A2: Designer Phase

Spawn Designer agent (`/design` with epic context). The designer MUST produce TWO mandatory outputs:

**Output 1: SwiftUI skeleton code** for every new/modified view
- Load aesthetics reference (`design-system/references/swiftui-aesthetics.md`)
- FULL_DESIGN: Create design specs with SwiftUI skeleton code for each screen. Each spec includes: layout structure, typography hierarchy (2x+ size contrast), color strategy (where accent goes), material usage, and the one signature animation. Specs saved to `planning/design/[screen]-spec.md`.
- DESIGN_UPDATE: Read existing designs, update with SwiftUI skeleton code for modified views.

**Output 2: EARS specs and state machine tables** in the UX Flows doc (MANDATORY)
- ⛔ **EARS specs are NOT optional.** Every interactive element on every screen in scope MUST have an EARS interaction spec in UX Flows Section 4.
- Fill in UX Flows Section 3 (state machine transition tables) for each screen — every state, every transition, every guard condition, every visual outcome.
- Fill in UX Flows Section 4 (EARS interaction specs) for each screen — every button, every keyboard shortcut, every form interaction, every error state.
- Fill in UX Flows Section 5 (modal/sheet flows) for every modal, sheet, and dialog.
- Update UX Flows Section 2 (user journeys) with Gherkin scenarios for the epic's journeys.

**The designer's output is SwiftUI code that compiles AND testable specs that visual-qa can verify.** Not wireframes, not descriptions, not "use appropriate spacing." Copy-paste-ready skeleton views with exact design system values, plus EARS specs that define exactly what each interaction should do.

⛔ **Do NOT proceed to Phase B for UI stories until BOTH exist:** (1) design specs with SwiftUI skeletons AND (2) EARS specs + state machines in UX Flows. Backend-only stories MAY proceed immediately. The dev agent implements against the skeleton; the visual-qa agent tests against the EARS specs.

### Step A3: Design Feasibility Review

Spawn Staff Engineer to review design:
- **State machine completeness** — all states have exit transitions, no orphaned states
- **EARS spec coverage** — every interactive element has a spec, every keyboard shortcut documented
- **Interaction spec feasibility** — can be implemented with SwiftUI
- **macOS conventions compliance** — platform checklist items addressed
- **Performance implications** of proposed interactions
- **Testability** — can visual-qa agent verify each EARS spec via Peekaboo? (must be triggerable + observable)
- If issues found: return to A2 with feedback

⛔ **Review MUST verify EARS specs exist.** If Section 4 of UX Flows is empty or has only placeholders for screens in scope, reject and return to A2.

### Step A4: Mark Design Complete

Verify:
- [ ] SwiftUI skeletons exist for all screens in scope
- [ ] UX Flows Section 3 has state machine tables for all screens
- [ ] UX Flows Section 4 has EARS specs for all interactive elements
- [ ] UX Flows Section 5 has modal/sheet flows for all dialogs
- [ ] Staff Engineer review passed

Set epic `design_phase_complete: true`. Proceed to story/task creation (Phase B).

---

### Step 4: Execute Waves (Parallel Story Dispatch)

Read `max_parallel_tasks` from epic metadata (default: 2, max: 4). This controls per-story task parallelism.

For each wave:

#### Step 4a: Pre-Dispatch Analysis

1. **Classify stories** in this wave:
   - **HAS_UI**: Any task creates/modifies files in `Views/`, `Components/`, or references design specs → requires design phase complete
   - **NO_UI**: All tasks are services, models, Core Data, infrastructure → can start during design phase

2. **Check file overlap** across stories in this wave:
   ```bash
   .claude/scripts/story-overlap-check.sh <story-id-1> <story-id-2> ...
   ```
   - `DISJOINT` → safe to parallelize all stories
   - `OVERLAP:<id1>:<id2>` → serialize those two, parallelize the rest
   - Script unavailable or error → serial fallback (safe default)

3. **Determine dispatch groups:**
   - Group 1: Stories that can run in parallel (disjoint files)
   - Group 2+: Stories that must wait (overlap with Group 1)
   - Within each group, stories run their full lifecycle concurrently

#### Step 4b: Parallel Story Lifecycle

Each story progresses independently through: **Build → Verify → Submit → Review**.
Stories in the same dispatch group CAN be at different lifecycle phases simultaneously:

```
Story A: ████ build ████ code-review ████ qa ████ product-review ████
Story B:   ████ build ████ code-review ████ qa ████ product-review ████
Story C:        ████ build ████ code-review ████ qa ████ product-review ████
```

**Dispatch in batches.** Each coordinator turn, spawn agents across ALL active stories in the current dispatch group:

```
WHILE any story in wave has status != "completed":

  Collect dispatchable agents across ALL unblocked stories:
  - Stories in BUILD: next unstarted tasks (up to max_parallel_tasks per story)
  - Stories done building: VERIFY comments, then SUBMIT for review
  - Stories in REVIEW (awaiting): next review agent
  - Stories REJECTED: fix agent

  Spawn ALL collected agents in ONE message.
  All return directly (foreground). No polling.

  Advance each story's state based on returned results.
  Display: "[story-id]: [phase] → [result]"

END WHILE
```

**No hard cap on concurrent agents.** All unblocked stories in the wave dispatch simultaneously. Prioritize: fix agents > review agents > build agents (unblock before building more).

#### Per-Story Phases

**Phase B — Build Tasks (max `max_parallel_tasks` per story, in parallel)**

Spawn implementation agents (FOREGROUND — returns directly):
```
subagent_type: "macos-developer" (or "data-architect-agent" for DB)
model: "sonnet", mode: "bypassPermissions"
⛔ Do NOT set run_in_background.
prompt: "BUILD TASK [task-id]: [subject]
  1. TaskGet [task-id] — read description, local_checks, files
  2. Claim task (status: in_progress)
  3. FOR UI TASKS: Read the design spec at planning/design/[screen]-spec.md. Use the SwiftUI skeleton as your starting point. Load design-system/references/swiftui-aesthetics.md. Do NOT invent the visual layout — follow the skeleton.
  4. Implement following MVVM patterns
  5. Write XCTest files (deferred to QA)
  6. Build verification only — NOT test:
     [BUILD_COMMAND from pre-flight — coordinator inserts the concrete command]
     ⛔ Use exactly the command provided. Do NOT switch methods.
  7. Stage and commit changes:
     git add [changed files]
     git commit -m "feat(scope): description (task-[task-id])"
     If git-guards blocks the commit, fix issues and retry.
  8. Add IMPLEMENTATION + TESTING comments (include commit hash)
  9. Mark completed
  9. ⛔ VERIFY: TaskGet [task-id] — confirm status==completed and comments exist. Retry up to 3x. Do NOT exit until verified.
  Return only: DONE"
```

When batching across stories: spawn tasks from different stories in the SAME message. Both return directly. No polling.

**Phase C — Verify Comments**

For each child task: confirm `type:"implementation"` and `type:"testing"` comments exist. If missing, spawn cleanup agent.

**Phase D — Integration Test + Submit Story**

Before submitting for review, run the full test suite to catch cross-story regressions:
```
Run full test suite using [TEST_COMMAND from pre-flight detection]
If new failures appear that weren't present before this story's tasks:
  → Fix in the current story's scope before submitting
  → These are regressions caused by this story's changes
```

Then submit:
```
TaskUpdate [story-id]: review_stage="code-review", review_result="awaiting" + handoff comment
```

**Phase E — Review Cycle (per story, concurrent across stories)**

| Stage | Agent(s) | Model | Pass action | Fail action |
|-------|----------|-------|-------------|-------------|
| code-review | staff-engineer + coderabbit (parallel) | sonnet | stage→qa, result→awaiting | result→rejected |
| qa | qa + visual-qa (parallel, if UI story) | sonnet | stage→product-review, result→awaiting | result→rejected |
| security | security-audit (orchestrated) | sonnet+opus | stage→product-review, result→awaiting | result→rejected |
| product-review | pm | sonnet | result→passed | result→rejected |

**QA stage — conditional visual-qa:**

Check story metadata for `ux_screens`. If populated → UI story → spawn both agents in the SAME message:

1. **QA** (headless tests): `subagent_type: "qa"` — runs tests (MCP or xcodebuild per pre-flight), verifies acceptance criteria
2. **Visual QA** (Peekaboo): `subagent_type: "visual-qa"` — launches app, tests EARS specs, walks journeys, screenshots

Both must PASS for the story to advance. If visual-qa FAIL → story rejected with visual findings.
If story has no `ux_screens` → only headless QA runs.

**Concurrent reviews:** While Story A is in QA, Story B can enter code-review. Review agents operate on a single story's code and update only that story's metadata. The coordinator batches review agents from different stories in the same spawn message.

**⛔ ALL review agent spawn prompts MUST include these lines:**
```
⛔ Do NOT read rules files or scripts. Go directly to your review.
⛔ Use ONLY TaskGet and TaskUpdate for task operations. NEVER use Write/Edit on task JSON files.
⛔ VERIFY WRITE: After TaskUpdate, call TaskGet to confirm fields persisted. Retry up to 3x. Do NOT exit until verified.
```

**Code review stage — spawn BOTH agents in the SAME message (parallel):**

1. Staff-engineer (subagent_type: "staff-engineer", sonnet, bypassPermissions):
   ```
   CODE REVIEW Story [story-id]
   [standard review prompt from build-story.md Step 4, including Aikido scan step]
   ⛔ SAVE AIKIDO OUTPUT: echo "<full aikido output>" | .claude/scripts/save-review.sh aikido
   ```

2. CodeRabbit (subagent_type: "coderabbit:code-reviewer", sonnet, bypassPermissions):
   ```
   CODERABBIT REVIEW for Story [story-id]
   Review ALL code changes on the current branch vs main.
   Focus on: security issues, logic errors, concurrency bugs, architecture problems.
   ⛔ SAVE OUTPUT: echo "<full coderabbit output>" | .claude/scripts/save-review.sh coderabbit
   After review, add a comment to the story task [story-id] with your findings:
     TaskGet [story-id] first, then TaskUpdate with appended comment:
     {type: 'review', author: 'coderabbit-agent', content: 'CODERABBIT REVIEW\n\n[findings]'}
   Return only: CLEAN, or FINDINGS ([N] critical, [N] high)
   ```

→ Both return directly. If staff-engineer FAIL → rejected.
→ If CodeRabbit reports ANY findings:
  Apply **CodeRabbit Findings Triage Protocol** (`.claude/rules/global/coderabbit-triage.md`):
  Triage all findings → present batch table to user → user decides → execute.
→ If staff-engineer PASS and user approves CodeRabbit triage → verify review artifacts → proceed to QA.

**Review artifact verification (before advancing to QA):**
```bash
.claude/scripts/verify-review-artifacts.sh --level story
```
If INCOMPLETE → re-run the review agent that missed saving its output.
The review-gate hook also enforces this on the TaskUpdate call itself.

**Security audit orchestration (epic-level only):**
```
IF review_stage == "security" AND review_result == "awaiting":
  Run /security-audit [epic-id] (this handles the 4-agent orchestration)
```

If rejected: spawn fix agent (macos-developer, sonnet) → resets to code-review/awaiting.

After 3 rejections at same stage → flag for human, STOP.

All review agents run in FOREGROUND — they return "PASS" or "FAIL" directly. No polling needed.

#### Step 4c: Verify Peekaboo Screenshots (UI stories)

After product review passes for each story, if the story has UI components (`ux_screens` populated or tasks touching Views/):

```bash
.claude/scripts/verify-review-artifacts.sh --level story --peekaboo
```

If screenshots are missing → the PM didn't capture evidence during product review. Re-run product review for that story with explicit Peekaboo instructions.

#### Step 4d: Wave Completion

Wave is complete when ALL stories in the wave have `review_result == "passed"` AND Peekaboo verification passed for UI stories.
Only then advance to the next wave (if any). Log: `"Wave [N] complete: [story-ids]. Starting Wave [N+1]."`

### Step 5: Present Human UAT

After ALL stories pass product review:

1. Mark all stories `status="completed"`, `review_stage=null`, `review_result=null`
2. Run full test suite (spawn QA agent with [TEST_COMMAND from pre-flight detection])
   - **No Untracked Failures Gate:** If any tests fail, each failure must be either fixed (if caused by this epic) or have a Bug/TechDebt task **immediately created via TaskCreate** (if pre-existing). ⛔ Never dismiss a failure as "pre-existing" without filing a task. The epic CANNOT close with untracked failures. Log filed task IDs in the epic completion comment. See `.claude/docs/TESTING-POLICY.md` § Pre-Existing Test Failures.
3. **Pre-merge security delta check:**
   ```bash
   .claude/scripts/security-scope.sh $(git diff --name-only main...HEAD)
   ```
   If `SECURITY_REVIEW_REQUIRED` → run `/security-audit delta` before proceeding
4. Set epic: `review_stage="human-uat"`, `review_result="awaiting"`
5. Run `/backup [epic-id]-pre-uat`
6. Compile implementation summary from task comments
7. Generate UAT test plan from story acceptance criteria
8. Present UAT review to the user

### Step 6: STOP — Hand Off to User

**`/build-epic` ends here.** Do NOT mark the epic completed or finalize the branch.

Tell the user:

```
"All stories have passed their review cycles. The epic is now in Human UAT.

Take your time testing. When you find issues, use:
  /bug         — file a bug you found during testing
  /fix         — fix a rejected item
  /design      — rework UI you don't like
  /build       — build a new task (tech debt, polish, etc.)

When you're satisfied, run:
  /complete-epic [epic-id]

That will verify everything is clean, finalize the branch, and close the epic."
```

The epic stays on the epic branch with `review_stage: "human-uat"` until the user runs `/complete-epic`.

---

## Testing Strategy

```
LAYER 1: Task Agents — BUILD ONLY (~1-2 min)
  Write code + test files, run build verification [BUILD_COMMAND from pre-flight]

LAYER 2: QA Agent — TARGETED TESTS per story (~5-10 min)
  [TEST_COMMAND from pre-flight] — targeted to test classes written by task agents

LAYER 3: Full Suite — ONCE per epic (~10-15 min)
  Full regression after all stories pass reviews
```

---

## Session Boundary

After 2+ completed stories, or if auto-compaction has fired, suggest stopping:

```
"Story [ID] complete. Recommend new session to avoid context pressure.
To continue: /build-story [NEXT-STORY-ID]
Remaining: [list]"
```

---

## Context Budget (coordinator, using task CLI)

~7,750 tokens total for a 5-story epic (vs ~120k with old TaskOutput approach).

---

## Handling Edge Cases

- **Blocked stories** — handled by wave system
- **Stuck agent** — after 30min no change, spawn NEW fix agent with short error summary. See `.claude/skills/workflow/error-recovery/SKILL.md` for recovery prompt templates.
- **Agent didn't update state** — spawn staff-engineer agent to investigate: "TaskGet [story-id], read comments, identify what went wrong, fix the workflow state." NEVER fix state yourself.
- **Circular rejections** — 3 rejections at same stage → human intervention
- **Partial failure** — report which passed/failed, user decides

## Coordinator Guardrails

⛔ **The coordinator MUST NOT run these tools directly, even when agents fail:**
- `mcp__xcode__BuildProject`, `mcp__xcode__RunAllTests`, `mcp__xcode__RunSomeTests`
- Build/test: MCP (`BuildProject`, `RunSomeTests`, `RunAllTests`) or `xcodebuild` CLI (per pre-flight detection)
- `Read`/`Edit`/`Write` on `.swift` files
- `swiftlint`, `.claude/scripts/build.sh`, `.claude/scripts/test.sh`

**When an agent fails or doesn't complete cleanly:**
1. Do NOT take over and run the tools yourself
2. Spawn a NEW agent (macos-developer for build issues, qa for test issues, staff-engineer for state issues)
3. Use the error-recovery skill templates to keep the spawn prompt under 500 words
4. If 3 recovery attempts fail, STOP and ask the human

---

## Cross-References

- Single task: `.claude/commands/build.md`
- Single story: `.claude/commands/build-story.md`
- Fix rejected: `.claude/commands/fix.md`
- Agent Teams: `.claude/commands/build-epic-team.md`
- Task state protocols: `.claude/rules/global/task-state-updates.md`
