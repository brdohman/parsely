---
description: Build all tasks in a story and run full review cycle (code review → QA → product review)
argument-hint: story ID (required, e.g., CASHFLOW-202)
---

# /build-story Command

Build all tasks in a story by delegating each task and review stage to sub-agents. The coordinator stays lightweight — it spawns agents, polls task status to detect completion, and advances workflow state.

## Signature

```
/build-story <story-id>
```

**Arguments:**
- `story-id` (required): The story task ID to build completely

---

## Constraint: Main Conversation Only

This command can ONLY run from the **main conversation** (not from a sub-agent). The coordinator spawns task and review agents via the `Task` tool, which is only available to the main conversation. Sub-agents do not have the `Task` tool and cannot spawn sub-sub-agents.

If you need to build a story from within `/build-epic`, the epic coordinator runs the build-story protocol inline (it does not delegate to a story coordinator agent).

---

## Pre-Flight: MCP Detection (MANDATORY)

Before starting any work, detect Xcode MCP availability. This determines the build/test commands used in ALL spawn prompts.

```bash
# Step 1: Check MCP availability
.claude/scripts/check-mcp-deps.sh build

# Step 2: Detect Xcode MCP specifically
if .claude/scripts/detect-xcode-mcp.sh >/dev/null 2>&1; then
  XCODE_MCP=true
else
  XCODE_MCP=false
fi
```

**Show the check-mcp-deps output to the user.** If any MCP servers are missing:
- List what's unavailable and what's degraded
- Ask: "Some MCP dependencies are unavailable. Proceed with fallbacks, or fix first?"
- If the user proceeds, note degraded capabilities in the story's comments

**Store the detection result.** Use it to set concrete commands in spawn prompts:

| XCODE_MCP | Build command | Test command |
|---|---|---|
| `true` | `mcp__xcode__BuildProject` | `mcp__xcode__RunSomeTests` |
| `false` | `xcodebuild build -scheme [AppName] -destination 'platform=macOS'` | `xcodebuild test -scheme [AppName] -destination 'platform=macOS' -only-testing:...` |

**Agents receive ONE concrete command — not an if/else.** The coordinator decides; agents execute.

---

## What It Does

Unlike `/build` (single task) or `/build-phase` (tasks only, no reviews), this command:

1. **Delegates ALL tasks** to sub-agents (max `max_parallel_tasks` parallel, default 2, max 4 — read from parent epic metadata)
2. **Polls task status** to detect agent completion (lightweight, ~300 tokens per check)
3. **Submits story** for code review after verifying comments
4. **Delegates code review** to Staff Engineer sub-agent
5. **Delegates QA** to QA sub-agent
6. **Delegates product review** to PM sub-agent
7. **Handles rejections** — spawns fix sub-agent, restarts review cycle
8. **Completes when story passes product review**

---

## Architecture

```
+---------------------------------------------------------------+
|                  STORY COORDINATOR (you)                        |
|                                                                 |
|  Lightweight orchestration:                                     |
|  - Spawn sub-agents for tasks and reviews                       |
|  - Poll TASK STATUS to detect completion (~300 tok/check)       |
|  - Advance workflow state between stages                        |
|  - Handle rejections by spawning fix agents                     |
+---------------------------------------------------------------+
                              |
        +---------------------+---------------------+
        v                     v                     v
+------------------+  +------------------+  +------------------+
| Task Agent 1     |  | Task Agent 2     |  | Review Agent     |
| (foreground)     |  | (foreground)     |  | (foreground)     |
|                  |  |                  |  |                  |
| Claims, builds,  |  | Claims, builds,  |  | Reviews code,    |
| writes tests,    |  | writes tests,    |  | runs tests,      |
| marks complete   |  | marks complete   |  | updates metadata |
+------------------+  +------------------+  +------------------+

Communication: Agents update TASK METADATA (status, comments).
               Coordinator reads TASK METADATA (not agent transcripts).
```

**You are a COORDINATOR, not an implementer. Never write application code yourself. Always delegate via sub-agents.**

### Coordinator Hard Rules

