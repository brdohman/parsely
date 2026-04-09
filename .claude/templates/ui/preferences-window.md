# Preferences Window Template

## App Scene (add to your App struct)

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
```

Cmd+, is automatic when you add a `Settings` scene.

## SettingsView (tabbed preferences)

```swift
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            AdvancedSettingsView()
                .tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
        }
        .scenePadding()
        .frame(maxWidth: 450, minHeight: 250)
    }
}
```

Always include `.scenePadding()` for standard macOS preference window insets.

## Settings Tab (example)

```swift
struct GeneralSettingsView: View {
    @AppStorage("refreshInterval") private var refreshInterval = 300
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInDock") private var showInDock = true

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $launchAtLogin)
            Toggle("Show in Dock", isOn: $showInDock)
            Picker("Refresh Interval", selection: $refreshInterval) {
                Text("1 minute").tag(60)
                Text("5 minutes").tag(300)
                Text("15 minutes").tag(900)
                Text("30 minutes").tag(1800)
            }
        }
    }
}
```

## @AppStorage Types

Supported: `Bool`, `Int`, `Double`, `String`, `URL`, `Data`, `Date`.

For enums, conform to `RawRepresentable` with `String` or `Int` raw value:

```swift
enum Theme: String {
    case light, dark, system
}

@AppStorage("theme") private var theme: Theme = .system
```

## Programmatic Navigation to Settings Tab

```swift
// In SettingsView, use @AppStorage for selected tab
@AppStorage("selectedSettingsTab") private var selectedTab = "general"

// From anywhere in the app
@Environment(\.openSettings) private var openSettings
@AppStorage("selectedSettingsTab") private var selectedTab

Button("Open Advanced...") {
    selectedTab = "advanced"
    openSettings()
}
```

## Common Tab Categories

| Tab | Icon | Content |
|---|---|---|
| General | `gear` | Launch behavior, defaults, refresh intervals |
| Accounts | `person.crop.circle` | Login, API keys (stored in Keychain, not AppStorage) |
| Appearance | `paintbrush` | Theme, font size, display density |
| Notifications | `bell` | Alert preferences, sound toggles |
| Advanced | `wrench.and.screwdriver` | Debug options, data management, reset |

## Accessibility

Every form control needs a label. SwiftUI `Form` with labeled controls handles this automatically, but verify with VoiceOver.
