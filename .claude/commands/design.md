---
description: Create UI specification for a screen. Creates design task. Must be done BEFORE building any UI.
argument-hint: screen name (e.g., "dashboard", "donation-form")
---

# /design

Designer creates UI specification with task tracking.

## Delegation

**IMMEDIATELY delegate to Designer agent.**

## UX Flows Integration

Before creating screen specs, the Designer reads the UX Flows doc:

1. **Load UX Flows:** Check epic `ux_flows_ref` for the path (e.g., `planning/[app-name]/UX_FLOWS.md`). Read it as the primary design context.
2. **Fill UX Flows sections:** Designer fills relevant sections of UX Flows for the screen(s) being designed:
   - State machines (SM-*): all states, transitions, and guards for the screen
   - Interaction specs (IS-*): hover, click, drag, keyboard interactions
   - Modal flows: any dialogs, sheets, or popovers triggered from the screen
3. **Use Peekaboo for existing state:** If modifying an existing screen, use Peekaboo (`image`, `see`) to screenshot the current app state as a baseline.
4. **Reference UX Flows IDs:** Design specs reference UX Flows IDs (SM-*, IS-*, J*) so implementation tasks can trace back to the design.
5. **Scope:**
   - If epic-level design (Phase A of `/build-epic`): work on all screens in the epic
   - If task-level design (standalone `/design` call): work on the single specified screen

## Flow

1. Check if design task exists, create if not:
   ```
   TaskCreate {
     subject: "Design: [Screen Name]",
     description: "UI specification for [screen]. Create wireframe, component mapping, and state definitions.",
     activeForm: "Designing [Screen Name]",
     metadata: {
       schema_version: "2.0",
       type: "task",
       parent: "[story-id]",
       priority: "P2",
       approval: "approved",
       blocked: false,
       labels: [],
       local_checks: [
         "One-Question identification documented",
         "SwiftUI skeleton code with design system values created",
         "Component mapping (SwiftUI) completed",
         "State definitions (loading, error, empty) defined",
         "Spec saved to planning/design/[screen]-spec.md"
       ],
       checklist: [
         "Load design system skill",
         "Create wireframe with design system values",
         "Map to SwiftUI components",
         "Define all view states"
       ],
       completion_signal: "Design spec saved to planning/design/[screen]-spec.md",
       validation_hint: "Spec file exists and contains SwiftUI skeleton code"
     }
   }
   TaskUpdate { id: [task-id], status: "in_progress" }
   ```
2. Load design system skill (`.claude/skills/design-system/SKILL.md`)
   2a. Load creative brief (`.claude/skills/design-system/frontend-design.md`) for app personality and accent color
   2b. Load HIG decisions (`.claude/skills/design-system/references/hig-decisions.md`) for navigation/layout
   2c. If floating panels or toolbar → load Liquid Glass guide (`.claude/skills/macos-ui-review/liquid-glass-design.md`)
3. Designer agent creates:
   - One-Question identification
   - **SwiftUI skeleton code** with exact design system values (spacing, typography, colors)
   - Component mapping referencing `skills/design-system/components.md`
   - State definitions with real SwiftUI patterns (ContentUnavailableView, ProgressView, error states)
4. Save to `planning/design/[screen]-spec.md`
5. Complete design task:
   ```
   TaskUpdate {
     id: [task-id],
     status: "completed",
     metadata: { summary: "Design spec at planning/design/[screen]-spec.md" }
   }
   ```

## Output Format

```
Design complete

Task: [task-id] Design: Dashboard Spec
Status: Completed
Spec: planning/design/dashboard-spec.md

Design Principles Applied:
- One-Question: "What donations need attention today?"
- Semantic colors for status indicators
- Primary action: "Record Donation" prominent
- Honest emotion: Red for overdue items

Next: Run `/build` to implement.
```

## Pre-Conditions

- Feature epic exists
- Phase structure exists (run `/plan` first if not)
- Design system loaded (`.claude/skills/design-system/SKILL.md`)

## Task Commands

```
TaskCreate {
  subject: "Design: [Screen Name]",
  description: "UI specification for [screen]. Create wireframe, component mapping, and state definitions.",
  activeForm: "Designing [Screen Name]",
  metadata: {
    schema_version: "2.0",
    type: "task",
    parent: "[story-id]",
    priority: "P2",
    approval: "approved",
    blocked: false,
    labels: [],
    local_checks: [
      "One-Question identification documented",
      "SwiftUI skeleton code created",
      "Component mapping completed",
      "State definitions defined",
      "Spec saved to planning/design/[screen]-spec.md"
    ],
    checklist: ["Load design system", "Create wireframe", "Map components", "Define states"],
    completion_signal: "Spec saved to planning/design/[screen]-spec.md",
    validation_hint: "Spec file exists with SwiftUI skeleton"
  }
}
TaskUpdate { id: [task-id], status: "in_progress" }
TaskUpdate {
  id: [task-id],
  status: "completed",
  metadata: {
    comments: [{
      "id": "C1",
      "timestamp": "[ISO timestamp]",
      "author": "designer-agent",
      "type": "implementation",
      "content": "Design spec completed at planning/design/[screen]-spec.md"
    }]
  }
}
```
