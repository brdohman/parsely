# Liquid Glass Design Guide — macOS 26 (Tahoe)

> **Load when:** Implementing floating panels, toolbar controls, glass effects, or reviewing material usage.

## Overview

Liquid Glass is the material design system introduced in macOS 26 (Tahoe). Standard SwiftUI controls adopt it automatically when recompiled with Xcode 26. Custom views require explicit API usage.

**Primary API:** `.glassEffect()` — for interactive elements and custom glass surfaces.
**Materials:** `.ultraThinMaterial` through `.ultraThickMaterial` — for backgrounds and containers.
**Button styles:** `.buttonStyle(.glass)` and `.buttonStyle(.glassProminent)` — system-provided glass buttons.

---

## `.glassEffect()` API

```swift
func glassEffect(
    _ glass: Glass = .regular,
    in shape: some Shape = DefaultGlassEffectShape()  // Capsule
) -> some View
```

### Basic Usage

```swift
// Default — regular glass, capsule shape
Button("Action") { }
    .glassEffect()

// Custom shape
VStack { content }
    .glassEffect(in: .rect(cornerRadius: 16))

// Tinted + interactive
Button("Primary") { }
    .glassEffect(.regular.tint(.orange).interactive())
```

### Glass Variants

| Variant | Usage | When |
|---------|-------|------|
| `.regular` | Default, 95% of cases | Full adaptive behavior, automatic legibility |
| `.clear` | Special case only | ALL THREE conditions met (see below) |

**Clear variant conditions (all must be true):**
1. Media-rich background behind the glass (photo, video, gradient)
2. A dimming layer is acceptable between background and glass
3. Bold/bright content is positioned above the glass

```swift
// Clear — correct usage
ZStack {
    VideoPlayer(player: player)
        .overlay(.black.opacity(0.4))   // dimming required
    PlayButton()
        .glassEffect(.clear)
}
```

### Glass Modifiers

| Modifier | Purpose |
|----------|---------|
| `.tint(_ color:)` | Tint the glass with a color. Primary actions only. |
| `.interactive(_ bool:)` | Marks the glass as an interactive control. |

**Rule:** Apply `.glassEffect()` AFTER other appearance modifiers.

---

## `GlassEffectContainer`

Groups multiple `.glassEffect()` views into a single shape capable of morphing and blending.

```swift
GlassEffectContainer(spacing: 8) {
    ForEach(items) { item in
        ItemView(item)
            .glassEffect()
    }
}
```

### Container Features

| Feature | API | Purpose |
|---------|-----|---------|
| Identity for morphing | `.glassEffectID(id, in: namespace)` | Animated transitions between views |
| Transition type | `.glassEffectTransition(.matchedGeometry)` | `.matchedGeometry` or `.materialize` |
| Union shapes | `.glassEffectUnion(id:namespace:)` | Merge multiple views into one glass shape |

**Performance:** Use `GlassEffectContainer` when you have 3+ glass effects in proximity. It reduces GPU compositing overhead.

---

## Button Styles

```swift
Button("Standard Glass") { }
    .buttonStyle(.glass)

Button("Prominent Glass") { }
    .buttonStyle(.glassProminent)
```

| Style | Use For |
|-------|---------|
| `.glass` | Standard toolbar and secondary actions |
| `.glassProminent` | Primary actions that need emphasis |

---

## Material Layering System

Materials provide translucent backgrounds. Use them for containers and surfaces, NOT for interactive controls (use `.glassEffect()` for those).

### Layer Hierarchy

| Level | Context | Material | Notes |
|-------|---------|----------|-------|
| 0 | Window background | System-managed | Do not override |
| 1 | Sidebar, toolbar | `.bar` or system-provided | System manages automatically |
| 2 | Content cards, panels | `.ultraThinMaterial` or `.regularMaterial` | Most common custom usage |
| 3 | Floating elements, popovers | `.thickMaterial` or `.glassEffect()` + shadow | Highest visual elevation |

### Available Materials

| Material | Translucency | Use For |
|----------|-------------|---------|
| `.ultraThinMaterial` | Mostly translucent | Overlays on rich backgrounds |
| `.thinMaterial` | More translucent than opaque | Light overlays |
| `.regularMaterial` | Balanced | Content cards, panels |
| `.thickMaterial` | More opaque | Sheets, popovers |
| `.ultraThickMaterial` | Mostly opaque | High-contrast backgrounds |
| `.bar` | Matches system toolbar | Toolbar backgrounds |

### Stacking Rule

**Never stack more than 2 material levels.** If you have a material card on a material sidebar on a material window, the blur compounds and becomes illegible.

