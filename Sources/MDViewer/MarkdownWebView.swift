import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    let fontSize: CGFloat

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.loadedHTML != html {
            context.coordinator.loadedHTML = html
            context.coordinator.pendingFontSize = fontSize
            webView.loadHTMLString(html, baseURL: nil)
        } else if context.coordinator.appliedFontSize != fontSize {
            context.coordinator.appliedFontSize = fontSize
            webView.evaluateJavaScript("document.body.style.fontSize = '\(fontSize)px'")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        var loadedHTML: String = ""
        var pendingFontSize: CGFloat = 16
        var appliedFontSize: CGFloat = 0

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let isDark = NSApp.effectiveAppearance
                .bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            webView.evaluateJavaScript("setDarkMode(\(isDark))")
            webView.evaluateJavaScript("document.body.style.fontSize = '\(pendingFontSize)px'")
            appliedFontSize = pendingFontSize
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                return .cancel
            }
            return .allow
        }
    }
}
