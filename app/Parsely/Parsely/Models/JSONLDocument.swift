import Foundation

struct JSONLDocument {
    let fileURL: URL
    let lines: [JSONLLine]
    let fileName: String

    var lineCount: Int { lines.count }

    static func parse(from url: URL) throws -> JSONLDocument {
        let content = try String(contentsOf: url, encoding: .utf8)
        return parse(rawContent: content, url: url)
    }

    static func parse(rawContent: String, url: URL) -> JSONLDocument {
        // Split on "\n" and trim whitespace-including-newlines so CRLF (\r\n)
        // and LF files both count one physical line per iteration. Using
        // CharacterSet.newlines here would double-split on \r\n and shift
        // line numbers.
        var lines: [JSONLLine] = []
        var lineNumber = 1
        for raw in rawContent.components(separatedBy: "\n") {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            defer { lineNumber += 1 }
            guard !trimmed.isEmpty else { continue }
            lines.append(JSONLLine(lineNumber: lineNumber, rawJSON: trimmed))
        }

        return JSONLDocument(
            fileURL: url,
            lines: lines,
            fileName: url.lastPathComponent
        )
    }
}