### macOS Window State

Materials respond to window active/inactive state via `MaterialActiveAppearance`:

| Setting | Behavior |
|---------|----------|
| `.automatic` | Default — follows system rules |
| `.active` | Always appears active (use sparingly) |
| `.inactive` | Always appears inactive |
| `.matchWindow` | Matches the window's active state |

**Note:** `.bar` and window container backgrounds appear inactive when the window loses focus. Other materials appear always active by default. Override with `.materialActiveAppearance(.active)` if needed.

---

## Tinting Rules

| Context | Tinting Approach |
|---------|-----------------|
| Primary action button | `.glassEffect(.regular.tint(.appAccent))` |
| Status indicator on glass | Subtle tint at 10-15% opacity |
| Decorative glass | No tint — let the material speak |
| Error/warning state | Semantic color tint (`.red`, `.orange`) at low opacity |

**Rules:**
- Tint primary actions only — not every glass element
- Never use solid fills on glass — it defeats the translucency
- One tinted glass element per visual group maximum

---

## Scroll Edge Effects

```swift
ScrollView {
    content
}
.scrollEdgeEffectStyle(.soft, for: .top)
```

| Style | Effect |
|-------|--------|
| `.automatic` | System default |
| `.soft` | Gentle fade at scroll edge |
| `.hard` | Sharp edge transition |

Hide with: `.scrollEdgeEffectHidden(true, for: .top)`

**macOS note:** Toolbars on macOS are static — they do not scroll-hide. This modifier applies to `ScrollView` content edges, not toolbar glass transitions.

---

## Migration Guide

### From Legacy Materials to Glass Effects

| Old Pattern | New Pattern |
|------------|-------------|
| `.background(.ultraThinMaterial)` + `.overlay(stroke)` + `.shadow()` | `.glassEffect(in: .rect(cornerRadius: 12))` |
| Manual glassmorphism (blur + overlay + stroke) | `.glassEffect()` |
| `.cornerRadius()` + material background | `.glassEffect(in: .rect(cornerRadius: N))` |
| Custom toolbar blur | `.buttonStyle(.glass)` or `.glassEffect()` |

### From AppKit (NSVisualEffectView)

| AppKit | SwiftUI (macOS 26+) |
|--------|---------------------|
| `NSVisualEffectView` with `.behindWindow` | `.background(.ultraThinMaterial)` |
| `NSVisualEffectView` with `.withinWindow` | `.background(.regularMaterial)` |
| `NSGlassEffectContainerView` | `GlassEffectContainer` |
| Custom `NSVisualEffectView` subclass | `.glassEffect(in: customShape)` |

---

## Performance

- `.glassEffect()` is GPU-accelerated — lightweight for static elements
- Avoid `.glassEffect()` on items inside `ScrollView` or `List` rows — use materials for scrollable content backgrounds instead
- Use `GlassEffectContainer` when 3+ glass effects are grouped — reduces compositing passes
- Use `LazyVStack`/`LazyVGrid` to limit concurrent material instances in collections
- Test on both Retina (2x) and non-Retina displays
- Use `onInteractiveResizeChange` to pause glass animations during window resize if needed

---

## Expert Review Checklist

### Material Appropriateness
- [ ] Interactive controls use `.glassEffect()`, not raw materials
- [ ] Containers and backgrounds use materials, not `.glassEffect()`
- [ ] `.bar` material used for custom toolbar-like surfaces

### Variant Selection
- [ ] `.regular` used by default
- [ ] `.clear` only where all 3 conditions are met (media background, dimming, bold content)

### Legibility
- [ ] Text on glass has sufficient contrast in both light and dark mode
- [ ] No small/thin text directly on translucent surfaces
- [ ] Labels use `.primary`/`.secondary` semantic colors on glass

### Layering
- [ ] No more than 2 material levels stacked
- [ ] Each layer serves a distinct purpose (not decorative stacking)

### Scroll Edge
- [ ] `scrollEdgeEffectStyle` set appropriately for scroll containers
- [ ] No glass effects on scrollable list items

### Accessibility
- [ ] `Reduce Transparency` respected — glass degrades gracefully to solid
- [ ] `Increase Contrast` does not make glass elements invisible
- [ ] All glass interactive elements have `.accessibilityLabel`

### Performance
- [ ] No `.glassEffect()` in `List`/`ForEach` rows
- [ ] `GlassEffectContainer` used for grouped glass elements
- [ ] Tested on 60Hz displays (MacBook Air) and ProMotion (MacBook Pro)
