---
description: Screenshot-driven UI polish. Takes screenshot, compares to design system, identifies visual issues, generates fixes.
argument-hint: screen name or URL (e.g., "dashboard", "http://localhost:3000")
---

# /ui-polish

Screenshot-driven visual verification of a running macOS app. Captures current state, compares against design spec and design system, identifies visual issues, and generates fix code.

## Delegation

**Delegate to Designer agent** for visual analysis and issue identification.

**Delegate to macOS Developer agent** if auto-applying fixes to source files.

## Arguments

- `<screen-name>` - Name of the screen to audit (e.g., "dashboard", "settings", "task-detail")
- `<url>` - URL to screenshot directly (e.g., "http://localhost:3000")
- If omitted: prompt user for screen name or URL

## Flow

```
┌─────────────────────────────────────────────────────┐
│               1. TAKE SCREENSHOT                     │
│                                                      │
│  URL provided?  ──yes──>  mcp__screenshot tool       │
│       │                                              │
│       no                                             │
│       │                                              │
│       ▼                                              │
│  Guide user to navigate, or use URL if available     │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│            2. LOAD DESIGN REFERENCES                 │
│                                                      │
│  - Design spec: planning/design/[screen]-spec.md     │
│  - Design system: .claude/skills/design-system/      │
│  - Source files: app/[AppName]/Views/                 │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│              3. VISUAL AUDIT                         │
│                                                      │
│  Check spacing, typography, color, layout,           │
│  components, and macOS HIG compliance                │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│            4. GENERATE FIX CODE                      │
│                                                      │
│  For each issue: file, line, current code,           │
│  fixed code, explanation                             │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│       5. APPLY FIXES (optional, user confirms)       │
│                                                      │
│  Edit files -> Re-screenshot -> Verify               │
└─────────────────────────────────────────────────────┘
```

---

### 1. Take Screenshot

**Peekaboo (Preferred for native macOS apps):**
```bash
# Clean window capture (no annotations)
image --app [AppName] --mode window

# Element-annotated view (for accessibility audit)
see --app [AppName]

# Structured element data (for automated checks)
see --app [AppName] --json-output
```

**If argument is a URL** (starts with `http://` or `https://`):
```
Use mcp__screenshot-website-fast__take_screenshot tool directly with the URL.
Save screenshot for reference.
```

**If argument is a screen name:**
- If the app is running natively, use Peekaboo: `image --app [AppName] --mode window`
- If the app exposes a local URL, use `mcp__screenshot-website-fast__take_screenshot`
- If Peekaboo unavailable: fall back to `mcp__screenshot-website-fast__take_screenshot` or ask user for screenshot path

### 2. Load Design References

Load the following references in parallel:

1. **Design spec** (if exists):
   ```
   planning/design/[screen-name]-spec.md
   ```
   If not found, note it and proceed with design system only.

2. **Design system** (always load):
   ```
   .claude/skills/design-system/SKILL.md
   ```

3. **Relevant source files** (find and load):
   ```
   # Find view files matching the screen name
   Glob: app/[AppName]/**/*[ScreenName]*.swift

   # Also find related ViewModels
   Glob: app/[AppName]/**/*[ScreenName]*ViewModel*.swift
   ```

### 3. Visual Audit

Analyze the screenshot against the design system. Check ALL of the following categories:

#### Spacing Issues
- Is spacing consistent? (should follow 4pt grid: 4, 8, 12, 16, 24, 32, 48)
- Are padding values standard? (16pt content, 12pt compact, 24pt major sections)
- Is there proper breathing room between sections?
- Are elements cramped or too sparse?

#### Typography Issues
- Is there a clear text hierarchy? (title -> headline -> body -> caption)
- Are font sizes appropriate for their role?
- Is text readable (sufficient size, contrast)?
- Are labels consistent in style and casing?

#### Color Issues
- Are semantic colors used? (not hardcoded)
- Do status indicators use correct colors? (green=success, red=error, orange=warning)
- Is there sufficient contrast ratio?
- Does it look correct in both light and dark mode?

#### Layout Issues
- Are elements properly aligned?
- Do columns/sections have consistent widths?
- Is the information density appropriate?
- Does the sidebar have proper proportions?

#### Component Issues
- Do cards have consistent corner radius?
- Are interactive elements at least 44pt tall?
- Are empty/loading/error states well-designed?
- Do toolbars follow standard layout?

#### macOS HIG Issues
- Does it feel like a native macOS app?
- Are standard patterns used (NavigationSplitView, Table, Form)?
- Are toolbar items properly placed?
- Does it respect system appearance?
- Does it use Liquid Glass where appropriate (macOS 26+)?

#### Liquid Glass Compliance (macOS 26+)
- Is `.glassEffect()` used for interactive toolbar controls?
- Are materials not stacked more than 2 levels?
- Is the glass variant (Regular/Clear) appropriate?

#### SF Symbols
- Do SF Symbols have explicit rendering modes (not defaulting to monochrome)?
- Are animation effects used on state-change symbols?
- Do symbol sizes match surrounding text?

