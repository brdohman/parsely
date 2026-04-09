---
description: Review implemented UI against Intentional Design principles.
argument-hint: component or page path (optional), or [story-id] for specific story review
---

# /design-review

Audit existing UI for design system compliance and visual quality. Checks both HIG correctness and aesthetic polish (see `design-system/references/swiftui-aesthetics.md` for the AI slop anti-patterns checklist).

## Delegation

**IMMEDIATELY delegate to Designer agent.**

## Arguments

- `path` - Component or page path to review
- `[story-id]` (optional) - Specific story awaiting design review

## Flow

### Story-based Review (with story-id)

If reviewing a specific story:

> **Note:** Design review is a supplementary check that runs alongside the standard review pipeline. It does not use labels for workflow state — all state is tracked via comments.

1. **Get story details**
   ```
   TaskGet [story-id]
   ```

2. **Perform design review against Intentional Design principles**

3. **On PASS:**
   ```
   TaskUpdate [story-id]
     metadata.comments: [...existing comments, {
       "id": "C[next-id]",
       "timestamp": "[ISO-8601 timestamp]",
       "author": "designer-agent",
       "type": "review",
       "content": "DESIGN REVIEW PASSED\n\nPrinciples verified:\n- [x] One-Question Rule\n- [x] Semantic Everything\n- [x] Earned Decoration\n- [x] Action Gravity\n- [x] Honest Emotion"
     }]
   ```

4. **On FAIL:**
   ```
   TaskUpdate [story-id]
     metadata.comments: [...existing comments, {
       "id": "C[next-id]",
       "timestamp": "[ISO-8601 timestamp]",
       "author": "designer-agent",
       "type": "rejection",
       "content": "REJECTED - DESIGN REVIEW\n\nIssues found:\n1. [Principle]: [Issue description]\n2. [Principle]: [Issue description]\n\nNext action: Dev to fix design issues.",
       "resolved": false,
       "resolved_by": null,
       "resolved_at": null
     }]
   ```

### Path-based Review (general audit)

1. Load design system (`.claude/skills/design-system/SKILL.md`) and relevant sub-files (`spacing-and-layout.md`, `typography-and-color.md`, `components.md`)
2. Identify components to review:
   - If path provided: review that component/page
   - If no path: review recently changed UI files
3. **Capture visual evidence (when Xcode MCP available):**
   ```
   # Render SwiftUI preview for visual comparison
   mcp__xcode__RenderPreview(tabIdentifier: "...", file: "app/AppName/AppName/Views/SomeView.swift")
   ```
   Compare rendered output against design spec. Include screenshot evidence in review comments.
4. Check against Intentional Design principles:
   - One-Question Rule
   - Semantic Everything
   - Earned Decoration
   - Action Gravity
   - Honest Emotion
4. If issues found, create tasks:
   ```
   TaskCreate
     subject: "Design Fix: [issue]"
     description: "[detailed description]"
     metadata: {
       type: "task",
       labels: ["design"]
     }
   ```
5. Report findings

## Review Checklist

### One-Question Rule
- [ ] Screen has ONE primary question it answers
- [ ] Question is immediately clear
- [ ] Secondary info doesn't compete

### Semantic Everything
- [ ] Colors convey meaning (not decoration)
- [ ] Size indicates importance
- [ ] Position shows priority

### Earned Decoration
- [ ] Every element justifies its existence
- [ ] No decorative-only icons
- [ ] No gratuitous borders/shadows

### Action Gravity
- [ ] Primary action is visually obvious
- [ ] Secondary actions are subtle
- [ ] Destructive actions require confirmation

### Honest Emotion
- [ ] Success states feel celebratory
- [ ] Warning states feel concerned
- [ ] Error states feel serious

### Liquid Glass Correctness
- [ ] `.glassEffect()` only on interactive elements
- [ ] Material layering ≤ 2 levels
- [ ] Correct variant (Regular vs Clear)

### HIG Navigation
- [ ] Navigation pattern matches decision tree
- [ ] No anti-patterns (e.g., TabView for related content on macOS)

### SF Symbols Intent
- [ ] Rendering mode explicitly chosen
- [ ] Animation effects match trigger events
- [ ] Sizes contextually appropriate

### Typography Tier Compliance
- [ ] Display elements use Tier 2 where appropriate
- [ ] Standard content uses Tier 1
- [ ] 2x+ size contrast verified

## Output Format

### Pass
```
Design Review: PASSED

Scope: src/components/dashboard/**

All 5 principles verified:
- One-Question: "What needs attention?"
- Semantic colors for status
- All elements earn their place
- Primary action prominent
- Tone matches data reality
```

### Issues Found
```
Design Review: ISSUES FOUND

Scope: src/components/dashboard/**

Issues:
- [task-design-1] Decorative icon in header (Earned Decoration)
- [task-design-2] Secondary button too prominent (Action Gravity)

Tasks created to fix issues.
```

## Task Tool Reference

```
# Get story details for design review
TaskGet [story-id]

# PASS - add design review passed comment
TaskUpdate [story-id]
  - Add review comment to metadata.comments

# FAIL - add rejection comment with resolution tracking
TaskUpdate [story-id]
  - Add rejection comment to metadata.comments

# Create design fix task (for path-based audits)
TaskCreate
  subject: "Task: Design Fix - [issue]"
  description: "[details]"
  metadata: { schema_version: "2.0", type: "task", approval: "pending", blocked: false }
```
