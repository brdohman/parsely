---
description: Start new feature workflow with discovery Q&A. PM asks clarifying questions, then creates epic, Staff Engineer breaks into tasks.
argument-hint: feature description (e.g., "setup github with vercel and coderabbit for deployments")
---

# /feature

Start new feature workflow with discovery Q&A.

For v2.0 task schema fields and comment format: see `.claude/templates/tasks/metadata-schema.md` and `.claude/rules/global/task-state-updates.md`.

## Pre-Flight Checks

1. **Xcode Project exists:** `ls *.xcodeproj 2>/dev/null || ls *.xcworkspace 2>/dev/null`
2. **Build warning (optional):** `xcodebuild build -scheme AppName -destination 'platform=macOS' -quiet`

---

## Phase 0: Scan Existing Planning Docs (FIRST)

Before asking any questions, scan `planning/` for existing specs:

```bash
find planning -name "*.md" -type f 2>/dev/null | head -20
```

Present any relevant docs and ask if they should be used as the basis for planning.

---

## Delegation Chain

1. **PM Agent** — Discovery Q&A and epic creation
2. **Staff Engineer Agent** — Story and task breakdown
3. **STOP** — Wait for human approval

---

## Step 1: Discovery (MANDATORY)

**DO NOT CREATE ANYTHING UNTIL DISCOVERY IS COMPLETE.**

Explore these areas (adapt to feature type):

- **Scope & Goals:** Problem, success, out of scope
- **Technical Context:** Existing systems, dependencies, constraints
- **Users & Access:** Who uses it, permissions
- **Environment & Integration:** Environments, external services, auth
- **Priority & Timeline:** Urgency, deadlines, phases

### Discovery Complete Criteria

- [ ] Core scope understood
- [ ] Out of scope defined
- [ ] Technical approach clear
- [ ] Success criteria writable
- [ ] User confirms "looks good"

---

## Step 2: PM Agent — Epic Creation

After discovery, read `.claude/templates/tasks/epic.md`, create spec in `planning/features/[name].md`, then:

```
TaskCreate:
  subject: "Epic: [Name]"
  metadata:
    schema_version: "2.0", type: "epic"
    priority: "P1", approval: "pending", blocked: false
    review_stage: null, review_result: null
    labels: [], stories: []
    created_by: "pm-agent"
```

Hand off to Staff Engineer.

---

## Step 3: Staff Engineer Agent — Breakdown

1. Read spec from `planning/features/[name].md`
2. Read `.claude/templates/tasks/story.md` and `.claude/templates/tasks/task.md`
3. Identify phases (typically: DB → API → UI)

**For each phase, create a Story:**

```
TaskCreate:
  subject: "Story: Phase N - [Name]"
  metadata:
    schema_version: "2.0", type: "story"
    parent: "[epic-id]"
    priority: "P1", approval: "pending", blocked: false
    review_stage: null, review_result: null
    acceptance_criteria: [{id, title, given, when, then, verify}]
    created_by: "staff-engineer-agent"
```

**For each task in phase:**

```
TaskCreate:
  subject: "Task: [Action verb] [Specific deliverable]"
  metadata:
    schema_version: "2.0", type: "task"
    parent: "[story-id]"
    priority: "P2", approval: "pending", blocked: false
    local_checks: ["Check 1", "Check 2", "Check 3"]
    checklist: ["Step 1", "Step 2"]
    completion_signal: "...", validation_hint: "..."
    ai_execution_hints: ["..."]
    created_by: "staff-engineer-agent"
```

**Update parent story** with task IDs, then **update epic** with story IDs and add PLAN PENDING APPROVAL comment.

---

## Step 4: STOP for Human Approval

**DO NOT PROCEED. STOP HERE.**

Output plan summary. Instruct human to:
1. Review the epic, stories, and tasks
2. Run `/approve-epic [epic-id]` to approve the entire plan
3. Then run `/build` to start implementation

---

## Output Format

### After Planning Complete

```
Feature planned and ready for approval.

Epic: [task-id] Epic: [Name]
Spec: planning/features/[name].md

Story 1: [Name] ([N] tasks)
├── [task-id] [Task name]
└── [task-id] [Task name]

Total: [N] stories, [N] tasks

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AWAITING YOUR APPROVAL

1. Review the plan
2. Run /approve-epic [epic-id]
3. Run /build to start implementation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
