import Foundation
import Observation

@MainActor
@Observable
final class MarkdownViewModel {
    var markdownText = "# Untitled\n\n" {
        didSet {
            guard !isLoadingDocument else { return }
            isEdited = true
            if showPreview {
                renderedHTML = HTMLBuilder.build(markdownText)
            }
        }
    }
    var fileURL: URL?
    var isEdited = false
    var showPreview = false
    var renderedHTML = ""
    var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(Double(fontSize), forKey: "fontSize") }
    }

    private var isLoadingDocument = false

    init() {
        let saved = UserDefaults.standard.double(forKey: "fontSize")
        fontSize = saved > 0 ? CGFloat(saved) : 16
    }

    func openDocument(at url: URL) throws {
        let text = try String(contentsOf: url, encoding: .utf8)
        isLoadingDocument = true
        markdownText = text
        fileURL = url.standardizedFileURL
        isEdited = false
        renderedHTML = HTMLBuilder.build(text)
        showPreview = true
        isLoadingDocument = false
    }

    func newDocument() {
        isLoadingDocument = true
        markdownText = "# Untitled\n\n"
        fileURL = nil
        isEdited = false
        renderedHTML = ""
        showPreview = false
        isLoadingDocument = false
    }

    func save(to url: URL) throws {
        try Data(markdownText.utf8).write(to: url, options: .atomic)
        fileURL = url.standardizedFileURL
        isEdited = false
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
