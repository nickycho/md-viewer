import Foundation

enum HTMLBuilder {
    static func build(_ markdown: String) -> String {
        guard
            let templateURL = Bundle.module.url(forResource: "template", withExtension: "html"),
            let template = try? String(contentsOf: templateURL, encoding: .utf8)
        else {
            return "<html><body><p style='color:red'>Error: template.html not found in bundle.</p></body></html>"
        }
        let escaped = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        return template.replacingOccurrences(of: "{{MARKDOWN_CONTENT}}", with: escaped)
    }
}
