import Observation

@MainActor
@Observable
final class MarkdownViewModel {
    var showPreview: Bool = false
    var renderedHTML: String = ""

    func togglePreview(with markdown: String) {
        if !showPreview {
            renderedHTML = HTMLBuilder.build(markdown)
        }
        showPreview.toggle()
    }
}
