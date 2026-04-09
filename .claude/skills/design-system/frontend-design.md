# Creative Brief & Design Direction

> **Load this file:** Always — it is foundational for every design decision.

## App Creative Brief

> Fill this in during `/discover` Phase 2 (design questions), `/epic` (planning agent passes to designer), or `/design` (if still empty).

**App Name:** [App Name]
**Purpose:** [one sentence — what job does this app do?]
**Personality:** [one adjective — calm, energetic, precise, warm, playful, etc.]
**Visual Signature:** [one distinctive pattern — e.g., "large light-weight numbers with tracked uppercase labels"]
**Accent Color:** Color("AppAccent") — [hex + description, e.g., "#2DD4BF warm teal"]
**Accent Rule:** [where accent appears — e.g., "positive change indicators and primary action buttons only"]
**Typography Signature:** [which Tier 2 patterns this app uses — reference `typography-and-color.md`]

---

## Design Decision Trees

Use these when making visual choices. Each tree produces a single answer.

### Which Background?

| Context | Background |
|---------|-----------|
| Sidebar | `.listStyle(.sidebar)` (system-managed) |
| Floating panel | `.glassEffect()` |
| Content card | `.ultraThinMaterial` or `.regularMaterial` |
| Main content area | Inherit from parent (no explicit background) |
| Overlay / sheet | `.thickMaterial` |
| Media app (always dark) | `.preferredColorScheme(.dark)` |

### Which Color for This Element?

| Element Role | Color Choice |
|-------------|-------------|
| Error / warning / success | Semantic status colors (`.red`, `.orange`, `.green`) |
| Primary focal element | `Color("AppAccent")` from creative brief |
| Primary text | `.primary` |
| Secondary text | `.secondary` |
| Tertiary / disabled text | `.tertiary` |
| Interactive controls | System `.tint` |
| Decorative / ambient | `.quaternary` or subtle opacity of accent |

**Rule:** Accent color on ONE focal element per screen. If everything is accented, nothing stands out.

### Which Font Weight?

| Context | Weight |
|---------|--------|
| Large display text (>24pt) | `.light` or `.ultraLight` |
| Small label text (<12pt) | `.medium` or `.semibold` |
| Body text | `.regular` |
| Primary row item / emphasis | `.medium` |
| Section header | `.semibold` |

See the Two-Tier Typography Model in `typography-and-color.md` for when to use semantic vs explicit sizing.

### Which Depth Treatment?

| Context | Treatment |
|---------|----------|
| Card on content area | Subtle shadow (`.shadow(radius: 2, y: 1)`) |
| Floating panel | Medium shadow (`.shadow(radius: 8)`) + material |
| Toolbar control | `.glassEffect()` |
| Sidebar | System-managed (no manual depth) |
| Modal sheet | `.thickMaterial` + system shadow |

**Rule:** If the screen looks flat (no shadows, no materials, no gradient), something is missing. Every non-trivial screen should have at least one depth layer.

---

## AI Slop Prevention

These patterns signal generic, low-effort AI output. Avoid them.

### Red Flags
- Every element uses `.body` font — no typography hierarchy
- Accent color on 3+ elements — focal point lost
- No shadows or materials anywhere — flat, unfinished look
- Default system blue on everything — no personality
- Uniform padding throughout — mechanical, not designed
- Generic SF Symbol choices (e.g., `gear` for every settings-like action)

### What Good Looks Like
- 2x+ size contrast between hierarchy levels (e.g., 34pt hero number vs 13pt label)
- ONE accent-colored focal element per screen
- At least one material or shadow creating depth
- Typography weight varies by role (light for large display, medium for labels)
- SF Symbols with intentional rendering modes and animations
- Spacing that creates visual grouping, not uniform grids

---

## Design Review Pressure Guidance

When defending design choices, reference the creative brief.

### "Just use the default"
The default produces generic output indistinguishable from every other app. The creative brief defines this app's personality as [Personality]. The visual signature — [Visual Signature] — is what makes this app feel intentional. Defaults are a starting point, not a destination.

### "Why not system blue?"
System blue is correct for controls that should feel native (toggles, links, standard buttons). The accent color `[Accent Color]` is reserved for the app's focal elements per the accent rule: [Accent Rule]. Using system blue everywhere removes the app's identity.

### "This is overdesigned"
Every visual choice maps to a design system decision tree. The shadow is there because the card is floating above content (depth tree). The weight is `.light` because the number is >24pt (weight tree). The accent is on one element because that is the focal point (color tree). Nothing is decorative — everything is functional.

---

## When This File Gets Filled In

1. **During `/discover` Phase 2** — PM asks user for personality, accent color, visual signature
2. **During `/epic`** — Planning agent passes design answers to designer agent who populates this file
3. **During `/design`** — Designer checks this file; if still empty, prompts for the brief before proceeding
4. **Manual** — User can edit this file directly at any time

If the brief is empty when a designer agent starts work, the agent should ask:
- "What's the app's personality in one word?"
- "What accent color should we use?"
- "What's the visual signature?"
