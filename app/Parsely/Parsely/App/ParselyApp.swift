import SwiftUI

@main
struct ParselyApp: App {
    var body: some Scene {
        Window("Parsely", id: "main") {
            TabbedRootView()
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open File\u{2026}") {
                    NotificationCenter.default.post(name: .openFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Close Tab") {
                    NotificationCenter.default.post(name: .closeTab, object: nil)
                }
                .keyboardShortcut("w", modifiers: .command)
            }
            CommandMenu("Navigation") {
                Button("Jump to Line\u{2026}") {
                    NotificationCenter.default.post(name: .jumpToLine, object: nil)
                }
                .keyboardShortcut("g", modifiers: .command)

                Button("Next Line") {
                    NotificationCenter.default.post(name: .selectNextLine, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: [.option])

                Button("Previous Line") {
                    NotificationCenter.default.post(name: .selectPreviousLine, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: [.option])

                Divider()

                Button("Previous Tab") {
                    NotificationCenter.default.post(name: .switchToPreviousTab, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)

                Button("Next Tab") {
                    NotificationCenter.default.post(name: .switchToNextTab, object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)
            }
            CommandGroup(after: .pasteboard) {
                Button("Copy Line as Pretty JSON") {
                    NotificationCenter.default.post(name: .exportPrettyJSON, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button("Copy Line as Raw JSON") {
                    NotificationCenter.default.post(name: .exportRawJSON, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let jumpToLine = Notification.Name("com.jsonlviewer.jumpToLine")
    static let exportPrettyJSON = Notification.Name("com.jsonlviewer.exportPrettyJSON")
    static let selectNextLine = Notification.Name("com.jsonlviewer.selectNextLine")
    static let selectPreviousLine = Notification.Name("com.jsonlviewer.selectPreviousLine")
    static let switchToPreviousTab = Notification.Name("com.jsonlviewer.switchToPreviousTab")
    static let switchToNextTab = Notification.Name("com.jsonlviewer.switchToNextTab")
    static let exportRawJSON = Notification.Name("com.parsely.exportRawJSON")
    static let openFile = Notification.Name("com.parsely.openFile")
    static let closeTab = Notification.Name("com.parsely.closeTab")
}

