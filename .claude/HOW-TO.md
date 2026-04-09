# HOW-TO: Claude Code Tasks Development Workflow

This guide explains the complete development workflow from feature idea to release using Claude Code's built-in Task tools for macOS Swift/SwiftUI development.

**Schema Version:** 2.0 (AI-first schema) - See `.claude/templates/tasks/metadata-schema.md` for complete field reference.

---

## Terminology

| Term | Definition |
|------|------------|
| **Claude Tasks** | The TaskCreate, TaskUpdate, TaskGet, TaskList tool system |
| **Epic** | Top-level initiative (`type: "epic"`) - subject: `Epic: [Name]` |
| **Story** | Phase or component (`type: "story"`) - subject: `Story: [Name]` |
| **Task** | Individual work item (`type: "task"`) - subject: `Task: [Name]` |
| **Schema v2.0** | Current metadata schema with AI-first fields (execution_plan, ai_context, local_checks, etc.) |

---

## Getting Started

### Which Command Do I Use?

| Your Situation | Command | What Happens |
|----------------|---------|--------------|
| Starting from scratch | `/init-macos-project my-app` | Creates Xcode project with full structure |
| Have code, need structure | `/setup` | Adds workflow structure around existing code |
| Have planning docs (PRD, etc.) | `/epic` | Create epic from planning docs |
| Ad-hoc feature (no docs) | `/feature` | Discovery + planning with PM |
| Check current state | `/status` | Shows project and workflow status |

### Quick Start Paths

**Path 1: New Project (Greenfield)**
```
/init-macos-project my-awesome-app
    |
open MyAwesomeApp.xcodeproj
Cmd+R to run
    |
/feature "user preferences"
    |
/build -> /code-review -> /qa -> /product-review -> /archive
```

**Path 2: Existing Codebase**
```
cd my-existing-project
/setup
    |
/status  # verify configuration
    |
/feature "new dashboard"
    |
/build -> /code-review -> /qa -> /product-review -> /archive
```

**Path 3: Planning Docs Workflow (Recommended for Complex Features)**
```
Create planning docs (PRD.md, TECHNICAL_SPEC.md)
    |
/external-review  # Multi-model review (optional)
    |
/epic  # Creates structured epic from docs
    |
/write-stories-and-tasks  # Break into stories/tasks
    |
Human reviews -> /approve-epic  # Approve the whole plan
    |
/build-epic  # Autonomous parallel building
    |
/archive
```

**Path 4: Already Set Up**
```
/status  # check what's ready
    |
/feature "data sync"
    |
/build -> /code-review -> /qa -> /product-review -> /archive
```

---

## Setup Commands Reference

### Infrastructure Setup

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/init-macos-project <name>` | Full Xcode project creation | Starting completely fresh |
| `/setup` | Add workflow structure to existing code | Have code, need organization |

### Dependency Setup

Install all CLI tools and MCP servers:

```bash
./tools/setup-dependencies.sh           # Interactive mode
./tools/setup-dependencies.sh --check   # Check what's installed
./tools/setup-dependencies.sh --all     # Install everything
```

See `tools/dependency-setup.md` for details on each tool and MCP server.

### Maintenance Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/status` | Show project & workflow state | Check what's configured |
| `/update-toolkit` | Update .claude/ to latest | Get new features/fixes |
| `/check-updates` | Quick scan for Claude Code platform changes | Weekly or before a new epic |
| `/deep-dive-updates` | Full analysis of all tracked platform docs | Monthly or after an Anthropic release |
| `/evolve` | Self-audit toolkit against platform capabilities | When planning toolkit improvements |

---

## Agent Delegation Reference

All implementation work is delegated to specialized agents. **Never implement directly.**

| Agent | Handles | Commands |
|-------|---------|----------|
| **Planning** | Epic creation from planning docs | `/epic` |
| **PM** | Feature discovery, product review | `/feature`, `/product-review`, `/pm-loop` |
| **Staff Engineer** | Planning, code review, architecture | `/write-stories-and-tasks`, `/code-review`, `/review-loop` |
| **Designer** | UI specs, visual polish | `/design`, `/ui-polish`, `/design-review` |
| **macOS Developer** | Implementation | `/build`, `/fix`, `/build-loop` |
| **Data Architect** | Core Data / database work | `/build` (DB tasks auto-detected) |
| **QA** | Testing, verification | `/qa`, `/test`, `/checkpoint`, `/qa-loop` |
| **Security** | Security review | `/security-audit` |
| **Build Engineer** | Builds, commits, PRs, archives | `/archive`, `/commit`, `/pr` |

Agent documentation: `.claude/agents/*.md`

### Skill Loading Order

Agents load skills listed in their frontmatter `skills:` field. For agents that need multiple skills, load order matters — later skills can reference concepts from earlier ones.

| Agent | Skills (load order) | Notes |
|-------|-------------------|-------|
| **Designer** | `macos-design-system` → `ui-review-tahoe` → `macos-scenes` → `agent-shared-context` | Design system MUST load before UI review. Load `liquid-glass-design.md` on demand for glass effects. |
| **macOS Developer** | `swiftui-patterns` → `macos-design-system` → `macos-best-practices` → `agent-shared-context` → `story-context` → `xcode-mcp` | Load `frontend-design.md` and `hig-decisions.md` on demand for UI tasks. |
| **Staff Engineer** | `core-data-patterns` → `security` → `architecture-patterns` → `macos-best-practices` → `agent-shared-context` → `story-context` → `xcode-mcp` | Broadest skill set — architecture + security for code review. |
| **QA** | `test-generator` → `agent-shared-context` → `xcode-mcp` → `peekaboo` | Test patterns before shared context. |
| **All other agents** | `agent-shared-context` first, then domain-specific skills | `agent-shared-context` provides shared terminology and workflow reference. |

