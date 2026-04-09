---
paths:
  - "app/**/*.swift"
---

# Localization Standards

## All User-Visible Strings Must Be Localizable

### In SwiftUI Views (Automatic)

SwiftUI `Text`, `Button`, `Label`, `Toggle`, `NavigationLink` automatically create `LocalizedStringKey` from string literals. No extra work needed:

```swift
Text("Welcome")              // Automatically localizable
Button("Save") { save() }    // Automatically localizable
Label("Settings", systemImage: "gear")  // Automatically localizable
```

For variables that should be localized:
```swift
Text(LocalizedStringKey(dynamicKey))
```

For variables that should NOT be localized (user input, data):
```swift
Text(verbatim: userInput)
```

### In ViewModels, Services, Non-View Code

Use `String(localized:)` (macOS 12+). Never use `NSLocalizedString`.

```swift
let title = String(localized: "welcome_title")
let error = String(localized: "network_error",
                   comment: "Shown when network request fails")
```

## Locale-Aware Formatting (Required)

### Currency

Never hardcode currency symbols or decimal separators.

```swift
// GOOD — locale-aware
let price: Decimal = 1234.56
Text(price, format: .currency(code: "USD"))  // "$1,234.56" in en_US, "1.234,56 $" in de_DE

// BAD — hardcoded
Text("$\(price)")
```

### Dates

```swift
// GOOD — locale-aware
Text(date, format: .dateTime.month().day().year())

// GOOD — relative
Text(date, format: .relative(presentation: .named))  // "yesterday", "2 days ago"

// BAD — hardcoded format
Text("\(month)/\(day)/\(year)")
```

### Numbers

```swift
// GOOD — locale-aware
Text(count, format: .number)                          // "1,234" in en, "1.234" in de
Text(ratio, format: .percent)                         // "85%"

// BAD — hardcoded separator
Text("\(count),\(remainder)")
```

## String Catalogs

Use Xcode String Catalogs (`.xcstrings`) for all new projects. Xcode auto-extracts localizable strings from SwiftUI views and `String(localized:)` calls.

## Never

- Hardcode currency symbols (`$`, `€`, `£`)
- Hardcode date formats (`MM/dd/yyyy`)
- Hardcode number separators (`,` for thousands)
- Use `NumberFormatter` or `DateFormatter` (use `.formatted()` instead)
- Concatenate strings for pluralization (use String Catalog plural rules)
