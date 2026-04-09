# TechDebt Template (v2.0)

Tech debt items represent code that works today but creates drag on velocity, reliability, or safety over time. Unlike bugs (something is broken) or features (new user value), tech debt addresses the quality of existing working code.

**Schema Version:** 2.0 (AI-first schema)

**Review Cycle:** Code Review → QA (regression check) → Product Review → Completed

---

## Title Format

**REQUIRED PREFIX:** All tech debt subjects MUST begin with `TechDebt: `

```
TechDebt: [Area] - [Brief Description]
```

**Area** is the file, layer, or component affected. **Description** is the specific problem.

Examples:
- `TechDebt: LoginView - Remove force unwraps in authentication flow`
- `TechDebt: SessionViewModel - Migrate to @Observable macro`
- `TechDebt: TaskParserService - Add missing unit test coverage`
- `TechDebt: Alamofire - Upgrade to 5.9.x for Swift 6 compatibility`
- `TechDebt: CoreDataStack - Extract PersistenceController from AppDelegate`

---

## Description Sections

### Required Sections

```markdown
## Current State
<What the code looks like now and why it's a problem. Be specific: file names, line ranges, patterns observed.>

## Desired State
<What the code should look like after this is resolved. Describe the target pattern, not just "make it better.">

## Why Now
<Why is this worth addressing now vs. deferring? How does it affect current or upcoming work?>

## Regression Risk
<What could break if we change this? What existing tests provide safety? What manual checks are needed?>
```

---

## Complete Metadata Structure (v2.0)

Every tech debt item MUST include ALL of these fields.

```json
{
  "schema_version": "2.0",
  "type": "techdebt",
  "parent": null,

  "debt_type": "quality",
  "debt_category": "force-unwrap",
  "discovered_by": "techdebt-scan",
  "discovered_at": "2026-02-19T10:00:00Z",

  "priority": "P3",

  "assignee": null,
  "claimed_by": null,
  "claimed_at": null,

  "hours_estimated": 2,
  "hours_actual": null,

  "files_affected": [
    "app/AppName/AppName/Views/Login/LoginView.swift"
  ],

  "regression_risk": "medium",
  "compounding": false,
  "impact_if_deferred": "Force unwraps in auth flow will crash on nil password during edge-case empty keychain state.",
  "business_justification": "Prevents potential crash during first-launch flow; unblocks Swift 6 strict concurrency adoption.",

  "checklist": [
    "Audit all ! usages in the affected file(s)",
    "Replace with guard let / if let / nil coalescing as appropriate",
    "Ensure no behavior change (same outputs for same inputs)",
    "Run existing tests to confirm no regression"
  ],

  "local_checks": [
    "Zero force unwraps remain in files_affected",
    "Build succeeds with no new warnings",
    "All existing tests pass without modification",
    "No behavioral change to login flow (manual smoke test)"
  ],

  "completion_signal": "PR merged, all tests green, no new SwiftLint warnings introduced.",
  "validation_hint": "swiftlint run on affected files, xcodebuild test passes.",

  "ai_execution_hints": [
    "Check for ! in guard conditions, optional chains, and downcasts — not just property access.",
    "Prefer guard let for early-exit paths; prefer nil coalescing for default-value patterns.",
    "Do NOT change public interfaces or method signatures — refactor internals only."
  ],

  "approval": "pending",
  "blocked": false,
  "review_stage": null,
  "review_result": null,

  "labels": ["tech-debt", "quality"],

  "comments": [],

  "created_at": "2026-02-19T10:00:00Z",
  "created_by": "techdebt-scan",
  "last_updated_at": "2026-02-19T10:00:00Z"
}
```

---

## Field Reference

### Identification Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | string | YES | Must be `"2.0"` |
| `type` | string | YES | Must be `"techdebt"` |
| `parent` | string | NO | Task ID of parent story/epic if part of a larger effort; `null` if standalone |

