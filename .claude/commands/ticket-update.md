---
description: Update a ticket's workflow state by logical ID (e.g., CASHFLOW-1100) and target stage. Handles all field updates and cascading effects.
argument-hint: <ticket-id> <stage> (e.g., CASHFLOW-1100 human-uat)
---

# /ticket-update

Manually advance or set a ticket's workflow state using its logical project ID.

> **Task State Protocol:** All TaskUpdate calls MUST follow `.claude/rules/global/task-state-updates.md`.
> For workflow state fields and valid values: see `.claude/docs/WORKFLOW-STATE.md`

## Usage

```
/ticket-update <ticket-id> <stage>
```

**Examples:**
```
/ticket-update CASHFLOW-1100 human-uat
/ticket-update CASHFLOW-101 code-review
/ticket-update CASHFLOW-101-3 completed
/ticket-update CASHFLOW-200 approved
/ticket-update CASHFLOW-305 rejected
/ticket-update CASHFLOW-101-1 blocked
```

## Valid Stages

### Universal (all ticket types)

| Stage | What It Does |
|-------|-------------|
| `approved` | Sets `approval: "approved"`. Cascades to all children if epic/story. |
| `in-progress` | Sets `status: "in_progress"`. |
| `completed` | Sets `status: "completed"`, clears `review_stage`/`review_result` to null. |
| `blocked` | Sets `blocked: true`. |
| `unblocked` | Sets `blocked: false`. |

### Review Stages (Story, Epic, Bug, TechDebt only — NOT Task)

| Stage | What It Sets |
|-------|-------------|
| `code-review` | `review_stage: "code-review"`, `review_result: "awaiting"` |
| `qa` | `review_stage: "qa"`, `review_result: "awaiting"` |
| `security` | `review_stage: "security"`, `review_result: "awaiting"` |
| `product-review` | `review_stage: "product-review"`, `review_result: "awaiting"` |
| `human-uat` | `review_stage: "human-uat"`, `review_result: "awaiting"` (Epic only) |
| `rejected` | `review_result: "rejected"` (keeps current `review_stage`) |
| `passed` | Advances to next review stage automatically (see Advancement Rules) |

### Stage Applicability

| Stage | Epic | Story | Task | Bug | TechDebt |
|-------|------|-------|------|-----|-------|
| `approved` | Y | Y | Y | Y | Y |
| `in-progress` | Y | Y | Y | Y | Y |
| `completed` | Y | Y | Y | Y | Y |
| `blocked/unblocked` | Y | Y | Y | Y | Y |
| `code-review` through `product-review` | Y | Y | - | Y | Y |
| `human-uat` | Y | - | - | - | - |
| `rejected`/`passed` | Y | Y | - | Y | Y |

## Advancement Rules (`passed`)

| Current `review_stage` | Next State |
|------------------------|------------|
| `"code-review"` | `review_stage: "qa"`, `review_result: "awaiting"` |
| `"qa"` | `review_stage: "product-review"`, `review_result: "awaiting"` |
| `"security"` | `review_stage: "product-review"`, `review_result: "awaiting"` |
| `"product-review"` (Story/Bug/TechDebt) | `review_stage: null`, `review_result: null`, `status: "completed"` |
| `"product-review"` (Epic) | `review_stage: "human-uat"`, `review_result: "awaiting"` |
| `"human-uat"` (Epic) | `review_stage: null`, `review_result: null`, `status: "completed"` |
| `null` | **Error** — nothing to pass |

## Cascading Effects

- **`approved` on Epic:** Cascades to all child stories and tasks
- **`approved` on Story:** Cascades to all child tasks
- **`completed` on Task:** If all siblings done, auto-advances parent story to `code-review` (Protocol 4); unblocks dependents (Protocol 5)
- **`completed` on Story:** If all siblings done, auto-advances parent epic to `code-review`; unblocks dependents
- **`rejected`:** After dev fixes, move to `code-review` (full cycle restart)

## Flow

```
1. PARSE arguments — extract <ticket-id> and <stage>
2. FIND ticket by logical ID via TaskList
   - Epic:  metadata.id == <ticket-id>
   - Story: metadata.story_id == <ticket-id>
   - Task:  metadata.task_id == <ticket-id>
3. VALIDATE stage is valid for this ticket type
4. READ current state via TaskGet
5. COMPUTE field changes based on <stage>
6. APPLY changes via TaskUpdate with state-change comment
7. APPLY cascading effects (if applicable)
8. REPORT results
```

Every state change adds a structured comment (Protocol 6 format from task-state-updates.md).

## Output Format

### Success
```
Ticket Update: CASHFLOW-1100 → human-uat

Type:    Epic
Title:   Epic: CASHFLOW-1100 - Dashboard & Reporting
ID:      42 (Claude Tasks)

Changes Applied:
  review_stage:  "product-review" → "human-uat"
  review_result: "awaiting" → "awaiting"

Cascading Effects: None
State change comment added (C7).
```

### Success with Cascading
```
Ticket Update: CASHFLOW-200 → approved
...
Cascading Effects:
  - Story CASHFLOW-201 (id: 16) → approved
  - Task CASHFLOW-201-1 (id: 18) → approved
  Total: 5 children updated
```

### Errors
- `"Ticket <id> not found"` — check metadata.id / story_id / task_id fields
- `"Stage 'human-uat' is not valid for Stories"` — see applicability table
- `"Cannot set 'rejected' — ticket is not currently in review"`

## Related Commands

| Command | Difference |
|---------|-----------|
| `/workflow-fix` | Auto-fixes inconsistencies. `/ticket-update` is intentional manual changes. |
| `/workflow-audit` | Reads and reports state; doesn't change anything. |
| `/approve-epic` | Specifically for cascading approval to entire epic tree. `/ticket-update approved` works on individual items. |
| `/build` | Claims and implements a task. `/ticket-update in-progress` just changes state. |
