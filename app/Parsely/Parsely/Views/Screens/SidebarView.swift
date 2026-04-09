import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: ParselyViewModel

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.lines.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    TextField("Search JSON\u{2026}", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.callout)
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Clear search"))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 6)
            }

            if viewModel.lines.isEmpty {
                emptyStateView
            } else if viewModel.filteredLines.isEmpty {
                noResultsView
            } else {
                lineListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("No results")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("No lines match \"\(viewModel.searchText)\"")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Open a .jsonl file")
                .font(.title3)
                .foregroundColor(.secondary)
            Button("Open File...") {
                viewModel.openFileImporter()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var lineListView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List(viewModel.filteredLines, selection: Binding(
                    get: { viewModel.selectedLineID },
                    set: { viewModel.selectedLineID = $0 }
                )) { line in
                    SidebarRowView(
                        line: line,
                        isSelected: viewModel.selectedLineID == line.id,
                        searchText: viewModel.searchText
                    )
                        .tag(line.id)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.visible)
                }
                .listStyle(.sidebar)
                .id(viewModel.id)
                .onChange(of: viewModel.selectedLineID) { _, newID in
                    if let newID {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            proxy.scrollTo(newID, anchor: .center)
                        }
                    }
                }
            }

            Divider()
            footerView
        }
    }

    private var footerView: some View {
        let filtered = viewModel.filteredLineCount
        let total = viewModel.lineCount
        let isFiltering = !viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty
        let label = isFiltering
            ? "\(filtered) of \(total) \(total == 1 ? "line" : "lines")"
            : "\(total) \(total == 1 ? "line" : "lines")"

        return HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
