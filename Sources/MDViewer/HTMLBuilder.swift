import Foundation

enum HTMLBuilder {
    static func build(_ markdown: String) -> String {
        guard
            let templateURL = Bundle.module.url(forResource: "template", withExtension: "html"),
            let template = try? String(contentsOf: templateURL, encoding: .utf8)
        else {
            return "<html><body><p style='color:red'>Error: template.html not found in bundle.</p></body></html>"
        }

        let markedJS = readResource(name: "marked.min", ext: "js")
        let highlightJS = readResource(name: "highlight.min", ext: "js")
        let highlightCSS = readResource(name: "highlight.min", ext: "css")

        let escaped = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        var html = template.replacingOccurrences(of: "{{MARKDOWN_CONTENT}}", with: escaped)
        html = html.replacingOccurrences(of: #"<link rel="stylesheet" href="highlight.min.css">"#,
                                         with: "<style>\(highlightCSS)</style>")
        html = html.replacingOccurrences(of: #"<script src="marked.min.js"></script>"#,
                                         with: "<script>\(markedJS)</script>")
        html = html.replacingOccurrences(of: #"<script src="highlight.min.js"></script>"#,
                                         with: "<script>\(highlightJS)</script>")
        return html
    }

    private static func readResource(name: String, ext: String) -> String {
        guard
            let url = Bundle.module.url(forResource: name, withExtension: ext),
            let content = try? String(contentsOf: url, encoding: .utf8)
        else { return "" }
        return content
    }
}
