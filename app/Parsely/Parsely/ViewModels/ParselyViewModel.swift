import Foundation
import Observation
import SwiftUI
import UniformTypeIdentifiers

enum FileType {
    case jsonl
    case markdown
}

struct FlatHeading: Identifiable {
    let heading: MarkdownHeading
    let depth: Int

    var id: UUID { heading.id }
}

struct ScrollTarget: Equatable {
    let lineIndex: Int
    let trigger: UUID

    init(lineIndex: Int) {
        self.lineIndex = lineIndex
        self.trigger = UUID()
    }
}

@Observable
final class ParselyViewModel: Identifiable {
    let id = UUID()
    var displayName: String = String(localized: "No file loaded")
    var fileURL: URL?
    var fileType: FileType = .jsonl
    var document: JSONLDocument?
    var markdownDocument: MarkdownDocument?
    var selectedLineID: UUID?
    var selectedHeadingID: UUID?
    var scrollTarget: ScrollTarget?
    var isLoading = false
    var errorMessage: String?
    var showFileImporter = false
    var searchText: String = ""
    var showJumpToLine: Bool = false
    var exportCopied: Bool = false

    var selectedLine: JSONLLine? {
        guard let id = selectedLineID else { return nil }
        return document?.lines.first(where: { $0.id == id })
    }

    var lines: [JSONLLine] {
        document?.lines ?? []
    }

