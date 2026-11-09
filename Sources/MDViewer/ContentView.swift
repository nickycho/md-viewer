import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var viewModel = MarkdownViewModel()

    @State private var recentFiles: [RecentFile] = []
    @State private var searchText = ""
    @State private var selectedURL: URL?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isSettingsPresented = false
    @State private var maximumRecentCount = 10
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
                .navigationSplitViewColumnWidth(min: 240, ideal: 290, max: 340)
        } detail: {
            documentContent
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear(perform: prepareWindow)
        .onReceive(NotificationCenter.default.publisher(for: .mdViewerOpenDocument)) { notification in
            guard let url = notification.object as? URL else { return }
            MDViewerAppDelegate.pendingDocumentURL = nil
            requestOpen(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdViewerChooseDocument)) { _ in
            chooseFile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdViewerNewDocument)) { _ in
            createNewDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdViewerSaveDocument)) { _ in
            _ = saveDocument()
        }
        .onReceive(NotificationCenter.default.publisher(for: .mdViewerSaveAsDocument)) { _ in
            saveDocumentAs()
        }
        .alert("檔案操作失敗", isPresented: $isErrorPresented) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Text(".md Viewer")
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Button(action: chooseFile) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("開啟檔案")

                Button(action: refreshRecentFiles) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("重新整理最近檔案")

                Button {
                    isSettingsPresented.toggle()
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("側邊欄設定")
                .popover(isPresented: $isSettingsPresented, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近檔案")
                            .font(.headline)
                        Stepper(value: $maximumRecentCount, in: 5...50, step: 5) {
                            Text("最多顯示 \(maximumRecentCount) 個")
                        }
                        Text("此設定只影響側邊欄最近檔案清單。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(width: 260)
                    .onChange(of: maximumRecentCount) { _, count in
                        UserDefaults.standard.set(count, forKey: "sidebarMaximumRecentCount")
                        refreshRecentFiles()
                    }
                }

                Button {
                    columnVisibility = columnVisibility == .all ? .detailOnly : .all
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .help(columnVisibility == .all ? "隱藏側邊欄" : "顯示側邊欄")
            }
            .buttonStyle(.borderless)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜尋最近檔案", text: $searchText)
                    .textFieldStyle(.plain)
                    .accessibilityLabel("搜尋最近檔案")
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("清除搜尋")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))

            Button(action: chooseFile) {
                Label("開啟檔案…", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("最近檔案")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredFiles) { file in
                        Button {
                            requestOpen(file.url)
                        } label: {
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: file.symbolName)
                                    .foregroundStyle(.tint)
                                    .frame(width: 18)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(file.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(file.details)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                            .background(
                                selectedURL?.standardizedFileURL == file.url.standardizedFileURL
                                    ? Color.accentColor.opacity(0.18)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 7)
                            )
                        }
                        .buttonStyle(.plain)
                        .help(file.url.path)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .overlay {
                if filteredFiles.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: recentFiles.isEmpty ? "doc.text" : "magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text(recentFiles.isEmpty ? "尚無最近檔案" : "找不到符合的檔案")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        if recentFiles.isEmpty {
                            Text("開啟檔案後會列在這裡。")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial)
    }

    private var documentContent: some View {
        Group {
            if viewModel.showPreview {
                MarkdownWebView(html: viewModel.renderedHTML, fontSize: viewModel.fontSize)
            } else {
                TextEditor(text: $viewModel.markdownText)
                    .font(.system(size: viewModel.fontSize, design: .monospaced))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    columnVisibility = columnVisibility == .all ? .detailOnly : .all
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .help(columnVisibility == .all ? "隱藏側邊欄" : "顯示側邊欄")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    _ = saveDocument()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("儲存 (⌘S)")
                .disabled(!viewModel.isEdited)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.togglePreview(with: viewModel.markdownText)
                } label: {
                    Label(
                        viewModel.showPreview ? "編輯" : "預覽",
                        systemImage: viewModel.showPreview ? "pencil" : "eye"
                    )
                }
                .help(viewModel.showPreview ? "切換回編輯模式" : "切換到預覽模式")
            }
            ToolbarItem(placement: .primaryAction) {
                Button { viewModel.decreaseFontSize() } label: {
                    Image(systemName: "textformat.size.smaller")
                }
                .help("縮小字型 (⌘-)")
                .keyboardShortcut("-", modifiers: .command)
                .disabled(viewModel.fontSize <= 10)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { viewModel.increaseFontSize() } label: {
                    Image(systemName: "textformat.size.larger")
                }
                .help("增大字型 (⌘=)")
                .keyboardShortcut("=", modifiers: .command)
                .disabled(viewModel.fontSize >= 32)
            }
        }
        .navigationTitle(viewModel.fileURL?.lastPathComponent ?? "未命名文件")
    }

    private var filteredFiles: [RecentFile] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return recentFiles }
        return recentFiles.filter {
            $0.name.localizedStandardContains(query) ||
            $0.url.path.localizedStandardContains(query)
        }
    }

    private func prepareWindow() {
        refreshRecentFiles()
        guard let url = MDViewerAppDelegate.pendingDocumentURL else { return }
        MDViewerAppDelegate.pendingDocumentURL = nil
        requestOpen(url)
    }

    private func refreshRecentFiles() {
        let savedCount = UserDefaults.standard.integer(forKey: "sidebarMaximumRecentCount")
        maximumRecentCount = savedCount == 0 ? 10 : min(max(savedCount, 5), 50)
        recentFiles = NSDocumentController.shared.recentDocumentURLs
            .filter { url in
                ["md", "markdown", "txt"].contains(url.pathExtension.lowercased()) &&
                FileManager.default.fileExists(atPath: url.path)
            }
            .prefix(maximumRecentCount)
            .map(RecentFile.init(url:))
    }

    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.markdownText, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "開啟"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            requestOpen(url)
        }
    }

    private func requestOpen(_ url: URL) {
        let standardizedURL = url.standardizedFileURL
        if viewModel.fileURL?.standardizedFileURL == standardizedURL {
            selectedURL = standardizedURL
            return
        }
        guard confirmUnsavedChanges() else { return }

        do {
            try viewModel.openDocument(at: standardizedURL)
            selectedURL = standardizedURL
            NSDocumentController.shared.noteNewRecentDocumentURL(standardizedURL)
            refreshRecentFiles()
        } catch {
            presentError(error)
        }
    }

    private func createNewDocument() {
        guard confirmUnsavedChanges() else { return }
        viewModel.newDocument()
        selectedURL = nil
    }

    private func confirmUnsavedChanges() -> Bool {
        guard viewModel.isEdited else { return true }

        let alert = NSAlert()
        alert.messageText = "尚有未儲存的變更"
        alert.informativeText = "切換文件前要先儲存目前的內容嗎？"
        alert.addButton(withTitle: "儲存")
        alert.addButton(withTitle: "不儲存")
        alert.addButton(withTitle: "取消")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return saveDocument()
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    @discardableResult
    private func saveDocument() -> Bool {
        guard let url = viewModel.fileURL else {
            return saveDocumentAs()
        }
        return writeDocument(to: url)
    }

    @discardableResult
    private func saveDocumentAs() -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.markdownText]
        panel.nameFieldStringValue = viewModel.fileURL?.lastPathComponent ?? "Untitled.md"
        panel.prompt = "儲存"

        guard panel.runModal() == .OK, let url = panel.url else { return false }
        return writeDocument(to: url)
    }

    private func writeDocument(to url: URL) -> Bool {
        do {
            try viewModel.save(to: url)
            selectedURL = url.standardizedFileURL
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            refreshRecentFiles()
            return true
        } catch {
            presentError(error)
            return false
        }
    }

    private func presentError(_ error: Error) {
        errorMessage = error.localizedDescription
        isErrorPresented = true
    }

    private struct RecentFile: Identifiable {
        let url: URL

        var id: String { url.standardizedFileURL.path }
        var name: String { url.lastPathComponent }
        var symbolName: String {
            switch url.pathExtension.lowercased() {
            case "md", "markdown":
                "doc.text"
            default:
                "doc.plaintext"
            }
        }

        var details: String {
            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            let date = values?.contentModificationDate?.formatted(.relative(presentation: .named)) ?? "時間未知"
            let size = values?.fileSize.map {
                ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file)
            } ?? "大小未知"
            return "\(date) · \(size)"
        }
    }
}