```
⛔ FORBIDDEN TOOLS (for the coordinator):
  - NEVER use Read, Write, Edit on source/test files (.swift, .ts, .js, etc.)
  - NEVER use Grep/Glob to search source code
  - NEVER fix code, refactor, or "verify code quality" yourself

✅ ALLOWED TOOLS (for the coordinator):
  - TaskGet, TaskList, TaskUpdate (workflow state only)
  - Task (spawn sub-agents)
  - Bash: .claude/scripts/task [command] (task CLI for lightweight status checks)
  - Bash: tail -50 [output_file] (ONLY for diagnosing stuck agents)

⛔ NEVER USE TaskOutput:
  TaskOutput returns the FULL agent transcript (~32k chars / ~8k tokens).
  Three TaskOutput calls can exhaust the coordinator's entire context budget.
  Use .claude/scripts/task CLI instead (~50 tokens per call).

⛔ WHEN AGENTS APPEAR TO FAIL:
  - Do NOT intervene directly — this is the #1 cause of context exhaustion
  - Do NOT read source files "to check what went wrong"
  - Do NOT write code "to finish what the agent started"
  - INSTEAD: Spawn a NEW fix/cleanup sub-agent with a clear prompt
  - If 2 fix agents fail at the same issue → STOP and report to user
  - The coordinator touching source code is ALWAYS wrong
```

### Agent Strategy: Foreground (No Polling)

✅ **All agents run in FOREGROUND.** They return their final message directly to the coordinator (~50-200 tokens). No polling, no sleep loops, no waiting.

```
IMPLEMENTATION AGENTS:
  Spawn via Task tool WITHOUT run_in_background.
  Agent returns: "ONE-LINE: [files created] [build result]"
  Coordinator receives result immediately → moves to next task.
  For parallelism: spawn 2 agents in the SAME message → both run, both return.

REVIEW AGENTS:
  Spawn via Task tool WITHOUT run_in_background.
  Agent returns: "ONE-LINE: PASS or FAIL"
  Coordinator receives result immediately → advances to next stage.
  No polling. No sleep. No wait-field. No TaskGet loops.

CONTEXT CHECKS (when needed):
  Bash: .claude/scripts/task summary              (~150 tokens, overview)
  Bash: .claude/scripts/task field [id] [path]    (~50 tokens, any field)
  Use for context recovery or status checks — NOT for waiting.
```

---

## Execution Flow

### Step 0: Context Recovery (fresh session support)

This command works in both fresh sessions and mid-epic continuations. If invoked as the first
command in a new session (e.g., after `/build-epic` suggested a session break), recover context:

```
1. Bash: .claude/scripts/task summary                    → see all tasks and statuses (~150 tokens)
2. Bash: .claude/scripts/task field <story-id> .metadata.parent  → find parent epic ID
3. Bash: .claude/scripts/task field <story-id> .subject          → confirm story name
4. Identify which child tasks belong to this story (metadata.parent == story-id)
5. Check which tasks are already completed vs. pending
6. Proceed to Step 1 with this context
```

If this is a continuation within an existing session, skip Step 0 — you already have context.

### Step 1: Validate Story and Branch

⛔ **CONTEXT BUDGET:** You are a lightweight coordinator. Minimize context:
- Use `.claude/scripts/task summary` or **TaskList** to discover child tasks
- Only call **TaskGet** on the story itself (for validation) — prefer `.claude/scripts/task field` for individual fields
- Do **NOT** call TaskGet on individual child tasks — sub-agents read their own details
- Do **NOT** read task descriptions, local_checks, or files — sub-agents do that

```
1. TaskGet <story-id> (or .claude/scripts/task field <story-id> for specific fields)
   - Verify: type = "story"
   - Verify: metadata.approval == "approved" (run /approve-epic if not)
   - Note story subject for display
2. Ensure epic branch:
   - Read parent epic ID: .claude/scripts/task field <story-id> .metadata.parent
   - Read epic branch: .claude/scripts/task field <epic-id> .metadata.branch
   - Run: .claude/scripts/ensure-epic-branch.sh <branch-name>
   - Verify: git branch --show-current matches the epic branch
   - HARD STOP if branch setup fails
3. TaskList -> identify child tasks of this story
   - Extract ONLY: task ID, subject, status, blockedBy
   - Do NOT call TaskGet on individual child tasks
4. Count total tasks, determine dependency order from blockedBy
```

**If validation fails:**
```
VALIDATION FAILED: [reason]

Story [story-id] cannot be built because:
- [specific issue]

To fix:
- [remediation steps]
```

