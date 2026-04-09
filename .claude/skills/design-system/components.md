# Components — Design Values Reference

Reusable SwiftUI component patterns. Spacing, typography, and color values from the design system.
For full implementation code, agents should build components using these values + the SKILL.md cheat sheet.

---

## StatCard
- Padding: 16pt (md) all sides
- Corner radius: 12pt (lg)
- Background: `.ultraThinMaterial`
- Value font: `.title` semibold | Label font: `.caption` secondary | Icon font: `.title3` tinted

## SectionHeader
- Top padding: 24pt (lg) | Bottom padding: 8pt (xs)
- Title font: `.title3` semibold | Action button: `.borderless`, `.body` font

## ListRow
- Icon-text spacing: 12pt (sm) | Icon frame: 24x24pt
- Title: `.headline` | Subtitle: `.subheadline` secondary | Trailing: `.footnote` tertiary
- Vertical padding: 4pt (xxs)

## DetailHeader
- Icon: 36pt font in 48x48pt frame | Icon-text spacing: 16pt (md)
- Title: `.title2` semibold | Subtitle: `.subheadline` secondary
- Bottom padding: 16pt (md) | Action buttons: `.bordered` style

## FormGroup
- Label: `.body` secondary | Label-to-input spacing: 4pt (xxs)
- Validation: `.caption` | Between FormGroups: 12pt (sm)

## EmptyStateView
- Icon: 48pt system font, secondary | Title: `.title2` semibold
- Description: `.body` secondary, centered, max 300pt wide
- Outer padding: 48pt (xxl) | Button: `.borderedProminent`, `.controlSize(.large)`
- Prefer `ContentUnavailableView` on macOS 14+

## StatusBadge
- Dot: 6x6pt circle | Dot-text spacing: 4pt (xxs)
- Text: `.caption` medium | H-padding: 6pt | V-padding: 4pt
- Background: status color at 12% opacity | Shape: `Capsule`

## ErrorBanner
- Inner padding: 12pt (sm) | Icon-text spacing: 8pt (xs)
- Corner radius: 8pt (md) | Background: severity color at 10% opacity
- Border: severity color at 30% opacity, 0.5pt
- Severity colors: error=`.red`, warning=`.orange`, info=`.blue`

## LoadingOverlay
- Scrim: `.ultraThinMaterial` | Card: `.regularMaterial`, 12pt (lg) radius
- Card padding: 24pt (lg) | ProgressView: `.controlSize(.large)`
- Message: `.subheadline` secondary

## State Pattern
Every data-driven view needs: loading, loaded, empty, error states.
