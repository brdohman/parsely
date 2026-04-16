import SwiftUI

struct TabStripView: View {
    @Bindable var manager: TabManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(manager.tabs) { tab in
                    TabItemView(
                        tab: tab,
                        isActive: tab.id == manager.activeTabID,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                manager.activeTabID = tab.id
                            }
                        },
                        onClose: {
                            withAnimation(.easeOut(duration: 0.15)) {
                                manager.closeTab(tab.id)
                            }
                        }
                    )
                }

                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 36)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct TabItemView: View {
    let tab: ParselyViewModel
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tab.fileType == .markdown ? "doc.richtext" : "doc.text")
                .font(.system(size: 11))
                .foregroundStyle(isActive ? .primary : .secondary)

            Text(tab.displayName)
                .font(.callout)
                .fontWeight(isActive ? .medium : .regular)
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(1)
                .frame(maxWidth: 140, alignment: .leading)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .opacity(isHovering || isActive ? 1 : 0)
            .accessibilityLabel(Text("Close \(tab.displayName)"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.accentColor.opacity(0.15) : (isHovering ? Color.primary.opacity(0.05) : Color.clear))
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel(Text("\(tab.displayName), tab"))
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}