### Debt Classification Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `debt_type` | string | YES | Primary category (see values below) |
| `debt_category` | string | YES | Specific sub-type (see values below) |
| `discovered_by` | string | YES | How this was found |
| `discovered_at` | ISO8601 | YES | When this was identified |

#### `debt_type` Values

| Value | Meaning |
|-------|---------|
| `"architectural"` | Wrong pattern, MVVM violation, responsibility leak, god object |
| `"quality"` | Force unwraps, magic numbers, duplication, dead code, long functions |
| `"test-coverage"` | Missing tests, flaky tests, untested ViewModels/Services |
| `"dependency"` | Outdated packages, deprecated APIs, insecure or unused deps |
| `"performance"` | Main-thread blocks, memory leaks, unnecessary re-renders, N+1 queries |
| `"documentation"` | Missing or stale inline comments, undocumented public APIs |

#### `debt_category` Examples (by debt_type)

| debt_type | debt_category examples |
|-----------|------------------------|
| `architectural` | `"mvvm-violation"`, `"missing-protocol"`, `"actor-misuse"`, `"god-object"`, `"responsibility-leak"` |
| `quality` | `"force-unwrap"`, `"magic-number"`, `"duplication"`, `"dead-code"`, `"long-function"`, `"poor-naming"` |
| `test-coverage` | `"missing-tests"`, `"flaky-test"`, `"untested-viewmodel"`, `"untested-service"` |
| `dependency` | `"outdated-dep"`, `"deprecated-api"`, `"insecure-dep"`, `"unused-dep"` |
| `performance` | `"main-thread-block"`, `"memory-leak"`, `"unnecessary-rerender"`, `"n-plus-one"` |
| `documentation` | `"missing-inline-comments"`, `"stale-docs"`, `"undocumented-public-api"` |

#### `discovered_by` Values

| Value | Meaning |
|-------|---------|
| `"techdebt-scan"` | Found by `/techdebt` command scan |
| `"code-review"` | Surfaced during story code review |
| `"incident"` | Found while investigating a bug or incident |
| `"developer"` | Noticed during normal development |
| `"qa"` | Found during QA testing |

### Impact Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `files_affected` | string[] | YES | Files that need to change (min 1) |
| `regression_risk` | string | YES | `"low"` \| `"medium"` \| `"high"` |
| `compounding` | boolean | YES | Does deferred debt generate more debt? |
| `impact_if_deferred` | string | YES | What gets worse if this is not addressed |
| `business_justification` | string | YES | Why fix it now (velocity, reliability, upcoming work) |

#### `regression_risk` Guidance

| Value | When to Use |
|-------|-------------|
| `"low"` | Isolated change, full test coverage exists, single file |
| `"medium"` | Multiple files, partial test coverage, touches shared utilities |
| `"high"` | Cross-cutting refactor, sparse tests, changes interfaces or shared state |

### Sizing Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `hours_estimated` | number | YES | Estimated hours (0.5–4h; split if larger) |
| `hours_actual` | number | YES | Actual hours (null until complete) |

**Rule:** If a tech debt item exceeds 4 hours, break it into multiple items or promote it to a Story with tasks.

### Work Fields

| Field | Type | Required | Min Count | Description |
|-------|------|----------|-----------|-------------|
| `checklist` | string[] | YES | 2 | Granular steps to complete |
| `local_checks` | string[] | YES | 3 | Specific, testable assertions that must be true after the fix |
| `completion_signal` | string | YES | — | When is this item done? Clear stop condition. |
| `validation_hint` | string | YES | — | How to quickly verify completion |
| `ai_execution_hints` | string[] | RECOMMENDED | — | Guidance for AI agents on approach and constraints |

