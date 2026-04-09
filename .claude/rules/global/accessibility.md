---
paths:
  - "app/**/*View*.swift"
  - "app/**/*Screen*.swift"
---

# Accessibility Standards (macOS)

## Required on ALL Interactive Elements

```swift
Button("Save") { save() }
    .accessibilityLabel("Save document")
    .accessibilityHint("Saves current changes to disk")

Toggle("Dark Mode", isOn: $isDarkMode)
    .accessibilityLabel("Dark mode toggle")
```

## Required Patterns

### Labels
- Every `Button`, `Toggle`, `Slider`, `TextField`, `Picker` must have `.accessibilityLabel()`
- Labels must describe the action, not the appearance ("Save document" not "Blue button")
- Icon-only buttons MUST have labels — VoiceOver can't read SF Symbols

### Hints
- Add `.accessibilityHint()` when the action isn't obvious from the label
- Hints describe what happens, not how to interact ("Opens settings" not "Double-tap to open")

### Grouping
```swift
// Group related elements so VoiceOver reads them as one
HStack {
    Image(systemName: "star.fill")
    Text("4.5 rating")
}
.accessibilityElement(children: .combine)
```

### Value Descriptions
```swift
Slider(value: $volume, in: 0...100)
    .accessibilityValue("\(Int(volume)) percent")
```

### Keyboard Navigation
- All interactive elements must be reachable via Tab key
- Custom views need `.focusable()` modifier on macOS
- Support Escape to dismiss modals/popovers

## Semantic Colors

Use system semantic colors — they adapt to accessibility settings (High Contrast, Reduce Transparency):
- `.primary`, `.secondary` — not hardcoded RGB
- `.accentColor` — not custom hex values

## Testing

- Run Accessibility Inspector (Xcode > Open Developer Tool > Accessibility Inspector)
- Tab through every screen with keyboard only
- Enable VoiceOver (Cmd+F5) and navigate the full flow

## Never

- Use color alone to convey meaning (add icons or text)
- Set `.accessibilityHidden(true)` on interactive elements
- Use images of text instead of actual text
- Skip keyboard navigation support on macOS
