---
name: macos-scenes
description: "macOS SwiftUI scene types, window management, and multi-window patterns. Use when building app structure, adding windows, or managing window lifecycle."
allowed-tools: [Read, Glob, Grep]
---

# macOS Scene Architecture

## Scene Types

### WindowGroup (Primary, macOS 11+)
Most apps start here. Supports multiple windows, tabbed windows, Cmd+N for new.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 600)
    }
}
```

**Data-presenting windows (macOS 13+):**
```swift
WindowGroup(for: Message.ID.self) { $messageID in
    MessageDetail(messageID: messageID)
} defaultValue: {
    model.makeNewMessage().id
}
```
Value type must conform to `Hashable` and `Codable` (for state restoration).

### Window (Singleton, macOS 13+)
One instance only. Use for About, Connection Doctor, auxiliary panels.

```swift
Window("About MyApp", id: "about") {
    AboutView()
}
.windowResizability(.contentSize)
```
Calling `openWindow(id:)` again brings existing to front. If `Window` is the only scene, app quits on close.

### UtilityWindow (Floating, macOS 15+)
Floating tool palettes and inspectors. Stays visible when switching main windows. Hides when app deactivates.

```swift
UtilityWindow("Inspector", id: "inspector") {
    InspectorView()
}
```

### Settings (Preferences, macOS 11+)
**Always wrap in `#if os(macOS)`.** Automatically adds "Settings..." (Cmd+,) to app menu.

```swift
#if os(macOS)
Settings {
    SettingsView()
}
#endif
```

### MenuBarExtra (Menu Bar, macOS 13+)
Persistent icon in system menu bar.

```swift
MenuBarExtra("Status", systemImage: "chart.bar") {
    StatusMenu()
}
.menuBarExtraStyle(.window)  // .menu for pull-down, .window for popover
```
Set `LSUIElement = true` in Info.plist for menu-bar-only apps (no Dock icon).

### DocumentGroup (Document-Based, macOS 11+)
File-based apps. Adds New/Open/Save/Save As/Revert to File menu automatically.

```swift
DocumentGroup(newDocument: MyDocument()) { file in
    ContentView(document: file.$document)
}
```
Requires `UTExportedTypeDeclarations` in Info.plist.

## Opening and Closing Windows

```swift
@Environment(\.openWindow) private var openWindow
@Environment(\.dismissWindow) private var dismissWindow
@Environment(\.openSettings) private var openSettings  // macOS 14+

// Open by ID
openWindow(id: "detail-viewer")

// Open with value (matches WindowGroup(for:))
openWindow(value: item.id)

// Open settings programmatically
openSettings()
```

## Window Sizing

```swift
WindowGroup {
    ContentView()
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
}
.defaultSize(width: 900, height: 600)
.defaultPosition(.center)
.windowResizability(.contentMinSize)  // enforces min from .frame()
```

| Resizability | Behavior |
|---|---|
| `.automatic` | Default. Settings uses contentSize, others use contentMinSize |
| `.contentSize` | Min AND max from content's .frame() |
| `.contentMinSize` | Only min from content's .frame(), no max |

## State Restoration

```swift
// Per-scene storage (survives app restart)
@SceneStorage("selectedTab") private var selectedTab = "home"

// Disable restoration for specific windows
Window("Ephemeral", id: "temp") {
    TempView()
}
.restorationBehavior(.disabled)  // macOS 15+
```

`WindowGroup(for:)` automatically persists and restores the bound value.

## Common App Structures

**Standard app (main + preferences):**
```swift
var body: some Scene {
    WindowGroup { ContentView() }
    #if os(macOS)
    Settings { SettingsView() }
    #endif
}
```

**App with auxiliary window:**
```swift
var body: some Scene {
    WindowGroup { MainView() }
    Window("Activity Log", id: "activity-log") { ActivityLogView() }
    #if os(macOS)
    Settings { SettingsView() }
    #endif
}
```

**Menu bar utility:**
```swift
var body: some Scene {
    MenuBarExtra("Utility", systemImage: "hammer") { UtilityMenu() }
        .menuBarExtraStyle(.window)
}
```

## Pitfalls

- `Window` as primary scene quits app on close. Use `WindowGroup` unless you want this.
- `WindowGroup(for:)` passes `nil` on File > New Window. Always handle nil or provide `defaultValue`.
- `.windowResizability(.contentSize)` requires `.frame()` on content view or it has no size info.
- `.scenePadding()` is required inside `Settings` for proper insets.
- Always `#if os(macOS)` around `Settings` scene.