### Workflow Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `approval` | string | YES | `"pending"` until human approves |
| `blocked` | boolean | YES | `false` unless a dependency is unmet |
| `review_stage` | string | YES | `null` initially; advances through `"code-review"` → `"qa"` → `"product-review"` |
| `review_result` | string | YES | `null` initially; `"awaiting"` or `"rejected"` |
| `labels` | string[] | YES | Categorization only — always include `"tech-debt"` |

---

## Priority Guidelines for Tech Debt

| Priority | Meaning | When to Use |
|----------|---------|-------------|
| P0 | Critical blocker | Debt is actively causing crashes or security issues |
| P1 | Must fix soon | Blocks an upcoming epic or creates high regression risk |
| P2 | Fix this sprint | Compounding debt, or impairs developer velocity noticeably |
| P3 | Fix when available | Standard cleanup, low compounding risk |
| P4 | Backlog | Cosmetic, no urgency, no compounding |

---

## TaskCreate Usage (v2.0)

```typescript
await TaskCreate({
  subject: "TechDebt: SessionViewModel - Migrate to @Observable macro",
  description: `## Current State
SessionViewModel uses the old ObservableObject/Published pattern from Swift 5.x. This creates
unnecessary Combine boilerplate and prevents adoption of the @Observable macro available in macOS 14+.
Affected file: app/AppName/AppName/ViewModels/SessionViewModel.swift

## Desired State
SessionViewModel uses @Observable macro. All @Published properties become regular stored properties.
All @ObservedObject references in views become plain let bindings. No Combine imports remain.

## Why Now
The upcoming Phase 3 epic adds 4 new ViewModels. Migrating now establishes the correct pattern
before it propagates further. Also required for Swift 6 strict concurrency compliance.

## Regression Risk
Medium — SessionViewModel is used in 3 views. Existing unit tests cover state transitions.
Manual smoke test: launch app, verify session persists across view transitions.`,
  activeForm: "Migrating SessionViewModel to @Observable",
  metadata: {
    schema_version: "2.0",
    type: "techdebt",
    parent: null,
    debt_type: "architectural",
    debt_category: "mvvm-violation",
    discovered_by: "techdebt-scan",
    discovered_at: "2026-02-19T10:00:00Z",
    priority: "P2",
    assignee: null,
    claimed_by: null,
    claimed_at: null,
    hours_estimated: 2,
    hours_actual: null,
    files_affected: [
      "app/AppName/AppName/ViewModels/SessionViewModel.swift",
      "app/AppName/AppName/Views/MainView.swift",
      "app/AppName/AppName/Views/SettingsView.swift"
    ],
    regression_risk: "medium",
    compounding: true,
    impact_if_deferred: "Each new ViewModel added before this fix will use the wrong pattern, multiplying migration cost.",
    business_justification: "Unblocks Phase 3 epic and Swift 6 migration. Establishes correct pattern for all new ViewModels.",
    checklist: [
      "Replace @ObservableObject conformance with @Observable macro",
      "Remove all @Published property wrappers — convert to plain stored properties",
      "Update view references from @ObservedObject to plain let bindings",
      "Remove Combine import if no longer needed",
      "Run existing tests and confirm all pass"
    ],
    local_checks: [
      "SessionViewModel has no @ObservableObject or @Published references",
      "All 3 consuming views compile without @ObservedObject",
      "Combine is not imported in SessionViewModel.swift",
      "All existing SessionViewModelTests pass without modification",
      "App launches and session state persists correctly across views"
    ],
    completion_signal: "PR merged, all tests green, no Combine imports remain in affected files.",
    validation_hint: "xcodebuild build + test passes; grep for @Published in files_affected returns empty.",
    ai_execution_hints: [
      "Do NOT change the public API (method signatures, property names) — only the implementation pattern.",
      "Check for any Combine-specific operators (.sink, .assign) before removing the import.",
      "Views referencing SessionViewModel should use `let viewModel: SessionViewModel` — no property wrapper needed with @Observable."
    ],
    approval: "pending",
    blocked: false,
    review_stage: null,
    review_result: null,
    labels: ["tech-debt", "architectural"],
    comments: [],
    created_at: "2026-02-19T10:00:00Z",
    created_by: "techdebt-scan",
    last_updated_at: "2026-02-19T10:00:00Z"
  }
});
```

