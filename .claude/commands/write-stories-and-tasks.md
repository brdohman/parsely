---
description: Break an existing epic into stories and tasks. Use when re-planning or planning an epic created outside /feature.
argument-hint: epic ID (e.g., task-abc123)
---

# /write-stories-and-tasks

Staff Engineer breaks an **existing** epic into stories and tasks.

> **This command does NOT create epics.** For new features use `/feature` or `/epic`.

Use when: re-planning after scope changes, breaking down a manually created epic, adding tasks to an existing plan.

For v2.0 schema field names and comment format: see `.claude/templates/tasks/metadata-schema.md` and `.claude/rules/global/task-state-updates.md`.
For workflow field values: see `.claude/docs/WORKFLOW-STATE.md`.

---

## Delegation

**IMMEDIATELY delegate to Staff Engineer agent.** The coordinator only validates the epic exists.

```
⛔ COORDINATOR FORBIDDEN:
  - Read templates, planning docs, or source code
  - Use Grep/Glob on codebase
  - Create stories or tasks (no TaskCreate)

✅ COORDINATOR ALLOWED:
  - TaskList, TaskGet (Step 0 validation only)
  - Task (spawn Staff Engineer agent)
  - Report results to user
```

---

## Step 0: Validate Epic (Coordinator)

```
TaskList → find epic by ID or subject
TaskGet [epic-id] → verify metadata.type == "epic"
```

If NOT found:
```
ERROR: Epic not found: [epicId]

Use /epic or /feature to create it first, then run:
  /write-stories-and-tasks [task-id]
```

---

## Steps 1–11: Staff Engineer Agent

### 1. Load Epic and UX Flows

```
TaskGet [epic-id]
Verify metadata.type == "epic"
Load planning/features/[name].md if exists
Read .claude/templates/tasks/story.md and task.md
```

**UX Flows as primary input:** Read the UX Flows doc alongside the PRD. Check epic `ux_flows_ref` field for the path (e.g., `planning/[app-name]/UX_FLOWS.md`). If it exists, this is the primary design input — it contains navigation maps, user journeys (Gherkin format), state machines per screen, interaction specs, and modal flows. All stories and tasks derive from this document alongside the PRD.

### 2. Identify Phases

**Surfaces first:** UI (mock data) → Services → Core Data → Integrations → Security. See `.claude/docs/PLANNING-PROCESS.md`.

### 3. Create Stories (one per phase)

**UX Flows traceability:** Stories derive acceptance criteria from Gherkin journeys in UX Flows. If UX Flows contains journey J1 with steps, those steps become acceptance criteria on the story (J1 → AC on story). Include `ux_flows_refs` in story metadata linking to relevant journey/screen IDs.

```
TaskCreate:
  subject: "Story: Phase N - [Name]"
  description: Summary, User Story, Context, Technical Approach, Dependencies
  metadata:
    schema_version: "2.0", type: "story"
    parent: "[epic-id]"
    story_id: "PROJECT-101", epic_id: "PROJECT-100"
    priority: "P1", approval: "pending", blocked: false
    review_stage: null, review_result: null
    acceptance_criteria: [{id, title, given, when, then, verify}]  (min 3, derived from UX Flows journeys)
    ux_flows_refs: ["J1", "SCR-01"]  (journey and screen IDs this story implements)
    out_of_scope: ["Item 1", "Item 2"]
    implementation_constraints: ["Constraint 1"]
    tasks: [], comments: []
    created_by: "staff-engineer-agent"
```

### 4. Create Tasks (one per deliverable)

**UX Flows traceability:** Tasks derive `local_checks` from state machine transitions in UX Flows. If UX Flows defines state machine transition SM-Login-T3, that becomes a local_check on the task. Include `ux_flows_refs` linking to specific spec IDs the task implements (SM-*, IS-*, J* identifiers).

```
TaskCreate:
  subject: "Task: [Action verb] [Specific deliverable]"
  description: What / Why / How
  metadata:
    schema_version: "2.0", type: "task"
    parent: "[story-id]"
    task_id: "PROJECT-101-1", story_id: "PROJECT-101"
    priority: "P2", approval: "pending", blocked: false
    files: ["app/AppName/AppName/[path].swift"]
    local_checks: ["Check 1", "Check 2", "Check 3"]  (min 3, derived from UX Flows state machine transitions)
    checklist: ["Step 1", "Step 2"]                  (min 2)
    ux_flows_refs: ["SM-Login-T3", "IS-Dashboard-01"]  (spec IDs this task implements)
    completion_signal: "PR merged and story AC still pass"
    validation_hint: "Build succeeds, tests pass"
    ai_execution_hints: ["Hint 1", "Hint 2"]
    hours_estimated: 2
    comments: []
    created_by: "staff-engineer-agent"
```

### 5. Update Story with Task IDs

```
TaskGet [story-id]  ← read before write
TaskUpdate [story-id]: tasks: [{id, title, status, hours}]
```

### 6. Update Epic with Story References

```
TaskGet [epic-id]  ← read before write
TaskUpdate [epic-id]:
  stories: [{
    id: "PROJECT-101",
    claude_task_id: "[TaskCreate result ID]",
    title: "Story: ...",
    description: "...",
    points: 5,
    hours: 6,
    tasks: ["Task: Task 1", "Task: Task 2"]
  }]
```

**Required story object fields (from metadata-schema.md):** `id`, `claude_task_id`, `title`, `description`, `points`, `hours`, `tasks`. No extras.

### 7. Add Planning Comment to Epic

```
TaskGet [epic-id]  ← read before write
TaskUpdate [epic-id]:
  comments: [...existing, {
    id: "C[N]", timestamp: "...", author: "staff-engineer-agent",
    type: "note",
    content: "PLAN PENDING APPROVAL:\n- Stories: [N]\n- Total tasks: [N]\n- Ready for human review"
  }]
```

### 8. Fill UX Flows Traceability Table

If UX Flows doc exists (from epic `ux_flows_ref`), update Section 9 (Traceability) with story/task IDs:
- Map each journey (J*) to the story that implements it
- Map each state machine transition (SM-*-T*) to the task that implements it
- Map each interaction spec (IS-*) to the task that implements it
- This creates a bidirectional link: UX Flows → stories/tasks AND stories/tasks → UX Flows (via `ux_flows_refs`)

### 9. STOP — Wait for Human Approval

---

## Output Format

```
Plan created for [task-id]: [Epic Name]

Story 1: Core Data Layer [story-id]
+-- [task-id] Create entities
+-- [task-id] Add relationships

Story 2: Service Layer [story-id]
+-- [task-id] Build DataManager

Total: [N] stories, [N] tasks

============================================
AWAITING YOUR APPROVAL

Review the plan, then run /approve-epic [epic-id].
Then run /build to start implementation.
============================================
```

---

## Cross-References

| Resource | Location |
|----------|----------|
| Story template | `.claude/templates/tasks/story.md` |
| Task template | `.claude/templates/tasks/task.md` |
| Full schema | `.claude/templates/tasks/metadata-schema.md` |
| Workflow state | `.claude/docs/WORKFLOW-STATE.md` |