---

## Build Command Comparison

Choose the right build command for your situation:

| Command | Scope | Implementation | Reviews | Use When |
|---------|-------|----------------|---------|----------|
| `/build [id]` | Single task | ✓ | ✗ | Implementing one task at a time |
| `/build-story [story-id]` | Story complete | ✓ | ✓ | Build story and run full review cycle |
| `/build-epic [epic-id]` | Entire epic | ✓ | ✓ | Autonomous parallel building |
| `/build-loop` | Queue processing | ✓ | ✗ | Continuous implementation mode |

### When to Use Each

- **`/build`** - Fine-grained control, one task at a time
- **`/build-story`** - Complete a story end-to-end (recommended for most work)
- **`/build-epic`** - Hands-off autonomous mode for entire epics
- **`/build-loop`** - Process implementation queue continuously

---

## Design Workflow

**Before building any UI, run the design workflow:**

```
/design [screen-name]    # Create UI spec
    |
/build                   # Implement the design
    |
/ui-polish [screen]      # Visual verification via screenshot
    |
/design-review           # (Optional) Review against principles
```

### Design System

Location: `.claude/skills/design-system/SKILL.md`

The design system provides concrete SwiftUI values:

| Category | Key Values |
|----------|------------|
| **Spacing** | 4pt grid: 4, 8, 12, 16, 24, 32, 48 |
| **Typography** | `.title` → `.headline` → `.body` → `.caption` |
| **Colors** | Semantic: `.primary`, `.secondary`, `.accentColor` |
| **Components** | Stat cards, list rows, forms, empty states |

Sub-files for detailed guidance:
- `spacing-and-layout.md` - Layout patterns, padding, margins
- `typography-and-color.md` - Text styling, color usage
- `components.md` - Reusable component patterns

---

## Permission Model

The project's `.claude/settings.json` uses a broad-allow model: most tools (Read, Write, Edit, Bash, Glob, Grep, Task, WebFetch, WebSearch, Xcode MCP) are allowed by default. Specific dangerous operations are denied (force-push to main, `rm -rf /`, reading `.env`/secrets files, writing to task storage).

This is intentional — agents run with `bypassPermissions` and need shell access for builds, git operations, and script execution. The deny list is the security boundary, not the allow list.

If you need tighter controls for a team environment, narrow the `permissions.allow` list in `.claude/settings.json` and rely on per-agent `permissionMode` instead.

---

## Task Persistence

Tasks persist across sessions automatically when you launch Claude Code with a named task list:

```bash
CLAUDE_CODE_TASK_LIST_ID=my-project claude --dangerously-skip-permissions
```

This pins all sessions to the same task directory (`~/.claude/tasks/my-project/`). No backup/restore cycle needed for day-to-day work.

### Archiving Completed Work

After an epic is completed and passes human UAT, archive the task state for historical records:

```
/backup cashflow-100
```

**What Happens:**
1. All task JSON files are copied to `planning/backups/cashflow-100/`
2. Files can be committed to git for historical reference
3. Useful for post-mortems, audits, or revisiting past decisions

**When to Archive:**
- After an epic passes human UAT and is marked completed
- Before major refactoring of task structure
- As a historical record of task state at a point in time

---

## Advanced Patterns

### Multi-Model External Review

Before creating complex epics, get feedback from Claude, Gemini, and OpenCode:

```
/epic
  → "No external review found. Run multi-model review first?"
  → Yes: Runs /external-review automatically
  → Reviews appear in planning/reviews/
  → Synthesis incorporated into epic risks
```

Or run manually: `/external-review`

### Self-Improving Rules

When Claude makes a mistake, capture the learning:

```
/learn Always check for nil before force unwrapping optionals
```

This adds a rule to the appropriate `.claude/rules/` file.

### Notes for Complex Epics

For epics with 3+ stories, maintain persistent notes:

```
planning/notes/[epic-name]/
├── context.md          # Background, goals, constraints
├── decisions.md        # Decisions made and why
├── open-questions.md   # Unresolved questions
└── progress.md         # What's done, what's next
```

Notes survive context clearing and session restarts.

### Subagent Delegation

Agents should spawn subagents for discrete tasks:

```
Main Agent
├── Subagent 1: Research existing patterns
├── Subagent 2: Implement ViewModel
├── Subagent 3: Implement View
└── Subagent 4: Write tests
```

See `.claude/skills/workflow/spawn-subagents/SKILL.md` for details.

### Verification-First Fixes

When fixing rejected items, PROVE the fix works before resubmitting:

1. Write a regression test that would have FAILED before
2. Show the test now PASSES
3. Include verification evidence in the fix comment

---

## Autonomous Loop Commands

For processing queues without manual invocation:

| Command | What It Does | Agent |
|---------|--------------|-------|
| `/build-loop` | Continuously implements approved tasks | macOS Dev |
| `/review-loop` | Continuously code reviews awaiting items | Staff Engineer |
| `/qa-loop` | Continuously QA tests awaiting items | QA |
| `/pm-loop` | Continuously product reviews awaiting items | PM |

**Usage:** Run when you have multiple items in a queue and want continuous processing until the queue is empty.

**Example:**
```
# Start autonomous implementation
/build-loop

# Or run multiple loops in sequence
/build-loop -> /review-loop -> /qa-loop -> /pm-loop
```

---

## Workflow Skills (Explicit Invocation)

