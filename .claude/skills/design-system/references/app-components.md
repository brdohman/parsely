# App Component Library

> **Load this file:** When building UI that reuses app-specific components. Check here before creating new components.

This file catalogs reusable components specific to **this app**. Each component uses design system tokens and creative brief values from `frontend-design.md`.

**When to populate:** During `/design` for the first screen of an epic. After creating a component, add it here so other screens reuse it instead of reinventing.

**Rule:** If you need a component and one exists here, use it. If you create a new reusable component, add it here before marking the task complete.

---

## Components Index

| Component | Screen(s) | Design System Pattern | Added By |
|-----------|-----------|----------------------|----------|
| *(empty — add components as they are created)* | | | |

---

## Component Template

Copy this template when adding a new component:

```markdown
## [Component Name]

**Use for:** [when this component appears — e.g., "displaying account balances in sidebar and dashboard"]
**Design tokens:** [which design system values it uses — e.g., "Tier 2 hero number, md padding, lg corner radius"]
**Creative brief alignment:** [how it reflects the app's personality — e.g., "light-weight large numbers match the 'precise' personality"]

### SwiftUI

\```swift
// Copy-paste ready code using design system tokens
// Reference creative brief values (accent color, typography signature)
\```

### Variants

| Variant | When | Difference |
|---------|------|-----------|
| Default | [context] | [description] |
| Compact | [context] | [description] |

### Usage Notes

- [Any important usage guidance]
- [Accessibility considerations]
```

---

## How Components Get Added

1. **During `/design`** — Designer creates a component spec, developer implements it, adds entry here
2. **During `/build`** — Developer creates a reusable component, adds entry here before task completion
3. **During `/ui-polish`** — If visual polish extracts a reusable pattern, add entry here
4. **During `/design-review`** — If review identifies a pattern that should be a shared component, add entry here

## Naming Convention

Name components by their **purpose**, not their implementation:
- `AccountBalanceCard` (what it shows)
- `TransactionRow` (what it represents)
- `StatusIndicator` (what it communicates)

Not:
- `GlassCard` (implementation detail)
- `LargeNumberView` (too generic)
- `CustomListRow` (meaningless)
