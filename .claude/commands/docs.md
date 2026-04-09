---
description: Create, update, or audit project documentation. Module specs, ADRs, changelogs, drift detection. Delegates to Documentation agent.
argument-hint: capture [story-id] | complete [story-id] | audit
---

# /docs

Documentation agent creates and maintains agent-consumed documentation: module specifications, Architecture Decision Records, changelogs, and drift detection.

**Schema Version:** 2.0

## Modes

| Mode | Trigger | What It Does |
|---|---|---|
| `capture` | After code review passes | Primary doc pass — creates/updates module specs and ADRs from code changes |
| `complete` | After story completes | Changelog entry + drift detection across ALL existing docs |
| `audit` | On demand | Full verification of all specs against code, health report |

## Arguments

- `capture [story-id]` — Run after story passes code review (`review_stage: "qa"`)
- `complete [story-id]` — Run after story reaches `status: "completed"`
- `audit` — No story ID needed. Verifies all documentation against code.

## Flow

### /docs capture [story-id]

1. **Validate:** Story exists and has `review_stage: "qa"` (code review already passed)
2. **Delegate to Documentation agent** with prompt:
   ```
   Run capture mode for story [story-id].
   Read the agent definition at .claude/agents/documentation-agent.md for full workflow.
   Read templates from .claude/templates/docs/ before creating any documentation.
   Ensure docs/ directory exists in the app repo. Create it if needed.
   Add a documentation comment to the story when done.
   Keep your final response under 500 characters.
   ```
3. **Verify:** Documentation comment was added to the story

### /docs complete [story-id]

1. **Validate:** Story exists and has `status: "completed"`
2. **Delegate to Documentation agent** with prompt:
   ```
   Run completion mode for story [story-id].
   Read the agent definition at .claude/agents/documentation-agent.md for full workflow.
   Read templates from .claude/templates/docs/ before creating any documentation.
   Generate changelog entry and run drift detection on ALL existing module specs.
   Add a documentation comment to the story when done.
   Keep your final response under 500 characters.
   ```
3. **Verify:** Changelog entry exists, documentation comment added

### /docs audit

1. **Delegate to Documentation agent** with prompt:
   ```
   Run audit mode.
   Read the agent definition at .claude/agents/documentation-agent.md for full workflow.
   Verify all module specs in docs/modules/ against actual code.
   Check ADR growth limits (warn at 30 active, hard limit 40).
   Check for superseded ADRs that need compression.
   Generate health report. Keep your final response under 2000 characters.
   ```
2. **Display:** Health report to user

## Pre-Conditions

- `capture`: Story must have `review_stage: "qa"` and `review_result: "awaiting"`
- `complete`: Story must have `status: "completed"`
- `audit`: No preconditions. Can run anytime.

## Output

### capture/complete
```
Documentation updated for [story-id] "[Story Title]"
Module specs: [created/updated count]
ADRs: [created count or 'none']
Changelog: [entry added or 'N/A']
Drift detected: [count or 'none']
```

### audit
```
Documentation Health Report
===========================
Module specs: X verified, Y stale, Z missing
ADRs: X active, Y superseded (X need compression)
ADR growth: [OK | WARNING: X/40 active]

Issues:
1. [type] [description]
...

Recommendations:
- [action items]
```