These workflows require explicit invocation for reliable execution:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/validate-task <id>` | Validate task metadata against schema v2.0 | Before submission |
| `/complete-task <id>` | Mark task done with required comments | Task completion |
| `/ticket-update <id> <stage>` | Transition ticket to new workflow state | Manual workflow transitions |
| `/submit-for-review <id>` | Validate story ready for code review | After all tasks done |

Skills location: `.claude/skills/workflow/`

---

## Security Review

When work touches sensitive areas (Keychain, credentials, entitlements, network requests, file handling):

```
/security-audit [id]
```

**What Happens:**
1. Security agent reviews code for vulnerabilities
2. Checks against OWASP patterns and macOS security best practices
3. Creates blocking security issues if problems found
4. Must be resolved before proceeding

**Triggers automatic security review:**
- Keychain access
- Credential storage
- Network requests
- File system operations
- Entitlement changes

---

## Logs

All setup and infrastructure operations are logged to `.claude/logs/`.

### Viewing Logs

```bash
# View the most recent log
cat .claude/logs/latest.log

# View a specific operation log
cat .claude/logs/setup-20250108-143001.log

# Watch log in real-time during setup
tail -f .claude/logs/latest.log

# List all logs
ls -la .claude/logs/
```

### What's Logged

- Every file created or copied (with source/destination)
- Every script executed (with exit status)
- Every configuration choice made
- All errors with full output
- Timestamps for all operations

### Log Rotation

Logs are automatically rotated - only the last 10 logs per operation type are kept.

---

## Infrastructure Scripts

Scripts are located in `.claude/scripts/` and can be run directly if needed:

```bash
# Run setup with validation only (no changes)
.claude/scripts/setup-project.sh --validate-only

# Run specific setup script
.claude/scripts/setup-dev.sh

# Check prerequisites
.claude/scripts/setup-project.sh --help
```

### Script Reference

| Script | Purpose |
|--------|---------|
| `setup-project.sh` | Master orchestrator |
| `setup-dev.sh` | Core Data stack with model setup |
| `setup-xcode-project.sh` | Xcode project configuration |
| `setup-github-repo.sh` | GitHub repo with branch protection |
| `setup-notarization.sh` | Code signing and notarization |
| `setup-monitoring.sh` | Crash reporting, analytics |

---

## Issue Type Hierarchy

```
Epic: [Name] (top-level initiative)
  |
  +-- Story: [Name] (user story or component)
        |
        +-- Task: [Name] (actual work item)
```

**Hierarchy in metadata (v2.0 schema):**
- Epic: `metadata.type: "epic"`, `metadata.schema_version: "2.0"`, subject: `Epic: [Name]`
- Story: `metadata.type: "story"`, `metadata.parent: <epic-id>`, `metadata.epic_id: <epic-id>`, subject: `Story: [Name]`
- Task: `metadata.type: "task"`, `metadata.parent: <story-id>`, `metadata.story_id: <story-id>`, subject: `Task: [Name]`

**Key v2.0 Fields by Type:**
| Type | Key Fields |
|------|------------|
| Epic | `execution_plan`, `estimate`, `definition_of_done` (structured), `suggested_inputs` |
| Story | `epic_id`, `ai_context`, `implementation_constraints`, `definition_of_done` (structured) |
| Task | `local_checks`, `checklist`, `completion_signal`, `validation_hint`, `ai_execution_hints` |

---

## Quick Reference

### Planning & Setup Commands

| Command | Purpose | Agent |
|---------|---------|-------|
| `/init-macos-project <name>` | Create new Xcode project | - |
| `/setup` | Configure existing project | - |
| `/status` | Show project & workflow state | - |
| `/update-toolkit` | Update .claude/ to latest | - |

### Feature Planning Commands

| Command | Purpose | Agent |
|---------|---------|-------|
| `/feature <name>` | Start new feature with discovery Q&A | PM |
| `/external-review` | Multi-model review (Claude, Gemini, OpenCode) | - |
| `/epic [phase]` | Create epic from planning docs | Planning |
| `/write-stories-and-tasks <epic-id>` | Break epic into stories/tasks | Staff Engineer |
| `/approve-epic` | Approve an epic and all its stories/tasks for implementation | - |
| `/backlog` | Add ideas to backlog for later | - |

### Design Commands

| Command | Purpose | Agent |
|---------|---------|-------|
| `/design [screen]` | Create UI spec before building | Designer |
| `/ui-polish [screen]` | Screenshot-driven visual verification | Designer |
| `/design-review` | Review UI against design principles | Designer |

### Implementation Commands

| Command | Purpose | Agent |
|---------|---------|-------|
| `/build [id]` | Implement a single task | macOS Dev |
| `/build-story [story-id]` | Build story + full review cycle | Multiple |
| `/build-epic [epic-id]` | Autonomous parallel epic building | Multiple |
| `/build-loop` | Continuous implementation queue | macOS Dev |
| `/fix [id]` | Fix rejected items (verification required) | macOS Dev |

### Review Commands

| Command | Purpose | Agent |
|---------|---------|-------|
| `/code-review [id]` | Review code quality | Staff Engineer |
| `/review-loop` | Continuous code review queue | Staff Engineer |
| `/qa [id]` | Test against acceptance criteria | QA |
| `/qa-loop` | Continuous QA queue | QA |
| `/security-audit [id]` | Security vulnerability review | Security |
| `/product-review [id]` | Final review before close | PM |
| `/pm-loop` | Continuous product review queue | PM |

### Testing & Validation Commands

| Command | Purpose | Agent |
|---------|---------|-------|
| `/test [scope]` | Run tests during development | QA |
| `/checkpoint` | Full validation gate | QA |
| `/complete-epic [id]` | Verify and close epic | Multiple |

### Git & Release Commands

| Command | Purpose | Agent |
|---------|---------|-------|
| `/commit` | Commit with task tracking | Build Engineer |
| `/pr` | Create pull request | Build Engineer |
| `/archive` | Build release archive | Build Engineer |

### Workflow Management Commands

| Command | Purpose | Agent |
|---------|---------|-------|
| `/ticket-update <id> <stage>` | Move ticket through workflow stages | - |
| `/workflow-audit` | Audit workflow field consistency | - |
| `/workflow-fix` | Fix workflow field issues | - |

### Maintenance Commands

| Command | Purpose | Agent |
|---------|---------|-------|
| `/backup [name]` | Archive task state for historical records | - |
| `/learn <desc>` | Capture learning, update rules | - |
| `/techdebt [scope]` | Scan for tech debt | - |
| `/clear-context-prompt` | Generate handoff for /clear | - |
| `/check-updates` | Quick scan for Claude Code platform changes | - |
| `/deep-dive-updates` | Full analysis of all tracked platform docs | - |
| `/evolve` | Self-audit toolkit against platform capabilities | - |

---

## The Review Cycle (Critical!)

Review cycles vary by ticket type:

### Tasks — No Review Cycle

Tasks complete directly after implementation. Reviews happen at the Story level.

```
pending → in-progress → completed
```

### Stories / Bugs / TechDebt — Standard Review

```
+-------------+    +-------------+    +-------------+    +-------------+
|   macOS     |--->| Code Review |--->|     QA      |--->|  Product    |---> COMPLETED
|    Dev      |    | (Staff Eng) |    |   Testing   |    |   Review    |
+-------------+    +-------------+    +-------------+    +-------------+
       ^                  |                  |                  |
       |                  | FAIL             | FAIL             | FAIL
       |                  v                  v                  v
       +------------------+------------------+------------------+
                    (All rejections return to Dev → restart at Code Review)
