---
description: Run static UI quality audit on changed files. Used during code review for UI stories.
argument-hint: story-id or file path
---

# /ui-audit

Static UI quality audit that checks SwiftUI View files for Liquid Glass, layout, navigation, accessibility, and visual patterns.

## Delegation

**IMMEDIATELY delegate to UI Audit agent** (`ui-audit-agent`).

## Arguments

- `<story-id>` — Audit all View files changed in this story's tasks
- `<file-path>` — Audit a specific View file or directory
- If omitted: prompt user for story ID or file path

## Flow

1. **Resolve file list:**
   - If story-id provided:
     ```
     TaskGet [story-id]
     # Read child tasks, collect files_changed from implementation comments
     # Filter to *.swift files in Views/ directories
     ```
   - If file path provided: use directly
   - If directory provided: Glob for `**/*View*.swift` and `**/*Screen*.swift`

2. **Delegate to UI Audit agent** with:
   - File list to audit
   - Story ID (if provided, for attaching findings as comment)
   - Instructions: "Run all 5 audit passes. Return structured findings with risk score."

3. **Agent runs 5 audit passes:**
   - Pass 1: Liquid Glass (`.glassEffect()` usage, materials, stacking)
   - Pass 2: Layout (GeometryReader, UIScreen, hardcoded frames, lazy containers)
   - Pass 3: Navigation (NavigationView, TabView, column widths, deprecated wrappers)
   - Pass 4: Accessibility (labels, focusable, hidden interactive)
   - Pass 5: Visual Verification (Peekaboo screenshot if available)

4. **Returns structured findings** with:
   - Per-finding: file:line, category, severity, current code, fix suggestion
   - Summary: counts by severity, risk score, PASS/PASS WITH NOTES/FAIL verdict

5. **If story-id provided:** findings added as comment on story task

## Output Format

```
UI Audit: [story-id or file path]

Files audited: [N]

## Results

Risk score: [X] — [PASS | PASS WITH NOTES | FAIL]

| Category | Critical | High | Medium | Low |
|----------|----------|------|--------|-----|
| Liquid Glass | 0 | 1 | 0 | 0 |
| Layout | 0 | 0 | 2 | 1 |
| Navigation | 1 | 0 | 0 | 0 |
| Accessibility | 0 | 2 | 0 | 0 |
| Visual | — | — | — | — |

## Top Findings

1. [Critical] Navigation: NavigationView deprecated
   File: Views/Screens/DashboardView.swift:15
   Fix: Replace with NavigationSplitView

2. [High] Accessibility: Button without label
   File: Views/Components/ActionBar.swift:42
   Fix: Add .accessibilityLabel("Delete item")

3. [High] Liquid Glass: .glassEffect() on static container
   File: Views/Screens/DashboardView.swift:28
   Fix: Move to interactive child element or use material modifier

## Verdict

[PASS: No blocking issues. | PASS WITH NOTES: Issues noted in review comment. | FAIL: Recommend rejection — [N] critical findings.]
```

## Pre-Conditions

- View files exist at the specified paths
- Design system skill available at `.claude/skills/design-system/`

## When to Use

- During `/code-review` for stories with UI changes
- Before submitting UI work for review
- As a standalone quality check on any View file
- After `/ui-polish` to verify fixes resolved flagged patterns

## Integration with Code Review

The staff engineer agent runs `/ui-audit` automatically during code review when the story contains View files. Findings are incorporated into the code review verdict:
- Critical findings → automatic FAIL
- High findings → require justification to pass
- Medium/Low → noted but not blocking