#### Creative Direction
- Does the screen use the app's visual signature from `frontend-design.md`?
- Is accent color used sparingly (ONE focal element)?
- Does it avoid AI slop anti-patterns from `swiftui-aesthetics.md`?

#### Typography Tiers
- Dashboard/stat numbers using Tier 2?
- Standard content using Tier 1?
- 2x+ size contrast between hierarchy levels?

#### Accessibility Audit (Peekaboo `see` Output)
If Peekaboo is available, use `see --app [AppName]` element annotations to:
- Verify all interactive elements have accessibility IDs
- Check labels are descriptive (not "Button" or "Image")
- Confirm tab order is logical (left-to-right, top-to-bottom)
- Compare `see` element annotations against UX Flows Section 8 (Accessibility Interactions) if a UX Flows doc exists
- Use `see --app [AppName] --json-output` for structured element data when checking coverage

### 4. Generate Fix Code

For each issue found, provide:

1. **Severity** - Critical (breaks visual consistency), Important (looks off), Polish (nice to have)
2. **File and line** - Exact file path and line number
3. **Current code** - The code as it exists now
4. **Fixed code** - The corrected code using design system values
5. **Explanation** - Why the fix improves visual quality

Example fix format:
```
### Issue 1: Inconsistent spacing in MainView.swift:42
Severity: Critical

Current:
    .padding(10)

Fix:
    .padding(.md)  // 16pt, standard content padding per design system

Why: The 10pt padding does not align with the 4pt grid system. Standard
content padding is 16pt (.md) which provides consistent visual rhythm
across the app.
```

### 5. Apply Fixes (Optional)

After presenting all issues:
1. Ask the user if they want fixes auto-applied
2. If yes, edit files with the generated fixes using the macOS Developer agent
3. Re-screenshot to verify improvements
4. Present before/after comparison

---

## Pre-Conditions

- App is running or a URL is available for screenshot
- Design system skill exists at `.claude/skills/design-system/`
- Source files exist in `app/[AppName]/Views/`

## When to Use

- After `/build` completes a UI task
- Before `/code-review` for visual quality assurance
- Anytime a screen "looks off"
- As part of `/build-story` pipeline (optional visual verification step)
- During iterative UI development cycles

## Output Format

```
UI Polish: [Screen Name]

Screenshot captured.
Design system loaded.
[Design spec loaded / No design spec found - using design system only]

Source files analyzed:
- app/[AppName]/[AppName]/Views/[ScreenName]View.swift
- app/[AppName]/[AppName]/ViewModels/[ScreenName]ViewModel.swift

---

## Issues Found

### Critical (breaks visual consistency)

1. **Inconsistent spacing** in MainView.swift:42
   - Current: `.padding(10)`
   - Fix: `.padding(.md)` (16pt, standard content padding)

2. **Wrong typography** in HeaderView.swift:18
   - Current: `.font(.body)` for section title
   - Fix: `.font(.title3)` (section headers use .title3)

### Important (looks off)

3. **Missing empty state** in ListView.swift
   - Current: blank area when list is empty
   - Fix: Add ContentUnavailableView pattern from design system

4. **Button too small** in ToolbarView.swift:55
   - Current: `.frame(height: 28)`
   - Fix: `.frame(minHeight: 44)` (minimum touch target)

### Polish (nice to have)

5. **Add material background** to sidebar header
   - Current: `.background(.clear)`
   - Fix: `.background(.ultraThinMaterial)`

---

## Summary

- 2 critical / 2 important / 1 polish issues
- Estimated fix time: quick (< 30 minutes)

Apply fixes? (y/n)
```

## Task Tool Reference

If working within a task context:
```
# Find relevant task
TaskGet [task-id]

# Add polish comment to task
TaskUpdate [task-id]
  metadata.schema_version: "2.0"
  metadata.last_updated_at: "[ISO 8601 timestamp]"
  metadata.comments: [...existing comments, {
    "id": "C[next-id]",
    "timestamp": "[ISO 8601 timestamp]",
    "author": "designer-agent",
    "type": "ui-polish",
    "content": "UI POLISH RESULTS\n\n**Screen:** [screen name]\n**Issues found:** [X] critical, [Y] important, [Z] polish\n**Issues fixed:** [N] of [total]\n**Screenshot verified:** [yes/no]\n\n**Details:**\n- [Issue 1]: [fixed/deferred]\n- [Issue 2]: [fixed/deferred]\n\n**Files changed:**\n- [file list]",
  }]
```

## Important Rules

1. **Design system is the source of truth** - All fix recommendations must reference design system values, not arbitrary numbers
2. **Do not invent design values** - If the design system does not specify a value, note it as a recommendation rather than a fix
3. **Preserve functionality** - Visual fixes must not alter behavior or break existing functionality
4. **Always explain why** - Every fix must include a rationale tied to the design system or HIG
5. **Severity matters** - Critical issues should be fixed before submission; polish items are optional
6. **Re-verify after fixes** - If fixes are applied, take a new screenshot to confirm visual improvement
