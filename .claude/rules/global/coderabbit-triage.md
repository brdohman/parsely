---
description: Triage protocol for CodeRabbit findings — structured recommendations, user decides, never dismiss without accountability
---

# CodeRabbit Findings Triage Protocol

## When This Applies

Every time CodeRabbit findings are reviewed — at story-level code review (`/code-review`, `/build-story`, `/build-epic`) and at PR-level review (`/complete-epic` git finalization).

## The Rule

⛔ **Never dismiss a CodeRabbit finding without user decision.** Every finding gets a structured recommendation. The user decides what to fix, defer, or acknowledge.

⛔ **Never dismiss a finding because it's "outside the diff" or "from a prior commit."** Evaluate every finding on its merit, regardless of when the code was introduced.

---

## Severity-Based Response

Every finding gets a recommendation based on severity AND merit — not based on which commit introduced it.

| Severity | Default Recommendation | Reasoning |
|---|---|---|
| **Critical** | FIX | Blocks merge. Security vulnerability, data loss risk, crash. |
| **High** | FIX | Significant bug, incorrect behavior, architectural problem. |
| **Medium** | FIX or TECHDEBT | Evaluate: if < 30min and in-scope files, recommend FIX. If larger or out-of-scope, recommend TECHDEBT. |
| **Low/Nitpick** | FIX or NOTE | If trivial (< 5min), recommend FIX. Otherwise present with reasoning and let user decide. |

---

## Outside-Diff Findings

When CodeRabbit re-flags something from a prior commit or on lines outside the current diff:

```
1. CHECK: Was this actually fixed in a prior commit?
   → git log --oneline --all -S "<relevant code>" -- <file>
   → Read the file at the flagged line

2. If FIXED: Mark as "VERIFIED FIXED in commit [hash]"
   → No task needed, no user action needed

3. If NOT FIXED: Evaluate on merit at its severity level
   → If in-scope (files we're already touching): recommend FIX
   → If out-of-scope: recommend TECHDEBT (create task for later)

4. If UNCLEAR: Spawn research agent to verify the finding
   → Then recommend based on research result
```

---

## Research for Uncertain Findings

When the reviewing agent isn't sure if a CodeRabbit finding is valid:

1. Note the finding as "NEEDS RESEARCH"
2. Coordinator spawns research agent: "Verify: [CodeRabbit's claim]. Is [API/pattern] correct or deprecated?"
3. Research agent returns with `[VERIFIED: source]` or `[UNVERIFIED]`
4. Update the recommendation with research backing

```
Finding: Using NavigationView instead of NavigationStack
Before research: Recommendation unclear
After research:  FIX — NavigationView deprecated in iOS 16 [VERIFIED: developer.apple.com]
```

---

## Recommendation Tags

| Tag | Meaning | Action |
|---|---|---|
| **FIX** | Recommend fixing now | Agent provides reasoning + effort estimate |
| **TECHDEBT** | Out-of-scope, not fixed — defer | Create TechDebt task with finding as description |
| **VERIFIED FIXED** | Was flagged but already fixed | Note commit hash, close — no action needed |
| **VERIFY** | Need to check if already fixed | Agent or research agent investigates |
| **RESEARCHED** | Was uncertain, research confirmed | Include source citation in reasoning |
| **NOTE** | Informational, not a bug | Present to user with context |

---

## Presentation Format

Present ALL findings in a batch table, never one at a time. The user needs the full picture to make decisions.

```
CodeRabbit Review — [N] findings

┌───┬──────────┬──────────────────────────────────┬───────────────┬────────┐
│ # │ Severity │ Finding                          │ Recommendation│ Effort │
├───┼──────────┼──────────────────────────────────┼───────────────┼────────┤
│ 1 │ High     │ [description]                    │ FIX           │ ~N min │
│ 2 │ Medium   │ [description]                    │ FIX           │ ~N min │
│ 3 │ Medium   │ [outside diff] [description]     │ TECHDEBT      │ ~N min │
│ 4 │ Medium   │ [outside diff] [description]     │ VERIFIED FIXED│ —      │
│ 5 │ Nitpick  │ [description]                    │ FIX           │ ~N min │
│ 6 │ Medium   │ [uncertain] [description]        │ RESEARCHED    │ ~N min │
└───┴──────────┴──────────────────────────────────┴───────────────┴────────┘

Details:
  #1: [full reasoning with source citations if researched]
  #2: [full reasoning]
  ...

Actions:
  (a) Fix all recommended — fix [list], create TechDebt for [list], close [verified list]
  (b) Let me pick — I'll tell you which to fix, defer, or skip
  (c) Fix everything — fix all findings regardless of recommendation
```

**Each finding's detail section MUST include:**
- File and line number
- What's wrong (CodeRabbit's finding)
- Why the recommendation (agent's reasoning)
- Source citation if researched `[VERIFIED: url]`
- Effort estimate

---

## TechDebt Task Format

When creating a TechDebt task for a deferred finding:

```
TaskCreate:
  subject: "TechDebt: [CodeRabbit finding summary]"
  type: "techdebt"
  description: "## What\n[CodeRabbit finding detail]\n\n## Source\nCodeRabbit review during [story-id/epic-id] code review.\nOriginal file: [file:line]\nSeverity: [severity]\n\n## Why Deferred\nOutside scope of current work. Filed for future cleanup."
  metadata:
    schema_version: "2.0"
    type: "techdebt"
    priority: "P3"
    approval: "pending"
    blocked: false
    local_checks: ["[specific fix verification]"]
    completion_signal: "CodeRabbit finding resolved, no regression"
    comments: []
```

---

## Integration Points

### Story-Level Code Review (/code-review, /build-story, /build-epic)

After CodeRabbit agent returns findings:
1. Coordinator applies this triage protocol
2. For outside-diff findings: verify or create TechDebt
3. For uncertain findings: spawn research agent
4. Present batch table to user
5. Execute user's decision

### PR-Level Review (/complete-epic)

After CodeRabbit reviews the PR on GitHub:
1. Retrieve findings: `gh api repos/{owner}/{repo}/pulls/{N}/comments`
2. Also check: `gh api repos/{owner}/{repo}/pulls/{N}/reviews`
3. Apply same triage protocol
4. Present batch table to user
5. If user says fix: spawn developer agent, push fixes, CI re-runs

---

## Never

- Dismiss a finding because it's "outside the diff"
- Dismiss a finding because it's "from a prior commit" without verifying the fix
- Skip presenting findings to the user
- Let the agent decide which findings to fix vs skip — the user decides
- Present findings one at a time (use batch table)
- Omit effort estimates from recommendations
- Create a FIX recommendation without reasoning
- Skip research when the finding's validity is uncertain
