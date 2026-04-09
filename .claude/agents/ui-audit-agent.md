---
name: ui-audit
description: "Static analysis for SwiftUI UI quality. Checks Liquid Glass, layout, navigation, accessibility patterns."
tools: Read, Glob, Grep, TaskGet, TaskUpdate
skills: macos-design-system, ui-review-tahoe, agent-shared-context
model: sonnet
maxTurns: 30
permissionMode: bypassPermissions
---

# UI Audit Agent

Static analysis agent for SwiftUI UI quality. Runs pattern-based checks on View files and produces structured findings with risk scoring.

> ⛔ **Task State Protocol:** You MUST follow `.claude/rules/global/task-state-updates.md` for ALL TaskUpdate calls.

## Inputs

- **File list:** Paths to `.swift` View files to audit (passed in spawn prompt)
- **Story ID:** (optional) Task ID to attach findings as a comment

## Audit Process

Run all 5 audit passes on each file. Collect findings, score them, and produce a structured report.

---

## Pass 1: Liquid Glass Audit

Check correct usage of macOS 26 glass and material APIs.

### Checks

1. **`.glassEffect()` on non-interactive elements** (High)
   - Grep for `.glassEffect()` in each file
   - Read surrounding context — verify it's applied to `Button`, `Toggle`, toolbar items, or `GlassEffectContainer` children
   - If applied to `Text`, `VStack`, `HStack`, static containers → flag

2. **Material context correctness** (Medium)
   - Grep `.ultraThinMaterial`, `.regularMaterial`, `.thickMaterial`
   - Verify context matches expected usage:
     - `.ultraThinMaterial` / `.regularMaterial` → content cards, panels
     - `.thickMaterial` → sheets, popovers
   - Flag if `.ultraThinMaterial` used on sheets or `.thickMaterial` on content cards

3. **Manual blur+overlay patterns** (Medium)
   - Grep for `.blur(radius:` combined with `.overlay` in the same view
   - Flag as "migrate to `.glassEffect()` or material modifier"

4. **Material stacking** (High)
   - Look for nested views where both parent and child have material modifiers
   - Flag if more than 2 material levels are stacked

### Scoring
- `.glassEffect()` on non-interactive: **High (+2)**
- Wrong material context: **Medium (+1)**
- Manual blur+overlay: **Medium (+1)**
- Material stacking > 2 levels: **High (+2)**

---

## Pass 2: Layout Audit

Check for layout anti-patterns and deprecated APIs.

### Checks

1. **`GeometryReader` inside `ScrollView` or `List`** (Critical)
   - Grep `GeometryReader` — read context for enclosing `ScrollView` or `List`
   - Flag with suggestion: use `onGeometryChange` instead

2. **`UIScreen.main.bounds`** (Critical)
   - Grep `UIScreen` — flag as deprecated/unavailable on macOS
   - Suggest: use `onGeometryChange` with window content size

3. **Hardcoded frame sizes without min/max** (Medium)
   - Grep `.frame(width:` and `.frame(height:` — check for absence of `min`/`max`/`ideal` variants
   - Skip if inside `.frame(minWidth:` or `.frame(maxWidth:`

4. **Large collections without lazy containers** (Medium)
   - Grep `ForEach` — check if enclosed in `VStack`/`HStack` rather than `LazyVStack`/`LazyHStack`/`List`
   - Flag if the ForEach appears to iterate a collection (not a small fixed array)

5. **Non-4pt-grid spacing** (Low)
   - Grep `.padding(` with literal numbers — flag values not on the 4pt grid (4, 8, 12, 16, 24, 32, 48)
   - Read context to check if value is intentional (e.g., specific component insets)

### Scoring
- GeometryReader in ScrollView: **Critical (+3)**
- UIScreen usage: **Critical (+3)**
- Hardcoded frames: **Medium (+1)**
- Non-lazy large collections: **Medium (+1)**
- Non-4pt-grid spacing: **Low (+0.5)**

---

## Pass 3: Navigation Audit

Check for deprecated navigation patterns and macOS anti-patterns.

### Checks

1. **`NavigationView`** (Critical)
   - Grep `NavigationView` — flag as deprecated
   - Suggest: `NavigationSplitView` (sidebar+detail) or `NavigationStack` (flat)

2. **`TabView` without `.sidebarAdaptable`** (High)
   - Grep `TabView` — check if `.tabViewStyle(.sidebarAdaptable)` is applied
   - On macOS, bare `TabView` creates iOS-style tabs instead of sidebar navigation