### Step 2: Build All Tasks

```
Using the task summaries from Step 1 (id, subject, status, blockedBy only):
Sort by dependency order. Among unblocked peers, prefer View/ViewModel tasks before Service/Core Data tasks (surfaces first).

Read `max_parallel_tasks` from parent epic metadata (default: 2, max: 4):
  .claude/scripts/task field <epic-id> .metadata.max_parallel_tasks

For each task (max `max_parallel_tasks` in parallel):

  1. Check task status (from TaskList summary):
     - If completed → skip
     - If in_progress → track (already running)
     - If pending → spawn

  2. Spawn implementation sub-agent (FOREGROUND — returns directly):
     Task tool:
       subagent_type: "macos-developer" (or "data-architect-agent" for DB)
       model: "sonnet"
       mode: "bypassPermissions"
       ⛔ Do NOT set run_in_background. Agent runs foreground and returns result directly.
       prompt: "BUILD TASK [task-id]: [subject]

         You are an implementation agent. Read your own task details.

         Instructions:
         1. Read task fully (TaskGet [task-id]) — get description, local_checks, files
         2. Claim task (TaskUpdate status: in_progress)
         3. FOR UI TASKS: Read the design spec at planning/design/[screen]-spec.md if it exists. Use the SwiftUI skeleton as your starting point. Load design-system/references/swiftui-aesthetics.md. Do NOT invent the visual layout — follow the skeleton.
         4. Implement following MVVM patterns
         5. Write test files (XCTest) — tests will be run by QA agent later
         6. Run BUILD ONLY to verify compilation:
            [BUILD_COMMAND from pre-flight detection — coordinator inserts one of:]
              mcp__xcode__BuildProject     ← if XCODE_MCP=true
              xcodebuild build -scheme [AppName] -destination 'platform=macOS'  ← if XCODE_MCP=false
            ⛔ Do NOT run tests — testing is deferred to QA stage.
            ⛔ Do NOT decide build method yourself — use exactly the command provided above.
         6. If build fails, fix compilation errors and rebuild.
         6.5. Stage and commit your changes:
              git add [files you created/modified]
              git commit -m "feat(scope): description (task-[task-id])"
              If git-guards blocks the commit, fix the reported issues and retry.

         ⛔ MANDATORY BEFORE MARKING COMPLETE:
         7. Add IMPLEMENTATION comment to task metadata.comments:
            {
              'id': 'C1',
              'timestamp': '[ISO8601]',
              'author': 'macos-developer-agent',
              'type': 'implementation',
              'content': 'TASK COMPLETED. Files: [list]. Approach: [brief]. Local checks verified: [list each].'
            }

         8. Add TESTING comment to task metadata.comments:
            {
              'id': 'C2',
              'timestamp': '[ISO8601]',
              'author': 'macos-developer-agent',
              'type': 'testing',
              'content': 'Tests written: [file]. Methods: [list]. Build verified. Tests deferred to QA.'
            }

         9. ONLY AFTER adding both comments, mark task completed (status: completed)

         10. ⛔ VERIFY WRITE: After marking completed, call TaskGet [task-id].
             If status is NOT 'completed' or comments are missing, retry TaskUpdate (up to 3 attempts).
             Do NOT exit until TaskGet confirms the write persisted.

         Return only: DONE"

  For parallelism: spawn up to `max_parallel_tasks` agents in the SAME message (multiple Task tool calls).
  All run concurrently. All return DONE. No polling needed.

  All tasks completed when all foreground agents return.
```

### Step 3: Submit Story for Code Review

```
1. Verify all child tasks have status = "completed"

2. ⛔ VERIFY ALL TASKS HAVE REQUIRED COMMENTS
   For each child task:
     TaskGet [task-id]

     Check metadata.comments contains:
     - At least one comment with type: "implementation" or "completion"
     - At least one comment with type: "testing" (unless testable: false)

     If ANY task missing comments -> HARD STOP

3. Set story metadata.review_stage: "code-review", metadata.review_result: "awaiting"
4. Add submission comment to story
```

