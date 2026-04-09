---
name: agent-shared-context
description: Shared terminology, review cycle overview, and task state protocol reference for all agents. Preloaded into agent context to avoid duplication across agent prompts.
user-invocable: false
---

# Shared Agent Context

## Terminology

| Term | Definition |
|-|-|
| **Claude Tasks** | The TaskCreate, TaskUpdate, TaskGet, TaskList tool system |
| **Epic** | Top-level initiative (`type: "epic"`) — subject: `Epic: [Name]` |
| **Story** | Phase or component (`type: "story"`) — subject: `Story: [Name]` |
| **Task** | Individual work item (`type: "task"`) — subject: `Task: [Name]` |
| **Bug** | Defect fix (`type: "bug"`) — subject: `Bug: [Name]` |
| **TechDebt** | Maintenance work (`type: "techdebt"`) — subject: `TechDebt: [Name]` |

## Review Cycle

```
Task:         pending → in-progress → completed (NO review)
Story/Bug/TD: Dev → Code Review → QA → Product Review → completed
Epic:         Dev → Code Review → QA → Product Review → Human UAT → completed
Rejection:    review_result:"rejected" → Dev fixes → restart at code-review
```

**Tasks** complete directly — reviews happen at the **Story** level.

## Task State Protocol

All TaskUpdate calls MUST follow `.claude/rules/global/task-state-updates.md`:

1. **Read Before Write** — always TaskGet before TaskUpdate
2. **Claim Before Work** — set status, claimed_by, claimed_at, STARTING comment
3. **Complete With Comments** — implementation + testing comments in same TaskUpdate
4. **Parent Advancement** — after last task in story, advance parent to code-review
5. **Dependency Unblocking** — check blocks array, unblock dependents
6. **Comment Format** — base (5 fields) for most types, trackable (8 fields) for rejections only

## Schema Version

All metadata must use `schema_version: "2.0"`. See skill `v2-schema-reference` for complete field tables.

### v2.0 Field Renames (Tasks)

| v1.0 Name | v2.0 Name | Purpose |
|-----------|-----------|---------|
| `acceptance_criteria` | `local_checks` | Task-specific verification (string array) |
| `subtasks` | `checklist` | Granular implementation steps |
| `verify` | `validation_hint` | Quick verification method |
| `definition_of_done` | (removed) | Now repo-level in CLAUDE.md, not per-task |
| — | `completion_signal` | When is this task done |
| — | `ai_execution_hints` | Guidance for AI agents |

## Workflow State Fields (Stories/Epics ONLY — NOT Tasks)

| Field | Values | Purpose |
|-------|--------|---------|
| `approval` | `"pending"`, `"approved"` | Human approval gate |
| `blocked` | `true`, `false` | Dependency blocking |
| `review_stage` | `"code-review"`, `"qa"`, `"security"`, `"product-review"`, `"human-uat"`, `null` | Current review stage |
| `review_result` | `"awaiting"`, `"rejected"`, `null` | Result at current stage |

**Tasks only have `approval` and `blocked`. Never set `review_stage` or `review_result` on Tasks.**

## Comment Format

**Base comment** (note, implementation, testing, handoff, review, fix):
```json
{ "id": "C1", "timestamp": "[ISO8601]", "author": "[agent]-agent", "type": "[type]", "content": "[text]" }
```

**Trackable comment** (rejection only — adds resolution tracking):
```json
{ "id": "C1", "timestamp": "[ISO8601]", "author": "[agent]-agent", "type": "rejection", "content": "[text]", "resolved": false, "resolved_by": null, "resolved_at": null }
```

For full comment templates by stage, see skill `review-cycle`.

## Product Review Depth (PM-4 through PM-8)

### User Journey Mapping (PM-4)
When reviewing a Story, walk the primary user flow step-by-step. At each step ask: "Would the user know what to do next?" Document friction points.

### Regression Checking (PM-5)
Verify changes don't break existing flows. Check: do existing keyboard shortcuts still work? Does window resizing behave correctly? Do previously working features still function?

### Discoverability Evaluation (PM-6)
Can a new user figure out this feature without instructions? Is the information hierarchy clear? Are primary actions visually obvious?

### Stakeholder Communication (PM-7)
When rejecting: explain the user impact, not just the technical issue. When approving: summarize what was delivered in user terms.

### AC Quality Evaluation (PM-8)
Before accepting planning output, verify ACs are: Observable (visible outcome), Testable (verifiable), Unique (no overlap), Complete (happy + error + edge case).

## Planning Methodology (PLAN-4 through PLAN-6)

### Risk Assessment (PLAN-4)
For each risk, evaluate: **Probability** (Low/Medium/High) x **Impact** (Low/Medium/High). Categories: Technical (can we build it?), Schedule (will it take longer?), Scope (will requirements change?), Resource (do we have the skills?).

### Story Sizing — INVEST Criteria (PLAN-5)
Each story should be: **I**ndependent (minimal dependencies), **N**egotiable (scope can flex), **V**aluable (delivers user value), **E**stimable (team can size it), **S**mall (fits in one build cycle), **T**estable (has verifiable ACs). If a story fails INVEST, split it.

### Phase Decomposition (PLAN-6)
Beyond surfaces-first, consider: **Risk-first** (tackle unknowns early), **Learning-first** (build the simplest version to validate assumptions), **Dependency-first** (unblock other stories). Default to surfaces-first; deviate only when risk or learning concerns override it.
