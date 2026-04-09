---
name: macos-design-system
description: Concrete SwiftUI design system with exact values for spacing, typography, color, and components. Reference during ALL UI implementation work.
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep]
---

# macOS Design System

This is the **single source of truth** for all visual design decisions in macOS SwiftUI applications built with this toolkit. Both the designer agent and the macOS developer agent reference these files when creating or reviewing UI.

**Do not improvise visual values.** If the answer is not here, add it here first, then use it.

---

## Cheat Sheet

Keep this section loaded during all UI work. For detailed rules, load the sub-files listed below.

### Spacing Scale (4pt Grid)

| Token | Value | Use For |
|-------|-------|---------|
| `xxs` | 4pt | Tight gaps: icon-to-badge, inner badge padding |
| `xs` | 8pt | Icon-to-label, between related inline elements |
| `sm` | 12pt | Compact padding (sidebar items, toolbar), between form fields |
| `md` | 16pt | Standard content padding, card inner padding, between cards |
| `lg` | 24pt | Between sections, major content area padding |
| `xl` | 32pt | Page-level margins, hero spacing |
| `xxl` | 48pt | Splash/empty state spacing, large visual gaps |

### Standard Padding by Context

| Context | Padding |
|---------|---------|
| Content area (detail pane) | 16pt (`md`) |
| Compact area (sidebar rows) | 12pt horizontal, 8pt vertical |
| Major sections (page root) | 24pt (`lg`) |
| Cards (inner) | 16pt (`md`) |
| Toolbar items | 12pt (`sm`) between items |
| Form sections | 24pt (`lg`) between sections, 8-12pt between fields |

### Corner Radius

| Token | Value | Use For |
|-------|-------|---------|
| `sm` | 6pt | Badges, tags, small pills |
| `md` | 8pt | Buttons, input fields, small cards |
| `lg` | 12pt | Cards, panels, popovers |
| `xl` | 16pt | Large cards, modal sheets |

### Typography Quick Reference

| Style | Use For |
|-------|---------|
| `.title` | Primary section headers |
| `.title2` | Secondary headers, panel titles |
| `.title3` | Card titles, group headers |
| `.headline` | List row primary text, emphasized info |
| `.subheadline` | List row secondary line, metadata |
| `.body` | Default content, descriptions, form values |
| `.callout` | Sidebar items, secondary content |
| `.footnote` | Timestamps, captions, tertiary info |
| `.caption` | Labels, badges, smallest readable text |

For dashboard/display contexts, see Tier 2 Signature Patterns in `typography-and-color.md`.

### Color Quick Reference

| Role | Value | Use For |
|------|-------|---------|
| Primary text | `.primary` | Main content |
| Secondary text | `.secondary` | Supporting info |
| Tertiary text | `.tertiary` | Disabled, placeholders |
| Interactive | `.accentColor` / `.tint` | Buttons, links, selections |
| Error | `.red` | Errors, destructive actions |
| Warning | `.orange` | Warnings, attention |
| Success | `.green` | Success states, active |
| Info | `.blue` | Informational, links |

---

## Sub-Files

Load these when you need detailed guidance for a specific area.

| File | Load When |
|------|-----------|
| `spacing-and-layout.md` | Building any view layout, choosing padding, creating page structure, sidebar/detail patterns |
| `typography-and-color.md` | Choosing fonts, text styling, colors, status indicators, dark mode |
| `components.md` | Building reusable UI components, stat cards, list rows, forms, empty states |
| `frontend-design.md` | Creative direction, aesthetic thinking, making UIs feel intentional and distinctive (not just correct) |
| `swiftui-aesthetics.md` | **Visual polish for native macOS.** Typography contrast, color strategy, materials/depth, animation moments, visual hierarchy. Load for ALL new UI work. |
| `references/hig-decisions.md` | Choosing navigation patterns, layout strategies, SF Symbol rendering modes, or answering "should I use X or Y?" |
| `references/app-components.md` | Building UI that reuses app-specific components. Check before creating new components. |

### When to Load Which File

- **Starting a new view?** Load `spacing-and-layout.md` for the layout template, then `components.md` for building blocks. **Also load `swiftui-aesthetics.md`** for visual polish guidance.
- **Styling text or choosing colors?** Load `typography-and-color.md`.
- **Building a reusable component?** Load `components.md` and cross-reference `spacing-and-layout.md` for spacing values.
- **UI feels generic or needs creative direction?** Load `frontend-design.md` for aesthetic thinking and intentional design principles.
- **Quick check on a single value?** Use the cheat sheet above -- no need to load sub-files.

---

## Principles (Brief)

1. **4pt grid, always.** Every spacing value is a multiple of 4.
2. **Semantic over literal.** Use `.primary`/`.secondary` not hardcoded colors. Use `.headline`/`.body` not font sizes.
3. **Density matches context.** Sidebars are compact. Content areas breathe. Forms have consistent rhythm.
4. **Platform-native first.** Use system components (List, Form, NavigationSplitView) before custom layouts.
5. **Copy-paste ready.** Every code example in this system works as-is. No pseudocode.

## Multi-Window Design (DES-4)

| Pattern | When to Use |
|---------|------------|
| Single `WindowGroup` | Most apps — one main window |
| `WindowGroup` + `Window` | Main window + auxiliary (inspector, log) |
| `WindowGroup` + `Settings` | Main window + Cmd+, preferences |
| Multiple `WindowGroup` | Document-based apps (one window per document) |

**Window lifecycle:** When the last window closes, macOS keeps the app running (dock icon visible). Use `NSApplication.shared.terminate(nil)` only if the app should quit on last window close.

**Auxiliary window coordination:** Use `@Environment(\.openWindow)` to open, pass data via the window's ID or `OpenWindowAction`.

## Dark / Light Mode (DES-5)

Beyond semantic colors:
- Use `@Environment(\.colorScheme)` to conditionally adjust values that don't adapt automatically
- Materials (`.ultraThinMaterial`, etc.) automatically adapt to color scheme
- Test both modes explicitly — some custom views may look broken in one mode
- Use `preferredColorScheme(.dark)` in previews to verify both appearances

```swift
// Preview both modes
#Preview("Light") { MyView().preferredColorScheme(.light) }
#Preview("Dark") { MyView().preferredColorScheme(.dark) }
```

## Design Review for Existing UI (DES-6)

When reviewing an already-built screen against the design system:

1. **Spacing audit:** Check every padding/spacing value against the 4pt grid tokens
2. **Typography audit:** Verify all text uses semantic font styles (no hardcoded sizes)
3. **Color audit:** Verify all colors are semantic (no hardcoded RGB/hex)
4. **State coverage:** Does the screen handle idle, loading, loaded, error, AND empty?
5. **Accessibility:** Labels on all interactive elements? Keyboard navigable?
6. **Responsive:** Does it work at minimum window size? Does it use available space at maximum?