---

## Validation Checklist (v2.0)

### Before creating the tech debt item, verify ALL of these:

#### Identification (3 checks)
- [ ] `schema_version` is "2.0"
- [ ] `type` is "techdebt"
- [ ] Title starts with `TechDebt: ` and includes `[Area] - [Description]`

#### Description (4 checks)
- [ ] Has Current State section (specific, names files)
- [ ] Has Desired State section (describes target pattern, not vague goal)
- [ ] Has Why Now section (justification for addressing now)
- [ ] Has Regression Risk section (what could break, what tests exist)

#### Debt Classification (4 checks)
- [ ] `debt_type` uses a valid value
- [ ] `debt_category` is specific (not just "other")
- [ ] `discovered_by` uses a valid value
- [ ] `discovered_at` is valid ISO 8601

#### Impact (4 checks)
- [ ] `files_affected` lists all files (min 1)
- [ ] `regression_risk` is set to "low", "medium", or "high"
- [ ] `impact_if_deferred` explains what gets worse over time
- [ ] `business_justification` explains why fix it now

#### Sizing (2 checks)
- [ ] `hours_estimated` is between 0.5 and 4
- [ ] If > 4 hours, item has been split or promoted to a Story

#### Work Fields (4 checks)
- [ ] `checklist` has at least 2 items
- [ ] `local_checks` has at least 3 specific, testable assertions
- [ ] `completion_signal` clearly defines "done"
- [ ] `validation_hint` describes how to verify quickly

#### Workflow Fields (4 checks)
- [ ] `approval` is "pending"
- [ ] `blocked` is false (unless a dependency is unmet)
- [ ] `review_stage` is null
- [ ] `review_result` is null

#### Labels (1 check)
- [ ] `labels` includes `"tech-debt"` plus the relevant category tag

---

## Minimum Requirements Summary

| Field | Minimum |
|-------|---------|
| `files_affected` | 1 |
| `checklist` | 2 |
| `local_checks` | 3 |
| `hours_estimated` | 0.5–4 (split if larger) |
| `labels` | Must include `"tech-debt"` |

---

## When to Promote to Story or Epic

Keep as a single tech debt item when:
- Completable in 1–4 hours
- Touches a focused set of files (1–5)
- One clear current → desired state transformation

Promote to a **Story with TechDebt tasks** when:
- Multiple areas need the same fix (e.g., migrate 8 ViewModels to @Observable)
- > 4 hours of work

Promote to an **Epic** when:
- The debt is architectural and affects every layer (e.g., adopt Swift 6 strict concurrency across the whole app)
- Requires phased delivery

---

## Anti-Patterns

| DO NOT | DO INSTEAD |
|--------|------------|
| Vague current state ("code is messy") | Be specific: name files, patterns, line counts |
| Vague desired state ("make it better") | Describe the exact target pattern |
| Skip `impact_if_deferred` | Always explain the compounding risk |
| Items > 4 hours | Split into multiple items or promote to Story |
| `local_checks` that can't be tested | Every check must be verifiable (grep, build, test) |
| Using `type: "chore"` for tech debt | Use `type: "techdebt"` for proper filtering |
| Omitting `"tech-debt"` from labels | Always include it — enables TaskList filtering |
| Creating without a regression risk assessment | Every refactor has risk; document it explicitly |

---

## Cross-References

- **Task Template:** `.claude/templates/tasks/task.md`
- **Story Template:** `.claude/templates/tasks/story.md`
- **Metadata Schema:** `.claude/templates/tasks/metadata-schema.md`
- **Tech Debt Command:** `.claude/commands/techdebt.md`