**If any task missing comments:**
```
⛔ STORY SUBMISSION BLOCKED: Tasks missing required comments

Story [story-id] cannot be submitted for code review.

Tasks with missing comments:
- Task [task-id-1]: Missing implementation comment
- Task [task-id-2]: Missing testing comment

Fix: Re-run implementation agent to add missing comments.
```

### Step 4: Review Cycle Loop

```
WHILE story review_result != "passed" AND story status != "completed":

  1. TaskGet [story-id] to read current state

  2. DETERMINE and EXECUTE appropriate stage:

     IF review_stage == "code-review" AND review_result == "awaiting":
       Spawn BOTH agents in the SAME message (parallel):

       1. Staff-engineer sub-agent (FOREGROUND):
         subagent_type: "staff-engineer"
         model: "sonnet"
         mode: "bypassPermissions"
         ⛔ Do NOT set run_in_background.
         prompt: "CODE REVIEW Story [story-id]
           ⛔ Do NOT read rules files or scripts. Go directly to step 1.
           ⛔ Use ONLY TaskGet and TaskUpdate for task operations. NEVER use Write/Edit on task JSON files.
           ⛔ Do NOT run xcodebuild test or xcodebuild build. Code review is READ-ONLY. Testing is QA's job.
           1. TaskGet [story-id] — read child task IDs from comments
           2. For each child task: TaskGet to read implementation comments and files changed
           3. Read ALL changed .swift files (source AND test files) and review against checklist:
              MVVM, @Observable, async/await, no Combine, no force unwraps, error handling, performance, accessibility, architectural boundaries
              For test files: verify proper assertions, mock patterns, teardown, edge case coverage
           4. Run Aikido scan: collect all changed .swift files from implementation comments, run aikido_full_scan MCP on them.
              CRITICAL/HIGH findings are blockers. MEDIUM/LOW are noted.
              If Aikido MCP unavailable, note 'Aikido scan skipped — MCP unavailable'.
              ⛔ SAVE OUTPUT: After scan completes, save the full results to disk:
              echo "<full aikido output>" | .claude/scripts/save-review.sh aikido
           5. Do NOT run any tests — only read and review the code
           6. Decision:
              If PASS: TaskUpdate — set review_stage: 'qa', review_result: 'awaiting', append CODE REVIEW PASSED comment (include Aikido results)
              If FAIL: TaskUpdate — set review_result: 'rejected', append rejection comment with specific issues per file
           ⛔ VERIFY WRITE: After TaskUpdate, call TaskGet to confirm fields persisted. Retry up to 3x. Do NOT exit until verified.
           Return only: PASS or FAIL"

       2. CodeRabbit review agent (FOREGROUND):
         subagent_type: "coderabbit:code-reviewer"
         model: "sonnet"
         mode: "bypassPermissions"
         ⛔ Do NOT set run_in_background.
         prompt: "CODERABBIT REVIEW for Story [story-id]
           Review ALL code changes on the current branch vs main.
           Focus on: security issues, logic errors, concurrency bugs, architecture problems.
           ⛔ SAVE OUTPUT: After review completes, save the full results to disk:
             echo "<full coderabbit output>" | .claude/scripts/save-review.sh coderabbit
           After review, add a comment to the story task [story-id] with your findings:
             TaskGet [story-id] first, then TaskUpdate with appended comment:
             {type: 'review', author: 'coderabbit-agent', content: 'CODERABBIT REVIEW\n\n[findings summary]\n\nCritical: [N]\nHigh: [N]\nMedium: [N]\nLow: [N]'}
           Return only: CLEAN, or FINDINGS ([N] critical, [N] high)"

       → Both agents return directly. No polling.
       → If staff-engineer says FAIL → story is rejected (staff-engineer already updated state).
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

     IF review_stage == "qa" AND review_result == "awaiting":

       # Check if story has UI components (ux_screens populated)
       HAS_UI = .claude/scripts/task field [story-id] .metadata.ux_screens returns non-empty array

       # ALWAYS spawn headless QA agent:
       Spawn QA sub-agent (FOREGROUND):
         subagent_type: "qa"
         model: "sonnet"
         mode: "bypassPermissions"
         ⛔ Do NOT set run_in_background.
         prompt: "QA TEST Story [story-id]
           ⛔ Do NOT read rules files or scripts. Go directly to step 1.
           ⛔ Use ONLY TaskGet and TaskUpdate for task operations. NEVER use Write/Edit on task JSON files.
           1. TaskGet [story-id] — read acceptance_criteria
           2. TaskGet each child task — read implementation/testing comments to find test class names
           3. Run ONLY story-related tests:
              [TEST_COMMAND from pre-flight detection — coordinator inserts one of:]
                mcp__xcode__RunSomeTests(tests: ['[TestClass1]', '[TestClass2]'])  ← if XCODE_MCP=true
                xcodebuild test -scheme [AppName] -destination 'platform=macOS' -only-testing:[TestClass1] -only-testing:[TestClass2]  ← if XCODE_MCP=false
              ⛔ Use exactly the command provided — do NOT switch methods.
              Full suite + regression is run at the epic level, not here.
           4. Verify each AC with evidence from test results
           5. Decision:
              If PASS: TaskUpdate — set review_stage: 'product-review', review_result: 'awaiting', append QA PASSED comment
              If FAIL: TaskUpdate — set review_result: 'rejected', append rejection comment with failed ACs and steps to reproduce
           ⛔ VERIFY WRITE: After TaskUpdate, call TaskGet to confirm fields persisted. Retry up to 3x. Do NOT exit until verified.
           Return only: PASS or FAIL"

       # IF UI story: spawn visual-qa in the SAME message (parallel with headless QA):
       IF HAS_UI:
         Spawn Visual QA sub-agent (FOREGROUND, in SAME message as headless QA):
           subagent_type: "visual-qa"
           model: "sonnet"
           mode: "bypassPermissions"
           ⛔ Do NOT set run_in_background.
           prompt: "VISUAL QA TEST Story [story-id]
             ⛔ Do NOT read rules files or scripts. Go directly to your execution flow.
             ⛔ Use ONLY TaskGet and TaskUpdate for task operations. NEVER use Write/Edit on task JSON files.
             1. Read story metadata: ux_screens, ux_flows_ref, journeys, acceptance_criteria
             2. Read UX Flows doc — extract EARS specs, state machine transitions, journey steps for screens in scope
             3. Check Peekaboo permissions — FAIL immediately if denied
             4. Launch app, take baseline screenshot
             5. Test each EARS spec: trigger action → verify result → screenshot
             6. Test each state machine transition: trigger event → verify state change → screenshot
             7. Walk each journey end-to-end with Peekaboo
             8. Add VISUAL QA review comment to story with coverage metrics
             Return only: PASS or FAIL ([N] failures)"

       → Both agents return directly (if both spawned). No polling.
       → If headless QA says FAIL → story is rejected (QA already updated state).
       → If headless QA says PASS but visual-qa says FAIL:
         Coordinator sets review_result: 'rejected' with comment:
         "Visual QA failed: [N] visual verification failures. See visual-qa-agent comment for details."
       → If both PASS → proceed to product-review.
       → If only headless QA was spawned (no UI): PASS → proceed to product-review.

     IF review_stage == "product-review" AND review_result == "awaiting":
       Spawn PM sub-agent (FOREGROUND):
         subagent_type: "pm"
         model: "sonnet"
         mode: "bypassPermissions"
         ⛔ Do NOT set run_in_background.
         prompt: "PRODUCT REVIEW Story [story-id]
           ⛔ Do NOT read rules files, scripts, or search for task files. Go directly to step 1.
           ⛔ Use ONLY TaskGet and TaskUpdate tools for task operations. NEVER use Write/Edit on task JSON files.
           1. TaskGet [story-id] — read acceptance_criteria and review comments
           2. Evaluate: Does implementation meet user requirements? Check UX and business logic.
           3. Decision:
              If PASS: TaskUpdate — set review_result: 'passed', append PRODUCT REVIEW PASSED comment (TaskGet first to read existing comments, then append)
              If FAIL: TaskUpdate — set review_result: 'rejected', append rejection comment with specific issues
           ⛔ Do NOT mark story as completed or set status to completed.
           ⛔ VERIFY WRITE: After TaskUpdate, call TaskGet to confirm fields persisted. Retry up to 3x. Do NOT exit until verified.
           Return only: PASS or FAIL"
       → Agent returns directly: "PASS" or "FAIL". No polling.

     IF review_result == "rejected":
       Spawn fix sub-agent (FOREGROUND):
         subagent_type: "macos-developer"
         model: "sonnet"
         mode: "bypassPermissions"
         ⛔ Do NOT set run_in_background.
         prompt: "FIX REJECTED Story [story-id]
           Read rejection feedback from comments.
           Fix all issues identified.
           Verify compilation:
           [BUILD_COMMAND from pre-flight detection — coordinator inserts the concrete command]
           Stage and commit fixes:
             git add [changed files]
             git commit -m "fix(scope): address review feedback (task-[task-id])"
           Set review_stage: 'code-review', review_result: 'awaiting'.
           Add fix comment documenting changes.
           ⛔ VERIFY WRITE: After TaskUpdate, call TaskGet to confirm fields persisted. Retry up to 3x. Do NOT exit until verified.
           Return only: DONE"
       → Agent returns directly. No polling.

  3. READ the agent's return value directly (no polling needed):
     The foreground agent's return message IS the result.
     Parse "PASS" or "FAIL" from the returned text.

     Display: "[story-id]: [stage] → [PASS/FAIL]"

  4. CHECK exit conditions:
     If review_result == "passed" → BREAK
     If rejection count for any stage >= 3 → flag for human, STOP
     Else → CONTINUE loop

END WHILE
```

