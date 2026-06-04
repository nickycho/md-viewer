import Foundation
import Observation

@MainActor
@Observable
final class MarkdownViewModel {
    var showPreview: Bool = false
    var renderedHTML: String = ""
    var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(Double(fontSize), forKey: "fontSize") }
    }

    init() {
        let saved = UserDefaults.standard.double(forKey: "fontSize")
        fontSize = saved > 0 ? CGFloat(saved) : 16
    }

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
