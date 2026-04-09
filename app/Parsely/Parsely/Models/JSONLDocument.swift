import Foundation

struct JSONLDocument {
    let fileURL: URL
    let lines: [JSONLLine]
    let fileName: String

    var lineCount: Int { lines.count }

    static func parse(from url: URL) throws -> JSONLDocument {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rawLines = content.components(separatedBy: .newlines)

        var lines: [JSONLLine] = []
        var lineNumber = 1
        for raw in rawLines {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { lineNumber += 1; continue }
            lines.append(JSONLLine(lineNumber: lineNumber, rawJSON: trimmed))
            lineNumber += 1
        }

        return JSONLDocument(
            fileURL: url,
            lines: lines,
            fileName: url.lastPathComponent
        )
    }
}