**Note:** Human verification is NOT required for Stories. It IS required for Epics (see `/complete-epic`). Stories close automatically after product review passes.

### Step 4.5: Verify Peekaboo Screenshots (UI stories)

After product review passes, if the story has UI components (`ux_screens` populated or tasks touching Views/):

```bash
.claude/scripts/verify-review-artifacts.sh --level story --peekaboo
```

If screenshots are missing → the PM didn't capture evidence during product review. Re-run product review with explicit Peekaboo instructions.

### Step 5: Story Complete

```
# Mark story completed (if PM agent didn't already)
TaskGet [story-id]
If status != "completed":
  TaskUpdate [story-id]:
    - status: "completed"
    - review_stage: null
    - review_result: null

Report final summary.
```

---

## Recovery When Agents Fail

**Agent didn't update task state:** Spawn staff-engineer agent to investigate: "TaskGet [story-id], read all child task comments, identify what went wrong, fix the workflow state fields." NEVER fix state yourself.

**Agent didn't complete cleanly:** Spawn a NEW agent using error-recovery skill templates (`.claude/skills/workflow/error-recovery/SKILL.md`). Do NOT run build/test tools yourself as a workaround.

**3 recovery attempts fail:** STOP and ask the human.

## Rejection Handling

### Maximum Rejection Limit

