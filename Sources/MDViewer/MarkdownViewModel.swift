import Foundation
import Observation

@MainActor
@Observable
final class MarkdownViewModel {
    var showPreview: Bool = false
    var renderedHTML: String = ""
    var fontSize: CGFloat = 16

    func togglePreview(with markdown: String) {
        if !showPreview {
            renderedHTML = HTMLBuilder.build(markdown)
        }
        showPreview.toggle()
    }

    func increaseFontSize() {
        fontSize = min(fontSize + 2, 32)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - 2, 10)
    }
}
