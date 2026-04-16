import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct TabbedRootView: View {
    @State private var manager: TabManager
    @State private var showFileImporter = false
    @State private var importErrorMessage: String?
    @State private var windowNumber: Int?
    @AppStorage("detailZoomLevel") private var zoomLevel: Double = 1.0

    private let initialURLs: [URL]

    init(initialURLs: [URL] = []) {
        _manager = State(initialValue: TabManager())
        self.initialURLs = initialURLs
    }

    var body: some View {
        Group {
            if let activeTab = manager.activeTab {
                NavigationSplitView {
                    sidebarContent(for: activeTab)
                        .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 400)
                } detail: {
                    VStack(spacing: 0) {
                        TabStripView(manager: manager)
                        Divider()
                        GeometryReader { geo in
                            detailContent(for: activeTab)
                                .frame(
                                    width: geo.size.width / zoomLevel,
                                    height: geo.size.height / zoomLevel,
                                    alignment: .topLeading
                                )
                                .scaleEffect(zoomLevel, anchor: .topLeading)
                        }
                    }
                }
                .toolbar(removing: .sidebarToggle)
                .navigationTitle(activeTab.fileName)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button(action: { showFileImporter = true }) {
                            Label("Open File", systemImage: "folder")
                        }
                        .help("Open a file")
                    }
                    if activeTab.fileType == .jsonl {
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
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: 4) {
                            Button { zoomOut() } label: {
                                Image(systemName: "minus.magnifyingglass")
                            }
                            .accessibilityLabel("Zoom out")
                            .help("Zoom out (\u{2318}-)")
                            .disabled(zoomLevel <= 0.5)

                            Text(verbatim: "\(Int(zoomLevel * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 36)

                            Button { zoomIn() } label: {
                                Image(systemName: "plus.magnifyingglass")
                            }
                            .accessibilityLabel("Zoom in")
                            .help("Zoom in (\u{2318}+)")
                            .disabled(zoomLevel >= 2.0)
                        }
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
            allowedContentTypes: [
                .jsonl,
                .json,
                .text,
                .plainText,
                UTType(filenameExtension: "jsonl") ?? .text,
                UTType(filenameExtension: "md") ?? .text,
                UTType(filenameExtension: "markdown") ?? .text,
            ],
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
        .background(WindowAccessor { window in
            windowNumber = window.windowNumber
        })
        .task {
            for url in initialURLs {
                await manager.openFile(from: url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFileURL)) { notification in
            let target = notification.userInfo?["windowNumber"] as? Int
            guard target == nil || target == windowNumber else { return }
            let urls: [URL]
            if let array = notification.object as? [URL] {
                urls = array
            } else if let single = notification.object as? URL {
                urls = [single]
            } else {
                return
            }
            Task {
                for url in urls {
                    await manager.openFile(from: url)
                }
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
        .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
            zoomIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
            zoomOut()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomReset)) { _ in
            zoomLevel = 1.0
        }
    }

    @ViewBuilder
    private func sidebarContent(for tab: ParselyViewModel) -> some View {
        switch tab.fileType {
        case .jsonl:
            SidebarView(viewModel: tab)
        case .markdown:
            MarkdownSidebarView(viewModel: tab)
        }
    }

    @ViewBuilder
    private func detailContent(for tab: ParselyViewModel) -> some View {
        switch tab.fileType {
        case .jsonl:
            DetailView(line: tab.selectedLine, searchText: tab.searchText)
        case .markdown:
            if let mdDoc = tab.markdownDocument {
                MarkdownDetailView(
                    document: mdDoc,
                    scrollTarget: tab.scrollTarget,
                    headingLookup: tab.headingLineIndexToID,
                    onVisibleHeadingChanged: { headingID in
                        if tab.selectedHeadingID != headingID {
                            tab.selectedHeadingID = headingID
                        }
                    }
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Unable to display file")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func zoomIn() {
        zoomLevel = min(2.0, zoomLevel + 0.1)
    }

    private func zoomOut() {
        zoomLevel = max(0.5, zoomLevel - 0.1)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Files Open")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Open a file to get started.")
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

// Captures the NSWindow hosting this SwiftUI view so file-open notifications
// can be routed to the window on the user's currently-active macOS Space.
struct WindowAccessor: NSViewRepresentable {
    let onWindowAvailable: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindowAvailable(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onWindowAvailable(window)
            }
        }
    }
}
