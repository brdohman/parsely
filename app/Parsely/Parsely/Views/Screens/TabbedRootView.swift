import SwiftUI
import UniformTypeIdentifiers

struct TabbedRootView: View {
    @State private var manager = TabManager()
    @State private var showFileImporter = false
    @State private var importErrorMessage: String?

    var body: some View {
        Group {
            if let activeTab = manager.activeTab {
                NavigationSplitView {
                    SidebarView(viewModel: activeTab)
                        .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 400)
                } detail: {
                    VStack(spacing: 0) {
                        TabStripView(manager: manager)
                        Divider()
                        DetailView(line: activeTab.selectedLine, searchText: activeTab.searchText)
                    }
                }
                .toolbar(removing: .sidebarToggle)
                .navigationTitle(activeTab.fileName)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button(action: { showFileImporter = true }) {
                            Label("Open File", systemImage: "folder")
                        }
                        .help("Open a .jsonl file")
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            activeTab.exportSelectedLineAsPrettyJSON()
                        } label: {
                            if activeTab.exportCopied {
                                Label("Copied!", systemImage: "checkmark")
                            } else {
                                Label("Copy as JSON", systemImage: "doc.on.clipboard")
                            }
                        }
                        .help("Copy selected line as pretty-printed JSON (\u{2318}\u{21E7}C)")
                        .disabled(activeTab.selectedLine == nil)
                    }
                }
                .overlay {
                    if activeTab.isLoading {
                        ZStack {
                            Color.black.opacity(0.2)
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Loading...")
                                    .foregroundColor(.secondary)
                            }
                            .padding(24)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    Group {
                        if activeTab.exportCopied {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Copied as pretty JSON")
                                    .font(.callout)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 4)
                            .padding(.bottom, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(duration: 0.3), value: activeTab.exportCopied)
                }
                .alert("Error", isPresented: Binding(
                    get: { activeTab.errorMessage != nil },
                    set: { if !$0 { activeTab.errorMessage = nil } }
                )) {
                    Button("OK") { activeTab.errorMessage = nil }
                } message: {
                    Text(activeTab.errorMessage ?? "")
                }
                .sheet(isPresented: Binding(
                    get: { activeTab.showJumpToLine },
                    set: { activeTab.showJumpToLine = $0 }
                )) {
                    JumpToLineView(viewModel: activeTab)
                }
                .onReceive(NotificationCenter.default.publisher(for: .jumpToLine)) { _ in
                    guard !activeTab.lines.isEmpty else { return }
                    activeTab.showJumpToLine = true
                }
                .onReceive(NotificationCenter.default.publisher(for: .exportPrettyJSON)) { _ in
                    activeTab.exportSelectedLineAsPrettyJSON()
                }
                .onReceive(NotificationCenter.default.publisher(for: .selectNextLine)) { _ in
                    activeTab.selectNextLine()
                }
                .onReceive(NotificationCenter.default.publisher(for: .selectPreviousLine)) { _ in
                    activeTab.selectPreviousLine()
                }
                .onReceive(NotificationCenter.default.publisher(for: .exportRawJSON)) { _ in
                    activeTab.exportSelectedLineAsRawJSON()
                }
            } else {
                emptyStateView
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.jsonl, .json, .text, UTType(filenameExtension: "jsonl") ?? .text],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    for url in urls {
                        await manager.openFile(from: url)
                    }
                }
            case .failure(let error):
                if let activeTab = manager.activeTab {
                    activeTab.errorMessage = error.localizedDescription
                } else {
                    importErrorMessage = error.localizedDescription
                }
            }
        }
        .alert("Import Error", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("OK") { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .onOpenURL { url in
            Task {
                await manager.openFile(from: url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToPreviousTab)) { _ in
            manager.switchToPreviousTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToNextTab)) { _ in
            manager.switchToNextTab()
        }
        .onChange(of: manager.lastOpenError) { _, newValue in
            if let error = newValue {
                importErrorMessage = error
                manager.lastOpenError = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFile)) { _ in
            showFileImporter = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeTab)) { _ in
            manager.closeActiveTab()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Files Open")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Open a JSONL file to get started.")
                .font(.callout)
                .foregroundColor(.secondary)
            Button("Open File\u{2026}") {
                showFileImporter = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard error == nil,
                      let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task {
                    await manager.openFile(from: url)
                }
            }
        }
        return true
    }
}
