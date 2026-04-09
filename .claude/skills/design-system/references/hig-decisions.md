# HIG Decision Trees — macOS

> **Load when:** Choosing navigation patterns, layout strategies, SF Symbol rendering modes, or answering "should I use X or Y?"

## Navigation Pattern Decision Tree

Choose based on your app's information structure:

| Structure | Pattern | Notes |
|-----------|---------|-------|
| Categories with detail views | `NavigationSplitView` (2 or 3 column) | Primary macOS pattern. Use `.balanced` or `.prominentDetail` style. |
| Peer sections of equal importance | `TabView` with `.sidebarAdaptable` | macOS always renders as sidebar. Supports `tabViewCustomization` for drag-to-reorder. |
| Flat list with detail | `NavigationSplitView` (2 column) | Sidebar + detail. Set column widths with `.navigationSplitViewColumnWidth()`. |
| Document-based app | `DocumentGroup` | System-managed open/save/recent. |
| Settings / preferences | `Settings` scene + `Form` | Standard macOS preferences window. |
| Drill-down within a section | `NavigationStack` | Use within a NavigationSplitView column, not as the root. |

### Anti-Patterns (macOS)
- `NavigationView` — **Deprecated.** Use `NavigationSplitView` or `NavigationStack`.
- `TabView` with bottom tab bar style — Does not exist on macOS. Use `.sidebarAdaptable`.
- `NavigationSplitView` without column width constraints — Columns resize unpredictably.
- Using size classes for layout branching — macOS is always `.regular` for both axes. Use `onGeometryChange` with explicit point thresholds instead.

---

## Layout Decision Tree

| Need | Tool | When |
|------|------|------|
| Show different layout based on available space | `ViewThatFits` | Best for "show A if it fits, otherwise show B" |
| Animate between horizontal and vertical layout | `AnyLayout` | Smooth transitions when window resizes |
| Read container dimensions for decisions | `onGeometryChange(for:of:action:)` | Preferred over `GeometryReader` — only fires when value changes |
| Respond to user dragging window edge | `onInteractiveResizeChange(_:)` | macOS-specific. Fires on drag start/stop. Use to pause animations or adjust renderers. |
| Custom layout algorithm | `Layout` protocol | For grids, flow layouts, or custom positioning |
| Scroll-aware layout changes | `onScrollGeometryChange(for:of:action:)` | Responds to scroll position/content size changes |

### Layout Red Flags
- `GeometryReader` inside `ScrollView` or `List` — causes layout thrashing
- `UIScreen.main.bounds` — does not exist on macOS. Use `NSScreen.main?.visibleFrame` or better, use `onGeometryChange` on the container
- `UIDevice.current` — does not exist on macOS
- Hardcoded frame sizes without `minWidth`/`maxWidth` — breaks on window resize
- Missing `LazyVStack`/`LazyVGrid` for collections with 20+ items
- Using `horizontalSizeClass` or `verticalSizeClass` — always `.regular` on macOS, never changes

### macOS Layout Principles
- Every window is freely resizable. Design for a range, not a fixed size.
- Use `minWidth`/`minHeight` on `WindowGroup` to set minimum window dimensions.
- Sidebar collapse is the primary responsive behavior (not size class changes).
- Test at 1280x800 (MacBook Air) through 5120x2880 (Studio Display).

---

## Common Design Questions

### Sheet vs Popover
- **Sheet:** Modal interaction that blocks the parent window. Use for forms, wizards, confirmations requiring focused input. Opens as a centered floating window on macOS.
- **Popover:** Non-modal, anchored to a control. Use for quick options, inspectors, or supplementary info. Dismisses on click-outside.
- **Rule:** If the user needs to complete a task before continuing, use a sheet. If they're glancing at options, use a popover.

### Sidebar Item vs Toolbar Button
- **Sidebar item:** Navigation destination — clicking changes the main content area.
- **Toolbar button:** Action — clicking does something (save, share, filter, add).
- **Rule:** Navigation goes in the sidebar. Actions go in the toolbar.

### Confirmation Dialog vs Alert
- **Alert (`.alert()`):** System-level interruption. Use sparingly — for destructive actions or errors only.
- **Confirmation Dialog (`.confirmationDialog()`):** Presents choices anchored to context. Use for "which option?" decisions.
- **Rule:** If there is only one action to confirm/cancel (especially destructive), use alert. If presenting multiple choices, use confirmation dialog.

---

## SF Symbols Guidance — macOS

### Rendering Mode Decision Tree

| Need | Mode | Example |
|------|------|---------|
| Simple, single-color icon | `.monochrome` | Toolbar icons, list item icons |
| Icon with depth/layering | `.hierarchical` | Status indicators, multi-part icons |
| Icon with 2-3 specific colors | `.palette` + `foregroundStyle` | Custom-branded icons |
| Apple-defined full-color icon | `.multicolor` | Weather, file type icons |

**Rule:** Always explicitly set a rendering mode. The default (monochrome) is often not the best choice — `.hierarchical` adds subtle depth with zero effort.

### Animation Effects

| Effect | Trigger | Use For |
|--------|---------|---------|
| `.bounce` | Click / selection | One-shot feedback on button press |
| `.pulse` | Ongoing state | Active download, recording, syncing |
| `.breathe` | Ambient state | Idle animation, "ready" indicator |
| `.wiggle` | Attention needed | Badge, notification, error state (macOS 15+) |
| `.rotate` | Processing | Loading, refreshing |
| `.variableColor` | Progress | Upload/download progress, signal strength |
| `.replace` | Content transition | Toggle states (play/pause, lock/unlock) |
| `.drawOn` / `.drawOff` | Entrance / exit | Hand-drawn appearance (macOS 26+ / SF Symbols 7) |

**Rule:** Always specify the trigger event when choosing an animation. "What user action or state change causes this animation to play?"

### Size Matching — macOS Density

macOS uses smaller UI elements than iOS (macOS body is 13pt, iOS body is 17pt).

| Context | Symbol Size | Notes |
|---------|------------|-------|
| Toolbar icons | 16–20pt | Match toolbar control height |
| Sidebar icons | 16pt | Consistent with system sidebar |
| Stat cards / inline with text | Match surrounding text size | e.g., 13pt next to body text |
| Large decorative | 24–48pt | Hero areas, empty states |

### Availability on macOS

| Feature | Minimum macOS Version |
|---------|----------------------|
| Basic symbol effects (bounce, pulse, scale) | macOS 14 |
| Wiggle, Breathe, Rotate | macOS 15 |
| Draw On/Off (SF Symbols 7) | macOS 26 |
| Symbol rendering modes | macOS 11 |
| `contentTransition(.symbolEffect(.replace))` | macOS 14 |

---

## macOS Control Sizing

macOS uses cursor and keyboard input, not touch. There is no 44pt minimum touch target.

| Control Size | Height | Use For |
|-------------|--------|---------|
| `.regular` | ~22pt | Default for most controls |
| `.small` | ~16pt | Dense layouts, secondary controls |
| `.large` | ~28pt | Prominent actions, onboarding |
| `.mini` | ~12pt | Compact toolbars, status bars |

Set with `.controlSize(.small)` or `.controlSize(.large)`.

**Keyboard accessibility is the macOS equivalent of touch targets:**
- All interactive elements must be reachable via Tab key (`.focusable()`)
- Buttons must respond to Return/Enter
- Custom controls need `.accessibilityAddTraits(.isButton)` and keyboard handlers
