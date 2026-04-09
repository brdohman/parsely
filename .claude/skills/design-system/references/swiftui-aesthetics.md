# SwiftUI Aesthetics: Making Native macOS Apps Look Designed, Not Generated

This reference teaches you to produce SwiftUI interfaces that look intentionally designed, not like default Xcode templates with data plugged in. It complements the design system (spacing, typography, color tokens) and HIG compliance rules by adding the layer that makes an app memorable.

**Load this reference when:** Creating new views, building UI for the first time in an epic, designing screens during `/design`, or when the user says anything about visual quality, polish, aesthetics, or "make it look good."

---

## The Problem: SwiftUI "AI Slop"

Claude defaults to safe, generic UI. The SwiftUI version of "AI slop" looks like this:

- Every view uses `.body` and `.headline` with no contrast between them
- Blue accent color on white sidebar (the default Xcode template)
- `List` with plain rows, no visual hierarchy between primary and secondary information
- No animations except what the system provides for free
- Flat solid backgrounds with no depth or atmosphere
- Every screen looks like every other screen in the app
- Uniform spacing and weight throughout, creating a wall of equally-important content

These apps compile, function, and even pass HIG checks. They just don't look like anyone cared.

---

## Design Thinking (Before Coding)

Before writing any view, answer four questions:

1. **Purpose:** What job does this screen do? A dashboard summarizes. A detail view tells a story. An editor captures input. Each has a different visual personality.

2. **Personality:** What adjective describes how this screen should feel? Calm and spacious? Dense and powerful? Warm and approachable? Pick ONE word and commit to it. That word drives every subsequent choice.

3. **Focus point:** What is the ONE thing the user should see first? Everything else is supporting context. If nothing stands out, nothing matters.

4. **Signature moment:** What interaction will the user remember? A smooth transition between states? A satisfying animation when data loads? An elegant empty state? Pick one moment and make it great.

---

## Typography: SF Pro Is Better Than You Think

> **Note:** These examples use Tier 2 (Signature) typography for intentional visual contrast. For standard structural text, use Tier 1 (Semantic) styles. See the Two-Tier Model in `typography-and-color.md`.

You don't need custom fonts on macOS. SF Pro has 9 weights, optical sizing, and width variants. The problem isn't the font, it's how Claude uses it.

**The default (generic):**
```swift
Text("Accounts")
    .font(.headline)     // weight: semibold, ~17pt
Text("$1,234.56")
    .font(.body)         // weight: regular, ~17pt
```
These are almost the same size and weight. Nothing stands out.

**With intention:**
```swift
Text("Accounts")
    .font(.system(size: 13, weight: .medium))
    .foregroundStyle(.secondary)
    .textCase(.uppercase)
    .tracking(1.5)

Text("$1,234.56")
    .font(.system(size: 34, weight: .light))
    .monospacedDigit()
```
Now there's a clear hierarchy. The label is small, uppercase, and tracked out. The number is large, light-weight, and monospaced for alignment. The size jump is ~2.6x, not 1x.

**Principles:**
- **Size contrast of 2x or more** between hierarchy levels. `.headline` vs `.body` is a 1x ratio. That's not contrast, it's sameness.
- **Weight extremes:** `.ultraLight`/`.light` for large display text, `.semibold`/`.bold` for small labels. Not `.regular` vs `.semibold` for everything.
- **Monospaced digits** (`.monospacedDigit()`) for any numbers that align vertically: prices, dates, counts, amounts. Non-negotiable for a banking app.
- **Uppercase tracking** for category labels and section headers: `.textCase(.uppercase)` + `.tracking(1.2)`. Gives small text presence without making it large.
- **One typographic signature per app.** Large light-weight numbers? Uppercase tracked section headers? Condensed sidebar labels? Pick one distinctive pattern and use it consistently.

---

## Color: Dominant + Accent, Not Everything Equal

**The default (generic):**
```swift
Text("Balance").foregroundStyle(.secondary)
Text("$1,234.56").foregroundStyle(.primary)
Image(systemName: "arrow.up").foregroundStyle(.green)
```
Three color roles, none dominant. The screen feels like a spreadsheet.

**With intention:**
```swift
// Define an app accent that's NOT the system blue
extension Color {
    static let appAccent = Color("AppAccent")     // A warm teal, or deep indigo, or whatever has personality
    static let appAccentMuted = appAccent.opacity(0.12)
}

// Use sparingly: accent only on the ONE thing that matters
Text("Balance").foregroundStyle(.tertiary)
Text("$1,234.56")
    .foregroundStyle(.primary)
    .font(.system(size: 34, weight: .light))

HStack(spacing: 4) {
    Image(systemName: "arrow.up.right")
    Text("+2.4%")
}
.font(.system(size: 13, weight: .semibold))
.foregroundStyle(Color.appAccent)   // Accent draws the eye HERE
```

**Principles:**
- **One dominant + one accent.** Most content is `.primary`/`.secondary`/`.tertiary`. Color appears on the ONE element that deserves attention.
- **Don't fight the system accent** for standard controls (buttons, toggles, selections). Use `.tint` or a custom accent only in content areas.
- **Muted accent backgrounds** (`.opacity(0.08)` to `.opacity(0.15)`) for selected states, badges, and status indicators. More refined than saturated backgrounds.
- **Avoid the Xcode template palette:** blue accent on white/gray. If your app looks like a fresh Xcode project, it looks generic. Define at least one custom accent color in your asset catalog.

---

## Materials and Depth: Not Just Flat Rectangles

macOS has a rich depth system. Use it.

**The default (flat):**
```swift
VStack {
    headerContent
    listContent
}
.background(Color(.windowBackgroundColor))
```

