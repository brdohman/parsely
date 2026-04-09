import SwiftUI

struct SidebarRowView: View {
    let line: JSONLLine
    let isSelected: Bool
    var searchText: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(verbatim: "\(line.lineNumber)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(minWidth: 32, alignment: .trailing)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                highlightedText(line.preview, query: searchText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if line.parseError != nil {
                    Label("Parse error", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