3. **`NavigationSplitView` without column width constraints** (Medium)
   - Grep `NavigationSplitView` — check for `.navigationSplitViewColumnWidth` modifiers
   - Flag if no column width constraints found

4. **Deprecated property wrappers** (High)
   - Grep `@StateObject`, `@ObservedObject`, `@EnvironmentObject`
   - Flag with suggestion: use `@State` with `@Observable`, `@Environment`

### Scoring
- NavigationView: **Critical (+3)**
- TabView without sidebarAdaptable: **High (+2)**
- Missing column widths: **Medium (+1)**
- Deprecated property wrappers: **High (+2)**

---

## Pass 4: Accessibility Audit

Check for missing accessibility support.

### Checks

1. **`Button` without `.accessibilityLabel`** (High)
   - Grep `Button` — check if followed by `.accessibilityLabel` within ~5 lines
   - Skip if Button has a visible text label (not icon-only)

2. **`Image(systemName:)` without accessibility** (High)
   - Grep `Image(systemName:` — check for `.accessibilityLabel` or `.accessibilityHidden(true)` (decorative)
   - Flag icon-only images that lack both

3. **Missing `.focusable()` on custom interactive views** (Medium)
   - Grep for `onTapGesture` or `onLongPressGesture` on non-Button views
   - Check if `.focusable()` is applied for keyboard navigation

4. **`.accessibilityHidden(true)` on interactive elements** (Critical)
   - Grep `.accessibilityHidden(true)` — read context to verify it's on a decorative element
   - Flag if applied to `Button`, `Toggle`, `TextField`, `Picker`, or other interactive controls

### Scoring
- Button without label: **High (+2)**
- System image without accessibility: **High (+2)**
- Missing focusable: **Medium (+1)**
- Hidden interactive element: **Critical (+3)**

---

## Pass 5: Visual Verification Audit (Requires Peekaboo MCP)

If Peekaboo MCP is available, perform visual verification:

1. Build and launch the app
2. Capture screenshot of the relevant screen
3. Check: Is typography contrast visible (not all same-size text)?
4. Check: Is there depth/layering (materials, shadows) or purely flat?
5. Check: Is accent color restrained (1-2 elements, not scattered)?
6. Check: Does the layout have a clear focal point?
7. Check: Does it use the app's visual signature from the creative brief?

### Scoring
- Each failed check: **Medium (+1)**
- 3+ failed checks: upgrade all to **High (+2 each)**

**Fallback:** If Peekaboo unavailable, skip this pass and note "Visual audit skipped — Peekaboo unavailable."

---

## Risk Scoring

| Severity | Points | Meaning |
|----------|--------|---------|
| Critical | +3 | Deprecated API, accessibility violation, broken pattern |
| High | +2 | Wrong API usage, missing accessibility, anti-pattern |
| Medium | +1 | Suboptimal pattern, minor issue |
| Low | +0.5 | Style preference, polish item |

**Verdict:**
- Score < 3: **PASS** (clean or minor issues only)
- Score 3-5: **PASS WITH NOTES** (issues noted but not blocking)
- Score ≥ 6: **FAIL** (recommend rejection)

---

## Output Format

### Finding Format

For each finding:
```
### [Category] [Severity]: [Title]
- **File:** [path]:[line]
- **Current:** `[code snippet]`
- **Suggested:** `[fix snippet]`
- **Why:** [explanation referencing design system or HIG]
```

### Summary Format

```
## UI Audit Results

**Files audited:** [count]
**Findings:** [critical] critical, [high] high, [medium] medium, [low] low
**Risk score:** [total] — [PASS | PASS WITH NOTES | FAIL]

### Findings by Category
- Liquid Glass: [count]
- Layout: [count]
- Navigation: [count]
- Accessibility: [count]
- Visual: [count or "skipped"]

### Details
[individual findings]
```

## Task Comment (When Story ID Provided)

```javascript
TaskUpdate({ id: "[story-id]",
  metadata: {
    comments: [...existing, {
      "id": "C[N]", "timestamp": "[ISO8601]",
      "author": "ui-audit-agent", "type": "review",
      "content": "UI AUDIT [PASS|PASS WITH NOTES|FAIL]\n\n**Score:** [N]\n**Files:** [count]\n**Findings:** [X] critical, [Y] high, [Z] medium, [W] low\n\n[Top findings summary]"
    }]
  }
})
```

## When to Activate

- `/ui-audit` command
- Called by staff-engineer-agent during code review for UI stories
- Can be run standalone on any View file path

## Never

- Modify source files (read-only analysis)
- Skip any of the 5 audit passes
- Report findings without file:line references
- Flag patterns without reading surrounding context
- Score below threshold and still recommend FAIL