```

### Epics — Standard Review + Human UAT

```
+-------------+    +-------------+    +-------------+    +-------------+    +-------------+
|   macOS     |--->| Code Review |--->|     QA      |--->|  Product    |--->|  Human UAT  |---> COMPLETED
|    Dev      |    | (Staff Eng) |    |   Testing   |    |   Review    |    |  (You Test) |
+-------------+    +-------------+    +-------------+    +-------------+    +-------------+
       ^                  |                  |                  |                  |
       |                  | FAIL             | FAIL             | FAIL             | FAIL
       +------------------+------------------+------------------+------------------+
                    (All rejections return to Dev → restart at Code Review)
```

**Key Rules:**
- ANY rejection at ANY stage returns to Dev, then the FULL cycle restarts from Code Review
- `human-uat` is Epic-only — Stories/Bugs/TechDebt complete after product-review
- Use `/ticket-update <id> passed` to advance through stages without remembering what comes next

### Optional Security Review

When work touches sensitive areas (Keychain, credentials, network, entitlements):

```
Code Review → QA → Security Review → Product Review → ...
```

### Workflow State Through the Cycle

| Stage | `review_stage` | `review_result` | Command | Who |
|-------|---------------|-----------------|---------|-----|
| Ready for code review | `"code-review"` | `"awaiting"` | `/code-review` | Staff Engineer |
| Ready for QA | `"qa"` | `"awaiting"` | `/qa` | QA Agent |
| Ready for security | `"security"` | `"awaiting"` | `/security-audit` | Security |
| Ready for PM | `"product-review"` | `"awaiting"` | `/product-review` | PM Agent |
| Code review rejected | `"code-review"` | `"rejected"` | `/fix` | Dev |
| QA rejected | `"qa"` | `"rejected"` | `/fix` | Dev |
| Security rejected | `"security"` | `"rejected"` | `/fix` | Dev |
| Product rejected | `"product-review"` | `"rejected"` | `/fix` | Dev |

**Note:** These fields apply to Stories and Epics only. Tasks do NOT have `review_stage` or `review_result`.

---

## Complete Workflow

```
+------------------------------------------------------------------+
|  HUMAN: /feature expense-tracker                                  |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|  PM AGENT creates epic + spec                                     |
|  STAFF ENGINEER breaks into stories/tasks                         |
|  Sets approval: "pending" on all items                            |
|  STOPS - awaiting approval                                        |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|  * HUMAN APPROVAL POINT *                                         |
|  1. Review epic, stories, and tasks                               |
|  2. Run /approve-epic [epic-id]                                   |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|  OPTIONAL: /design [screen] for UI work                           |
|  Creates UI spec at planning/design/[screen]-spec.md              |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|  HUMAN: /build (or /build-story or /build-epic)                   |
|                                                                   |
|  macOS DEV implements task                                        |
|  Sets review_stage: "code-review", review_result: "awaiting"      |
|  Hands off to Staff Engineer                                      |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|  HUMAN: /code-review                                              |
|                                                                   |
|  STAFF ENGINEER reviews code                                      |
|  PASS: Sets review_stage: "qa", review_result: "awaiting"         |
|  FAIL: Sets review_result: "rejected" (stage stays "code-review") |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|  HUMAN: /qa                                                       |
|                                                                   |
|  QA AGENT tests against acceptance criteria                       |
|  PASS: Sets review_stage: "product-review", review_result: "awaiting" |
|  FAIL: Sets review_result: "rejected" (stage stays "qa")         |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|  HUMAN: /product-review                                           |
|                                                                   |
|  PM AGENT reviews from user perspective                           |
|  PASS: Clears review fields, completes story                     |
|  FAIL: Sets review_result: "rejected" (stage stays "product-review") |
+------------------------------------------------------------------+
                              |
                              v
                     (repeat for all tasks)
                              |
                              v