```
If same rejection type occurs 3+ times:
  - Flag story for human review
  - Add comment: "Multiple rejections at [stage] - needs human intervention"
  - STOP and report
```

---

## Context Budget

| Item | Tokens | Notes |
|------|--------|-------|
| Task wait/check (task CLI) | ~50 | Per call |
| 4 tasks × ~2 CLI calls each | ~400 | wait + verify |
| 3 review stages × ~2 CLI calls | ~300 | wait + check result |
| Story validation + state mgmt | ~500 | task summary + TaskUpdate |
| **Total per story** | **~1,200** | |

Compare to old approaches:
- **Old TaskGet polling:** ~10,700 tokens per story (~300/call × many calls)
- **Old TaskOutput approach:** ~25,000+ tokens (3× TaskOutput dumps at 8k each)

---

## Comparison with Other Commands

| Command | Scope | Implementation | Code Review | QA | Product Review |
|---------|-------|----------------|-------------|-----|----------------|
| `/build` | Single task | ✓ | ✗ | ✗ | ✗ |
| `/build-phase` | Story tasks | ✓ | ✗ | ✗ | ✗ |
| `/build-story` | **Story complete** | **✓** | **✓** | **✓** | **✓** |
| `/build-epic` | Entire epic | ✓ | ✓ | ✓ | ✓ |

---

## Cross-References

- **Single task build:** `.claude/commands/build.md`
- **Phase/sequential build:** `.claude/commands/build-phase.md`
- **Full epic build:** `.claude/commands/build-epic.md`
- **Fix rejected items:** `.claude/commands/fix.md`
- **Code review:** `.claude/commands/code-review.md`
- **QA testing:** `.claude/commands/qa.md`
- **Product review:** `.claude/commands/product-review.md`