    var filteredLines: [JSONLLine] {
        let allLines = lines
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return allLines
        }
        let query = searchText.lowercased()
        return allLines.filter { $0.rawJSON.lowercased().contains(query) }
    }

    var lineCount: Int {
        document?.lineCount ?? 0
    }

    var filteredLineCount: Int {
        filteredLines.count
    }

    var fileName: String {
        switch fileType {
        case .jsonl:
            return document?.fileName ?? String(localized: "No file loaded")
        case .markdown:
            return markdownDocument?.fileName ?? String(localized: "No file loaded")
        }
    }

    var isLoaded: Bool {
        switch fileType {
        case .jsonl: return document != nil
        case .markdown: return markdownDocument != nil
        }
    }

    // MARK: - Markdown Headings

    var flattenedHeadings: [FlatHeading] {
        guard let doc = markdownDocument else { return [] }
        return Self.flattenHeadings(doc.headings, depth: 0)
    }

    var filteredHeadings: [FlatHeading] {
        let all = flattenedHeadings
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let query = searchText.lowercased()
        return all.filter { $0.heading.title.lowercased().contains(query) }
    }

    var headingCount: Int {
        flattenedHeadings.count
    }

    var filteredHeadingCount: Int {
        filteredHeadings.count
    }

    var headingLineIndexToID: [Int: UUID] {
        var map: [Int: UUID] = [:]
        for flat in flattenedHeadings {
            map[flat.heading.lineIndex] = flat.heading.id
        }
        return map
    }

    func selectHeading(_ heading: MarkdownHeading) {
        selectedHeadingID = heading.id
        scrollTarget = ScrollTarget(lineIndex: heading.lineIndex)
    }

    private static func flattenHeadings(_ headings: [MarkdownHeading], depth: Int) -> [FlatHeading] {
        var result: [FlatHeading] = []
        for heading in headings {
            result.append(FlatHeading(heading: heading, depth: depth))
            result.append(contentsOf: flattenHeadings(heading.children, depth: depth + 1))
        }
        return result
    }

    // MARK: - File Loading

    func openFileImporter() {
        showFileImporter = true
    }

    static func detectFileType(from url: URL) -> FileType {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "md", "markdown", "mdown", "mkd":
            return .markdown
        default:
            return .jsonl
        }
    }

    func loadFile(from url: URL) async {
        let detectedType = Self.detectFileType(from: url)

        await MainActor.run {
            isLoading = true
            errorMessage = nil
            fileType = detectedType
        }

        // Security scoped resource access
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        switch detectedType {
        case .markdown:
            await loadMarkdownFile(from: url)
        case .jsonl:
            await loadJSONLFile(from: url)
        }
    }

    private func loadMarkdownFile(from url: URL) async {
        let result: Result<MarkdownDocument, Error> = await Task.detached(priority: .userInitiated) {
            Result { try MarkdownDocument.parse(from: url) }
        }.value

        switch result {
        case .success(let doc):
            await MainActor.run {
                if doc.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.displayName = url.lastPathComponent
                    self.fileURL = url
                    self.errorMessage = "This file is empty."
                    self.markdownDocument = nil
                    self.isLoading = false
                } else {
                    self.markdownDocument = doc
                    self.fileURL = url
                    self.displayName = url.lastPathComponent
                    self.isLoading = false
                }
            }
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = "Failed to load file: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func loadJSONLFile(from url: URL) async {
        // Parse on a background thread to avoid blocking the UI
        let result: Result<JSONLDocument, Error> = await Task.detached(priority: .userInitiated) {
            Result { try JSONLDocument.parse(from: url) }
        }.value

        switch result {
        case .success(let doc):
            let allFailed = !doc.lines.isEmpty && doc.lines.allSatisfy { $0.parseError != nil }
            let isEmpty = doc.lines.isEmpty
            await MainActor.run {
                if isEmpty {
                    self.displayName = url.lastPathComponent
                    self.fileURL = url
                    self.errorMessage = "This file is empty. There are no lines to display."
                    self.document = nil
                    self.isLoading = false
                } else if allFailed {
                    self.displayName = url.lastPathComponent
                    self.fileURL = url
                    self.errorMessage = "This file doesn't contain valid JSON. Parsely can only display JSONL (JSON Lines) files where each line is a JSON object."
                    self.document = nil
                    self.isLoading = false
                } else {
                    self.document = doc
                    self.fileURL = url
                    self.displayName = url.lastPathComponent
                    self.selectedLineID = doc.lines.first?.id
                    self.isLoading = false
                }
            }
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = "Failed to load file: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func selectLine(_ line: JSONLLine) {
        selectedLineID = line.id
    }

    // MARK: - Jump To Line

    func jumpToLine(_ lineNumber: Int) {
        // Try filtered lines first; if not found, clear search to show all lines
        if let target = filteredLines.first(where: { $0.lineNumber == lineNumber }) {
            selectedLineID = target.id
        } else if let target = lines.first(where: { $0.lineNumber == lineNumber }) {
            searchText = ""
            selectedLineID = target.id
        }
    }

    // MARK: - Keyboard Navigation

    func selectNextLine() {
        let list = filteredLines
        guard !list.isEmpty else { return }
        if let current = selectedLineID,
           let idx = list.firstIndex(where: { $0.id == current }),
           idx + 1 < list.count {
            selectedLineID = list[idx + 1].id
        } else if selectedLineID == nil {
            selectedLineID = list.first?.id
        }
    }

    func selectPreviousLine() {
        let list = filteredLines
        guard !list.isEmpty else { return }
        if let current = selectedLineID,
           let idx = list.firstIndex(where: { $0.id == current }),
           idx > 0 {
            selectedLineID = list[idx - 1].id
        }
    }

    // MARK: - Export

    func exportSelectedLineAsRawJSON() {
        guard let line = selectedLine else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(line.rawJSON, forType: .string)
        exportCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run { exportCopied = false }
        }
    }

    func exportSelectedLineAsPrettyJSON() {
        guard let line = selectedLine else { return }
        let output: String
        if let parsed = line.parsed,
           let data = try? JSONSerialization.data(
               withJSONObject: jsonValueToAny(parsed),
               options: [.prettyPrinted, .sortedKeys]
           ),
           let pretty = String(data: data, encoding: .utf8) {
            output = pretty
        } else {
            output = line.rawJSON
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
        exportCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run { exportCopied = false }
        }
    }

    private func jsonValueToAny(_ value: JSONValue) -> Any {
        switch value {
        case .object(let pairs):
            var dict: [String: Any] = [:]
            for kv in pairs {
                dict[kv.key] = jsonValueToAny(kv.value)
            }
            return dict
        case .array(let arr):
            return arr.map { jsonValueToAny($0) }
        case .string(let str):
            return str
        case .number(let num):
            return num
        case .bool(let flag):
            return flag
        case .null:
            return NSNull()
        }
    }
}
