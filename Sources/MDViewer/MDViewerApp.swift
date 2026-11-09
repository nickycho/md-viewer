import AppKit
import SwiftUI

@main
struct MDViewerApp: App {
    @NSApplicationDelegateAdaptor(MDViewerAppDelegate.self) private var appDelegate

    var body: some Scene {
        Window(".md Viewer", id: "main") {
            ContentView()
        }
        .defaultSize(width: 960, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新增文件") {
                    NotificationCenter.default.post(name: .mdViewerNewDocument, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .newItem) {
                Button("開啟檔案…") {
                    NotificationCenter.default.post(name: .mdViewerChooseDocument, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {
                Button("儲存") {
                    NotificationCenter.default.post(name: .mdViewerSaveDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                Button("另存新檔…") {
                    NotificationCenter.default.post(name: .mdViewerSaveAsDocument, object: nil)
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
            }
        }
    }
}

extension Notification.Name {
    static let mdViewerOpenDocument = Notification.Name("mdViewer.openDocument")
    static let mdViewerChooseDocument = Notification.Name("mdViewer.chooseDocument")
    static let mdViewerNewDocument = Notification.Name("mdViewer.newDocument")
    static let mdViewerSaveDocument = Notification.Name("mdViewer.saveDocument")
    static let mdViewerSaveAsDocument = Notification.Name("mdViewer.saveAsDocument")
}

@MainActor
final class MDViewerAppDelegate: NSObject, NSApplicationDelegate {
    static var pendingDocumentURL: URL?

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        Self.pendingDocumentURL = url
        NotificationCenter.default.post(name: .mdViewerOpenDocument, object: url)
    }
}
