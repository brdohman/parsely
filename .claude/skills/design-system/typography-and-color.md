# Typography and Color

## Typography Hierarchy

| Style | Size | Weight | Use For |
|-------|------|--------|---------|
| `.title` | 22pt | Regular | Primary section headers |
| `.title2` | 17pt | Regular | Secondary headers, panel/dialog titles, empty state titles |
| `.title3` | 15pt | Regular | Card titles, group headers — add `.fontWeight(.semibold)` |
| `.headline` | 13pt | **Bold** | List row primary text (already bold, don't add `.bold()`) |
| `.subheadline` | 11pt | Regular | List row secondary line, supporting metadata |
| `.body` | 13pt | Regular | Default content, descriptions, form values, error messages |
| `.callout` | 12pt | Regular | Sidebar items, secondary content |
| `.footnote` | 10pt | Regular | Timestamps, captions, tertiary info |
| `.caption` | 10pt | Regular | Labels, badges, tag text — add `.fontWeight(.medium)` |

Sizes are macOS defaults. Typography follows a **Two-Tier Model**:

### Tier 1 — Structure (Semantic Styles)
Use for standard text — forms, settings, standard lists. These are the default choice.
- `.title`, `.headline`, `.body`, `.caption`, etc.
- Scale with Dynamic Type automatically (note: on macOS, Dynamic Type scale is fixed — users cannot adjust it unlike iOS)
- **Rule:** If the text serves a structural role (label, body copy, caption), use Tier 1.

### Tier 2 — Signature (Explicit Size/Weight)
Use for intentional visual signatures where semantic styles produce insufficient contrast.
- `.font(.system(size:weight:))` for dashboard numbers, hero balances, section labels with uppercase tracking, stat card values
- Pair with `.monospacedDigit()` for numbers that align vertically
- `@ScaledMetric` is available on macOS but the scale factor is fixed — it will not dynamically respond to user text size changes

**Signature Patterns:**

| Pattern | Size | Weight | Tracking | Use For |
|---------|------|--------|----------|---------|
| Hero number | 34pt | `.light` | default | Dashboard stats, balances |
| Section label | 11pt | `.medium` | 1.2-1.5 | Uppercase section headers |
| Compact stat | 20pt | `.regular` | default | Card stat values |
| Emphasis label | 13pt | `.semibold` | 0.5 | Important secondary info |

**Decision Tree:** Is this a display/dashboard context? Does the element need 2x+ size contrast from surrounding text? Is it a number that aligns vertically? → If yes to any, use Tier 2. Otherwise, use Tier 1.

## Color Roles

### Text
| Style | Use For |
|-------|---------|
| `.primary` | Main content (default) |
| `.secondary` | Supporting info, subtitles, labels |
| `.tertiary` | Disabled, placeholders |

### Status
| Color | Meaning |
|-------|---------|
| `.red` | Error, destructive, critical |
| `.orange` | Warning, attention needed |
| `.green` | Success, active, complete |
| `.blue` | Informational, links |

### Backgrounds
| Context | Value |
|---------|-------|
| Standard surface | `.background` |
| Cards | `.background` or `.ultraThinMaterial` |
| Floating panels | `.regularMaterial` |
| Overlays | `.ultraThinMaterial` |
| Hover state | `.secondary.opacity(0.1)` |

### Rules
- Use semantic colors only — never hardcode RGB/hex values
- Interactive elements use `.tint` / `.accentColor` automatically
- Dark mode works for free when you use semantic colors
- Borders/separators: always `.separator`
