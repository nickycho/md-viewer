import SwiftUI

@main
struct MDViewerApp: App {
    @State private var document = MarkdownDocument()

    var body: some Scene {
        WindowGroup {
            ContentView(document: $document)
        }
        .defaultSize(width: 960, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    document = MarkdownDocument()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