**With atmosphere:**
```swift
ZStack {
    // Atmospheric background
    LinearGradient(
        colors: [Color.appAccent.opacity(0.03), .clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    VStack {
        headerContent
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

        listContent
    }
}
```

**Principles:**
- **Subtle gradient washes** (2-5% opacity) on backgrounds add warmth without being visible as "a gradient." The user feels it more than sees it.
- **Materials for floating content:** `.ultraThinMaterial` for overlays, `.regularMaterial` for cards, `.thickMaterial` for prominent surfaces. These respond to the desktop behind them, making the app feel rooted on the Mac.
- **Liquid Glass (macOS 26+):** `.glassEffect()` for interactive elements in toolbars and control surfaces. Use sparingly. Apply after layout modifiers.
- **Shadow hierarchy:** Subtle shadows (`.shadow(color: .black.opacity(0.08), radius: 4, y: 2)`) on elevated content. Not heavy drop shadows. The shadow should be felt, not seen.
- **Vibrancy in sidebars:** `.listStyle(.sidebar)` gives you this for free. Don't override sidebar backgrounds with solid colors.

---

## Animation: One Great Moment, Not Constant Motion

**The default (none or everything):**
```swift
// Either no animation at all, or:
.animation(.default, value: someValue) // on everything, creating chaos
```

**With intention:**
```swift
// The ONE moment: staggered content appearance on data load
ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
    AccountRow(account: account)
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .animation(
            .spring(duration: 0.4, bounce: 0.15).delay(Double(index) * 0.05),
            value: isLoaded
        )
}
```

**Principles:**
- **One orchestrated moment per screen.** The data load, the state transition, the selection change. Pick the most important state change and animate it with care.
- **Staggered reveals** for list content: `delay(Double(index) * 0.04)` creates a cascade effect that feels alive without being busy.
- **Spring for interactive, easeOut for appearance:**
  - `.spring(duration: 0.3, bounce: 0.2)` for taps, selections, toggles
  - `.easeOut(duration: 0.25)` for content appearing
  - Never `.linear` for UI (it feels robotic)
- **Transforms over layout changes:** `scaleEffect`, `offset`, `opacity` are GPU-accelerated and smooth. `frame`, `padding` changes cause layout recalculation and can stutter.
- **Matched geometry for view transitions:** When navigating between states that share an element (e.g., an account card in a list transitioning to a detail header), use `.matchedGeometryEffect(id:in:)` for a seamless morph.
- **Restraint is polish.** An app with zero animations but perfect spacing looks more polished than an app with animations everywhere and inconsistent spacing.

---

## Visual Hierarchy: Not Everything Can Be Important

**The default (flat hierarchy):**
```swift
// Every row has equal visual weight
ForEach(transactions) { tx in
    HStack {
        Text(tx.payee)
        Spacer()
        Text(tx.amount.formatted(.currency(code: "USD")))
    }
}
```

**With hierarchy:**
```swift
ForEach(transactions) { tx in
    HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
            Text(tx.payee)
                .font(.body)
                .fontWeight(.medium)
            Text(tx.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }

        Spacer()

        Text(tx.amount.formatted(.currency(code: "USD")))
            .font(.body)
            .monospacedDigit()
            .foregroundStyle(tx.amount < 0 ? .primary : .appAccent)
    }
    .padding(.vertical, 4)
}
```

**Principles:**
- **Three levels maximum per view:** Primary (what it is), secondary (context), tertiary (metadata). If everything has equal weight, the user's eye has nowhere to go.
- **Primary information gets:** larger size, heavier weight, `.primary` color
- **Secondary information gets:** same or smaller size, lighter weight, `.secondary` color
- **Tertiary information gets:** smallest size, lightest weight, `.tertiary` color
- **Empty states are a design opportunity,** not an afterthought. Use `ContentUnavailableView` with a custom illustration or an intentional message and call to action.
- **Negative space is hierarchy.** Generous spacing between sections says "these are different groups." Tight spacing within a group says "these belong together." Use the spacing scale deliberately (design system tokens), not uniformly.

---

## Where Platform Convention Rules vs. Where Personality Goes

This is the critical boundary. Violating it makes the app feel wrong.

**Stay native (HIG-compliant, no personality):**
- Window chrome (title bar, traffic lights, toolbar area)
- Menu bar structure and keyboard shortcuts
- Sidebar navigation pattern and vibrancy
- Standard controls (Button, Toggle, Picker, Slider)
- System sheet and alert presentation
- Scroll behavior and elastic bouncing

**Add personality (within the design system):**
- Content areas (the main body of each screen)
- Dashboard and summary views
- Empty states and onboarding
- Data visualization and stat displays
- Transition animations between states
- Detail view layouts
- Loading states and progress indication
- Accent color and its application pattern

**The test:** If a user would be confused or annoyed by a non-standard behavior, keep it native. If a user would be delighted by a thoughtful detail, add personality.

---

## Anti-Patterns: SwiftUI "AI Slop" Checklist

If your view has any of these, it needs another pass:

- [ ] Every text element uses `.body` or `.headline` (no size/weight contrast)
- [ ] The accent color is system blue (no custom palette)
- [ ] Zero animations (system defaults only)
- [ ] Flat solid backgrounds on everything (no materials, no gradients, no depth)
- [ ] Every row in a list has identical visual treatment (no hierarchy)
- [ ] Empty states show "No items" with no design thought
- [ ] Loading states are a ProgressView() with no context
- [ ] Numbers displayed without `.monospacedDigit()`
- [ ] No spacing variation between sections (everything evenly spaced)
- [ ] The screen could belong to any app (no personality specific to this one)