+------------------------------------------------------------------+
|  OPTIONAL: /ui-polish [screen] for visual verification            |
|  Screenshot-driven comparison against design system               |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|  When all tasks closed -> PM closes epic                          |
|  /complete-epic [id] for full verification                        |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|  /archive to create release build                                 |
+------------------------------------------------------------------+
```

---

## Step-by-Step Details

### Step 1: Start a Feature

```
/feature expense-tracker
```

**What Happens:**
1. PM Agent creates feature spec at `planning/features/expense-tracker.md`
2. PM Agent creates epic using TaskCreate
3. Staff Engineer breaks epic into stories and tasks
4. Staff Engineer sets `approval: "pending"` on epic and all children
5. **STOPS** - awaiting your approval

### Step 2: Approve the Plan

1. Review the epic, stories, and tasks
2. Run `/approve-epic [epic-id]`

**What /approve-epic Does:**
- Sets `approval: "approved"` on the epic + all stories + all tasks
- Now the entire plan is green-lit for implementation

### Step 3: Design UI (Optional but Recommended)

```
/design dashboard
```

**What Happens:**
1. Designer creates UI spec at `planning/design/dashboard-spec.md`
2. Spec includes wireframe, component mapping, state definitions
3. Uses design system values (not arbitrary numbers)

### Step 4: Build Tasks

```
/build
```

**What Happens:**
1. macOS Dev picks first available task
2. Implements the work
3. Sets `review_stage: "code-review"`, `review_result: "awaiting"`
4. Adds "READY FOR CODE REVIEW" comment

**Output:**
```
Task [task-xyz] submitted for code review
Set review_stage: "code-review", review_result: "awaiting"

Handoff: Staff Engineer will review via /code-review
```

### Step 5: Code Review

```
/code-review
```

**What Happens:**
1. Staff Engineer reviews code quality, architecture, standards
2. **PASS:** Sets `review_stage: "qa"`, `review_result: "awaiting"`
3. **FAIL:** Sets `review_result: "rejected"` (stage stays `"code-review"`)

**Output (Pass):**
```
Code review PASSED for [task-xyz]
Set review_stage: "qa", review_result: "awaiting"

Handoff: QA will test via /qa
```

**Output (Fail):**
```
Code review FAILED for [task-xyz]
Set review_result: "rejected" (stage remains "code-review")

Handoff: Dev will fix via /fix
```

### Step 6: QA Testing

```
/qa
```

**What Happens:**
1. QA Agent tests against acceptance criteria
2. **PASS:** Sets `review_stage: "product-review"`, `review_result: "awaiting"`
3. **FAIL:** Sets `review_result: "rejected"` (stage stays `"qa"`)

**Output (Pass):**
```
QA PASSED for [task-xyz]
Set review_stage: "product-review", review_result: "awaiting"

Handoff: PM will review via /product-review
```

### Step 7: Product Review

```
/product-review
```

**What Happens:**
1. PM reviews from user/business perspective
2. **PASS:** Sets `review_stage: null`, `review_result: null`, **CLOSES story**
3. **FAIL:** Sets `review_result: "rejected"` (stage stays `"product-review"`)

**Output (Pass):**
```
Product review PASSED for [task-xyz]
Task CLOSED

Review cycle complete!
```

### Step 8: Fix Rejected Items

If any stage rejects:

```
/fix
```

**What Happens:**
1. Dev sees queue of rejected items
2. Picks one, reads rejection comment
3. Fixes ALL issues listed
4. Sets `review_stage: "code-review"`, `review_result: "awaiting"`
5. **Full cycle restarts from Code Review**

### Step 9: Visual Polish (Optional)

```
/ui-polish dashboard
```

**What Happens:**
1. Takes screenshot of running app
2. Compares against design system
3. Identifies spacing, typography, color issues
4. Generates fix code with explanations
5. Optionally applies fixes automatically

### Step 10: Complete Epic

```
/complete-epic [epic-id]
```

**What Happens:**
1. Verifies all stories passed
2. Runs comprehensive tests
3. Submits epic for final review cycle
4. Closes epic when approved

---

## Workflow Fields Quick Reference

### Approval & Blocking Fields

| Field | Values | Applies To |
|-------|--------|------------|
| `approval` | `"pending"`, `"approved"` | Epic, Story, Task |
| `blocked` | `true`, `false` | All |

### Review Cycle Fields (Stories & Epics Only)

| Field | Values | Purpose |
|-------|--------|---------|
| `review_stage` | `"code-review"`, `"qa"`, `"security"`, `"product-review"`, `"human-uat"`, `null` | Current review stage |
| `review_result` | `"awaiting"`, `"passed"`, `"rejected"`, `null` | Result at current stage |

### Review Stage Combinations

| State | `review_stage` | `review_result` | Meaning |
|-------|---------------|-----------------|---------|
| Ready for code review | `"code-review"` | `"awaiting"` | Staff Engineer should review |
| Ready for QA | `"qa"` | `"awaiting"` | QA should test |
| Ready for security | `"security"` | `"awaiting"` | Security review needed |
| Ready for PM | `"product-review"` | `"awaiting"` | PM should review |
| Ready for human UAT | `"human-uat"` | `"awaiting"` | Human tests manually (Epic only) |
| Code review rejected | `"code-review"` | `"rejected"` | Dev should fix |
| QA rejected | `"qa"` | `"rejected"` | Dev should fix |
| Security rejected | `"security"` | `"rejected"` | Dev should fix |
| Product rejected | `"product-review"` | `"rejected"` | Dev should fix |
| Human UAT rejected | `"human-uat"` | `"rejected"` | Dev should fix (Epic only) |
| Completed | `null` | `null` | Review cycle done |

### Categorization Labels

`metadata.labels` is now used **only** for categorization tags (e.g., `["infrastructure", "phase-1"]`). Labels no longer carry workflow state.

**Note:** Tasks do NOT have `review_stage` or `review_result` fields. Tasks only have `approval` and `blocked`.

---

## Comment Templates

Each stage has a required comment format. See `.claude/docs/WORKFLOW-STATE.md` for full templates.

| Comment | When | By Whom |
|---------|------|---------|
| `READY FOR CODE REVIEW` | After implementation | macOS Developer |
| `CODE REVIEW PASSED` | Code review approved | Staff Engineer |
| `QA PASSED` | QA approved | QA |
| `PRODUCT REVIEW PASSED` | PM approved | PM |
| `REJECTED - [STAGE]` | Any rejection | Reviewer |
| `FIXED AND RESUBMITTED` | After fixing | macOS Developer |

### Structured Comment Format

All comments must use structured JSON. Two variants:

**Base comment** (most types):
```json
{
  "id": "C1",
  "timestamp": "2026-01-30T10:00:00Z",
  "author": "macos-developer-agent",
  "type": "handoff",
  "content": "READY FOR CODE REVIEW\n\n**Files changed:**\n- ..."
}
```

**Trackable comment** (rejection only — adds resolution tracking):
```json
{
  "id": "C2",
  "timestamp": "2026-01-30T10:00:00Z",
  "author": "staff-engineer-agent",
  "type": "rejection",
  "content": "REJECTED - CODE REVIEW\n\nIssues:\n1. ...",
  "resolved": false,
  "resolved_by": null,
  "resolved_at": null
}
```

**Comment Types:**
- `note` - General observation or status update
- `handoff` - Handing off to next stage
- `review` - Approving and passing
- `rejection` - Rejecting with issues (includes `resolved` fields)
- `implementation` - Task completion details
- `testing` - Test coverage details
- `fix` - Fix details after rejection

---

## Finding Work

### Using TaskList Tool

Tasks are managed through Claude Code's Task tools. Use TaskList to find work:

### As Dev (macOS Developer)

```
// New work to start - tasks with approval == "approved", status 'pending'
TaskList
// Filter results where metadata.approval == "approved" AND status == "pending"

