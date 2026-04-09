---
disable-model-invocation: true
description: Scan codebase for technical debt, duplicates, and consolidation opportunities
argument-hint: [scope] - "full" | "changed" | path (default: app/)
---

# /techdebt Command

Scan the codebase for technical debt and generate a prioritized backlog of improvements.

> For v2.0 task schema fields: see `.claude/templates/tasks/metadata-schema.md`
> For TechDebt task template: see `.claude/templates/tasks/techdebt.md`

## Signature

```
/techdebt [scope]
```

**Arguments:** `full` | `changed` | `[path]` | default: `app/`

## What This Command Finds

| Category | Detection Method | Priority |
|----------|------------------|----------|
| **Duplicate Code** | >80% similarity between functions | High |
| **Copy-Paste Blocks** | >10 identical lines | High |
| **Force Unwraps** | `!` usage outside tests | High |
| **Deprecated APIs** | Usage of deprecated Swift/macOS APIs | High |
| **TODO/FIXME Comments** | Grep for TODO, FIXME, HACK | Medium |
| **Large Functions** | >50 lines | Medium |
| **Complex Conditionals** | Deeply nested if/switch | Medium |
| **Missing Tests** | Public functions without test coverage | Medium |
| **SwiftLint Warnings** | Accumulated lint issues | Low |

## Execution Flow

1. **Static Analysis** — SwiftLint with full report + custom pattern detection
2. **Duplicate Detection** — Hash-based similarity, AST-level pattern matching
3. **Code Smell Scan** — Force unwraps, TODO/FIXME, large functions, deep nesting
4. **Test Coverage** — Find public functions without tests, untested ViewModels
5. **Report Generation** — Prioritize findings, estimate effort, suggest consolidations → `planning/techdebt-report.md`

## Detection Patterns

```bash
# Force unwraps (outside tests)
grep -r "!" --include="*.swift" app/ | grep -v "Tests/" | grep -v "\/\/"

# TODO/FIXME (categorize by age via git blame)
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.swift" app/

# ViewModels without test files
grep -l "class.*ViewModel" app/**/*.swift
```

## Report Format

Output to `planning/techdebt-report.md`:

```markdown
# Technical Debt Report
Generated: [timestamp] | Scope: [what was scanned]

## Summary
| Category | Count | Priority |
|----------|-------|----------|
| Duplicate Code | X | High |
| Force Unwraps | X | High |
| ...

**Estimated Total Effort:** X hours

## High Priority (Must Address)
### 1. Duplicate Code: [Location]
Files: [file:lines], [file:lines] | Similarity: 95%
Recommendation: Extract to [shared utility]
Effort: 30 minutes

## Medium Priority (Should Address)
### TODO Comments (Aged > 30 days)
...

## Consolidation Opportunities
### Opportunity 1: [Description]
...

## Recommended Backlog Items
1. [High] [Item] (X min)
```

## Step 6: Create TechDebt Items

After generating the report, create `TechDebt:` tasks using `TaskCreate`:

```typescript
TaskCreate({
  subject: "TechDebt: [Area] - [Brief Description]",
  description: `## Current State\n[Specific problem with files/line numbers]\n\n## Desired State\n[Target pattern after fix]\n\n## Why Now\n[Why worth addressing]\n\n## Regression Risk\n[What could break]`,
  metadata: {
    schema_version: "2.0",
    type: "techdebt",
    parent: null,
    debt_type: "[architectural|quality|test-coverage|dependency|performance|documentation]",
    priority: "[P0-P4]",
    hours_estimated: [0.5-4],
    files_affected: ["[file paths]"],
    regression_risk: "[low|medium|high]",
    compounding: [true|false],
    checklist: ["Step 1", "Step 2"],
    local_checks: ["Check 1", "Check 2", "Check 3"],
    completion_signal: "[clear done condition]",
    validation_hint: "[quick verification method]",
    ai_execution_hints: ["Hint 1"],
    approval: "pending",
    blocked: false,
    review_stage: null,
    review_result: null,
    labels: ["tech-debt"],
    comments: []
  }
})
```

### Sizing Rule

| Finding | Action |
|---------|--------|
| Single file, < 4 hours | One `TechDebt:` item |
| Multiple files, same pattern | One item with all files in `files_affected` |
| > 4 hours total | Split into multiple items or promote to a Story |
| Cross-cutting, phased | Promote to an Epic |

Items start `approval: "pending"` — human approves before work begins.

## Subagent Usage

```
Coordinator
├── Subagent 1: SwiftLint analysis
├── Subagent 2: Duplicate detection
├── Subagent 3: Code smell detection
├── Subagent 4: Test coverage analysis
└── Main: Synthesize report + create TechDebt items
```

## Scheduled Runs

- Before each major release
- After completing an epic
- Monthly maintenance

## Cross-References

- **TechDebt Template:** `.claude/templates/tasks/techdebt.md`
- **Swift Standards:** `.claude/rules/global/swift-strict.md`
- **Testing Requirements:** `.claude/rules/global/testing-requirements.md`
