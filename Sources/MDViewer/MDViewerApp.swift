import SwiftUI

@main
struct MDViewerApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
        }
        .defaultSize(width: 960, height: 680)
    }
}
