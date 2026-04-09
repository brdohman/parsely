# Spacing and Layout

## Spacing Constants (CGFloat Extension)

Add to `Utilities/Extensions/` — this is the **single source of truth** for spacing values.

```swift
import SwiftUI

extension CGFloat {
    static let spacingXXS: CGFloat = 4   // Tight gaps: icon-to-badge, inner badge padding
    static let spacingXS: CGFloat = 8    // Icon-to-label, between related inline elements
    static let spacingSM: CGFloat = 12   // Compact padding, sidebar items, between form fields
    static let spacingMD: CGFloat = 16   // Standard content padding, card inner padding
    static let spacingLG: CGFloat = 24   // Between sections, major area padding
    static let spacingXL: CGFloat = 32   // Page-level margins, hero spacing
    static let spacingXXL: CGFloat = 48  // Splash/empty state spacing, large visual gaps
}

extension CGFloat {
    static let cornerRadiusSM: CGFloat = 6   // Badges, tags, small pills
    static let cornerRadiusMD: CGFloat = 8   // Buttons, input fields, small cards
    static let cornerRadiusLG: CGFloat = 12  // Cards, panels, popovers
    static let cornerRadiusXL: CGFloat = 16  // Large cards, modal sheets
}
```

## Standard Padding Rules

| Context | Padding |
|---------|---------|
| **Sidebar** | 12pt (sm) horizontal, 8pt (xs) vertical, row height 28-32pt |
| **Content/detail area** | 16pt (md) all sides, 24pt (lg) between sections |
| **Cards** | 16pt (md) inner, 16pt (md) between, 12pt (lg) corner radius |
| **Forms** | 8-12pt between fields, 24pt (lg) between sections |
| **Toolbar** | 12pt (sm) between items |
| **Detail headers** | 24pt (lg) top, 4pt (xxs) title-subtitle, 24pt (lg) to content |

## Density Rules

| Area | Font | Icon | Spacing |
|------|------|------|---------|
| **Sidebar** | `.callout` primary, `.footnote` secondary | 16-20pt | `.listStyle(.sidebar)` |
| **Content** | Per typography system | Per component | 44pt min interactive height |
| **Forms** | `.body` values, `.body.secondary` labels | — | `.formStyle(.grouped)` |
| **Dashboard** | `.title`/`.title2` stats, `.caption` labels | Per component | LazyVGrid flexible columns |