// Items you need to fix (prioritize these!)
TaskList
// Filter results where metadata.review_result == "rejected"
```

### As Staff Engineer

```
// Code review queue
TaskList
// Filter results where metadata.review_stage == "code-review" AND metadata.review_result == "awaiting"
```

### As QA

```
// QA queue
TaskList
// Filter results where metadata.review_stage == "qa" AND metadata.review_result == "awaiting"
```

### As PM

```
// Product review queue
TaskList
// Filter results where metadata.review_stage == "product-review" AND metadata.review_result == "awaiting"
```

### Common Task Operations

```
// Get task details
TaskGet { id: "[task-id]" }

// Update task status and last_updated_at
TaskUpdate {
  id: "[task-id]",
  status: "in_progress",
  metadata: {
    last_updated_at: "2026-01-30T12:00:00Z"
  }
}

// Update workflow state fields directly
TaskUpdate {
  id: "[story-id]",
  metadata: {
    approval: "approved",
    review_stage: "code-review",
    review_result: "awaiting",
    labels: ["infrastructure"],
    comments: [...existing_comments],
    last_updated_at: "2026-01-30T12:00:00Z"
  }
}

// Create new task (v2.0 schema)
TaskCreate {
  subject: "Task: Implement user preferences view",
  description: "## What\nCreate SwiftUI view for user preferences.\n\n## Why\nUsers need to configure app settings.\n\n## How\nSwiftUI Form with sections for each preference category.",
  metadata: {
    schema_version: "2.0",
    type: "task",
    parent: "story-123",
    task_id: "PROJECT-101-1",
    story_id: "PROJECT-101",
    priority: "P2",
    assignee: null,
    claimed_by: null,
    claimed_at: null,
    hours_estimated: 3,
    hours_actual: null,
    approval: "pending",
    blocked: false,
    labels: [],
    files: ["app/AppName/AppName/Views/Settings/PreferencesView.swift"],
    checklist: [
      "Create PreferencesView.swift structure",
      "Add Form with Toggle/Picker controls",
      "Connect to SettingsViewModel"
    ],
    local_checks: [
      "PreferencesView renders all preference options",
      "Toggle changes update SettingsViewModel",
      "Navigation title shows 'Preferences'"
    ],
    completion_signal: "PR merged and all local_checks pass",
    validation_hint: "Build succeeds, PreferencesView renders in preview",
    ai_execution_hints: [
      "Keep view presentational, state in ViewModel",
      "Use @Environment for colorScheme support",
      "Group related settings in Form sections"
    ],
    comments: [],
    created_at: "2026-01-30T10:00:00Z",
    created_by: "staff-engineer-agent",
    last_updated_at: "2026-01-30T10:00:00Z"
  }
}
```

**v2.0 Schema Notes:**
- **Tasks**: Use `local_checks` (not `acceptance_criteria`), `checklist` (not `subtasks`), `validation_hint` (not `verify`)
- **Tasks**: Include `completion_signal` and `ai_execution_hints` for AI agents
- **Tasks**: Do NOT include `definition_of_done` (repo-level quality gate, not task-level)
- **Stories**: Include `epic_id`, `ai_context`, `implementation_constraints`
- **Epics**: Use `execution_plan` (not `timeline`), `estimate` (not `estimated_hours`/`estimated_days`/`size`)

---

## Git Commit Messages

Include task ID in all commits:

```
<type>(<scope>): description (task-xxx)
```

Example:
```
feat(auth): add biometric authentication support (task-abc123)
```

This enables traceability between code and tasks.

---

## Xcode Project Structure

All app code lives in `app/`:

```
app/                           # All macOS app code
├── MyApp.xcodeproj/
├── MyApp/
│   ├── App/
│   │   └── MyAppApp.swift     # @main entry point
│   ├── Features/
│   │   └── FeatureName/
│   │       ├── Views/         # SwiftUI views
│   │       ├── ViewModels/    # @Observable view models
│   │       └── Models/        # Feature-specific models
│   ├── Core/
│   │   ├── Models/            # Core Data models, shared types
│   │   ├── Services/          # Business logic services
│   │   ├── Networking/        # Alamofire network layer
│   │   └── Persistence/       # Core Data stack
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
├── MyAppTests/                # XCTest unit tests
├── MyAppUITests/              # XCTest UI tests
└── .swiftlint.yml

.claude/                       # Workflow configuration (at repo root)
planning/                      # Feature specs, backups, designs (at repo root)
```

---

## Running Tests

### Unit Tests
```bash
# Run all unit tests
xcodebuild test -scheme MyApp -destination 'platform=macOS'

# Or use Xcode: Cmd+U
```

### UI Tests
```bash
# Run UI tests
xcodebuild test -scheme MyAppUITests -destination 'platform=macOS'
```

### SwiftLint
```bash
# Run linter
swiftlint

# Auto-fix issues
swiftlint --fix
```

---

## Troubleshooting

### "Task has not been approved"
Run `/approve-epic [epic-id]` to approve the epic and all its stories/tasks.

### "Epic has approval: pending"
Run `/approve-epic [epic-id]` to approve the entire plan for implementation.

### Task stuck in rejected state
Run `/fix [task-id]` to pick it up and address the rejection feedback.

### Don't know what stage a story is in
```swift
TaskGet(taskId)
// Look at metadata.review_stage and metadata.review_result
// For tasks, check metadata.approval and metadata.blocked
```

### Tasks missing after new session
Ensure you're launching with the same `CLAUDE_CODE_TASK_LIST_ID`:
```bash
CLAUDE_CODE_TASK_LIST_ID=my-project claude --dangerously-skip-permissions
```

### Need to archive completed work
Run `/backup [name]` to archive task state to `planning/backups/` for git tracking.

### Build fails with signing errors
Check that your development team is set in Xcode project settings under Signing & Capabilities.

### Core Data model changes not reflected
Clean build folder (Cmd+Shift+K) and rebuild.

### Need to hand off work before clearing context
Run `/clear-context-prompt` to generate a handoff prompt for the next session.

---

## Documentation Map

| Doc | Location | Purpose |
|-----|----------|---------|
| **This Guide** | `.claude/HOW-TO.md` | Complete workflow |
| **CLAUDE.md** | `CLAUDE.md` | Quick reference, tech stack, critical rules |
| **Metadata Schema** | `.claude/templates/tasks/metadata-schema.md` | Complete v2.0 field reference |
| **Workflow State** | `.claude/docs/WORKFLOW-STATE.md` | Full review cycle details |

### Agent Documentation

| Agent | Location |
|-------|----------|
| Planning Agent | `.claude/agents/planning-agent.md` |
| PM Agent | `.claude/agents/pm-agent.md` |
| Staff Engineer | `.claude/agents/staff-engineer-agent.md` |
| Designer Agent | `.claude/agents/designer-agent.md` |
| macOS Developer | `.claude/agents/macos-developer-agent.md` |
| Data Architect | `.claude/agents/data-architect-agent.md` |
| QA Agent | `.claude/agents/qa-agent.md` |
| Security Agent | `.claude/agents/security-agent.md` |
| Build Engineer | `.claude/agents/build-engineer-agent.md` |

### Skills Documentation

| Skill Category | Location | Purpose |
|----------------|----------|---------|
| Design System | `.claude/skills/design-system/` | Visual design values |
| Workflow Skills | `.claude/skills/workflow/` | Task completion, validation, workflow state |
| Generator Skills | `.claude/skills/generators/` | Test, networking generators |
| Security Skills | `.claude/skills/security/` | Security patterns |
| Tooling Skills | `.claude/skills/tooling/` | Core Data, Keychain, SwiftUI, etc. |
| macOS UI Review | `.claude/skills/macos-ui-review/` | HIG compliance, Liquid Glass |

### Templates

Templates live in two locations by design:

| Location | What | Synced by toolkit? |
|----------|------|--------------------|
| `.claude/templates/` | Task schemas, doc templates, linter configs | Yes — toolkit-owned, synced via `sync-toolkit.sh` |
| `planning/templates/` | Planning doc templates (PRD, UI_SPEC, epic-skeleton) | No — project-level, may be customized per project |

**Toolkit templates** (`.claude/templates/`):

| Template | Location |
|----------|----------|
| Epic Template | `.claude/templates/tasks/epic.md` |
| Story Template | `.claude/templates/tasks/story.md` |
| Task Template | `.claude/templates/tasks/task.md` |
| Bug Report | `.claude/templates/tasks/bug.md` |
| PR Template | `.claude/templates/pr-template.md` |

**Planning templates** (`planning/templates/`):

| Template | Location |
|----------|----------|
| PRD | `planning/templates/PRD-TEMPLATE.md` |
| UI Spec | `planning/templates/UI_SPEC-TEMPLATE.md` |
| Data Schema | `planning/templates/DATA_SCHEMA-TEMPLATE.md` |
| Technical Spec | `planning/templates/TECHNICAL_SPEC-TEMPLATE.md` |
| Implementation Guide | `planning/templates/IMPLEMENTATION_GUIDE-TEMPLATE.md` |
| Epic Skeleton (JSON) | `planning/templates/epic-skeleton.json` |
| UX Flows | `planning/templates/UX_FLOWS.md` |

### Other Locations

| Item | Location |
|------|----------|
| Slash Commands | `.claude/commands/*.md` |
| Feature Specs | `planning/features/*.md` |
| Design Specs | `planning/design/*.md` |
| Backups | `planning/backups/` |
| External Reviews | `planning/reviews/` |
| Epic Notes | `planning/notes/[epic-name]/` |

---

## Schema v2.0 Reference

The v2.0 schema is AI-first, designed to provide clear execution guidance for AI agents.

### Key v2.0 Changes from v1.0

#### Epic Changes

| Added | Removed | Purpose |
|-------|---------|---------|
| `schema_version: "2.0"` | - | Version tracking |
| `execution_plan` | `timeline` | AI-oriented sequencing (precedence phases, not calendar days) |
| `estimate` | `estimated_hours`, `estimated_days`, `size` | Unified estimate object |
| `definition_of_done` (structured) | `definition_of_done` (array) | Includes completion_gates, generation_hints |
| `suggested_inputs` | - | Fields that could be populated later |
| `last_updated_at` | - | Track modifications |
| - | `git_setup` | Git commands are standard |
| - | `tech_spec_lines`, `data_schema_lines` | Use section anchors, not line numbers |

#### Story Changes

| Added | Removed | Purpose |
|-------|---------|---------|
| `schema_version: "2.0"` | - | Version tracking |
| `epic_id` | - | Quick reference to parent epic |
| `ai_context` | - | Context for AI agents |
| `implementation_constraints` | - | Technical constraints |
| `definition_of_done` (structured) | - | Includes completion_gates, generation_hints |
| `last_updated_at` | - | Track modifications |
| - | `git` | Branch derived from story_id |
| - | `hours_estimated`, `hours_actual` | Hours only at task level |
| - | `context` | Move to description |

#### Task Changes

| Added | Removed/Renamed | Purpose |
|-------|-----------------|---------|
| `schema_version: "2.0"` | - | Version tracking |
| `local_checks` | `acceptance_criteria` (renamed) | Task-specific acceptance |
| `checklist` | `subtasks` (renamed) | Granular steps |
| `validation_hint` | `verify` (renamed) | Quick verification |
| `completion_signal` | - | When is task done |
| `ai_execution_hints` | - | Hints for AI agents |
| `last_updated_at` | - | Track modifications |
| - | `definition_of_done` | Repo-level quality gate |

### Example: Epic with v2.0 Fields

```json
{
  "schema_version": "2.0",
  "type": "epic",
  "id": "PROJECT-100",

  "estimate": {
    "primary_unit": "points",
    "value": 21,
    "notes": "Story points, not hours"
  },

  "execution_plan": {
    "shape": "precedence_phases",
    "phases": [
      {
        "phase": "execution-1",
        "intent": "Core infrastructure",
        "stories": ["PROJECT-101", "PROJECT-102"],
        "deliverables": ["Core Data stack", "Basic CRUD"]
      }
    ],
    "notes": "AI-oriented sequencing"
  },

  "definition_of_done": {
    "purpose": "Stop condition for AI + humans",
    "completion_gates": [
      "All acceptance criteria pass",
      "End-to-end flow works",
      "No open P0/P1 bugs"
    ],
    "quality_gates_source": "CLAUDE.md#quality-gates",
    "generation_hints": [
      "Derive checklist from acceptance_criteria.verify"
    ]
  },

  "suggested_inputs": [
    {
      "field": "owner",
      "suggestion": "Set accountable owner"
    }
  ],

  "last_updated_at": "2026-01-30T12:00:00Z"
}
```

### Example: Story with v2.0 Fields

```json
{
  "schema_version": "2.0",
  "type": "story",
  "story_id": "PROJECT-101",
  "epic_id": "PROJECT-100",

  "ai_context": "Login view is first screen for returning users",

  "implementation_constraints": [
    "SwiftUI SecureField for password",
    "Validate via DatabaseService.validatePassword()"
  ],

  "definition_of_done": {
    "completion_gates": [
      "All story acceptance_criteria pass",
      "No regression on related functionality"
    ],
    "generation_hints": [
      "Map each AC to verification artifact"
    ]
  },

  "last_updated_at": "2026-01-30T12:00:00Z"
}
```

### Example: Task with v2.0 Fields

```json
{
  "schema_version": "2.0",
  "type": "task",
  "task_id": "PROJECT-101-1",
  "story_id": "PROJECT-101",

  "checklist": [
    "Create LoginView.swift",
    "Add SecureField with binding",
    "Add Unlock button"
  ],

  "local_checks": [
    "LoginView renders lock icon",
    "SecureField masks password",
    "Button disabled when empty"
  ],

  "completion_signal": "PR merged and story AC still pass",
  "validation_hint": "Build succeeds, preview renders",

  "ai_execution_hints": [
    "Keep view presentational",
    "Match UI_SPEC for layout",
    "Use .onSubmit for unlock"
  ],

  "last_updated_at": "2026-01-30T12:00:00Z"
}
```

### Fields NOT Used in v2.0

These fields from v1.0 should NOT be used:

| Type | Removed Fields |
|------|----------------|
| Epic | `timeline`, `git_setup`, `estimated_hours`, `estimated_days`, `size`, `tech_spec_lines`, `data_schema_lines` |
| Story | `git`, `hours_estimated`, `hours_actual`, `context` |
| Task | `definition_of_done`, `acceptance_criteria` (use `local_checks`), `subtasks` (use `checklist`), `verify` (use `validation_hint`) |
