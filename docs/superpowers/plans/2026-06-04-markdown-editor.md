# Markdown Editor macOS App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立一個原生 macOS Markdown 編輯器，支援切換「編輯模式」（TextEditor）與「預覽模式」（WKWebView），以 DocumentGroup 整合標準 macOS 檔案管理體驗。

**Architecture:** `MarkdownDocument (FileDocument)` 是 DocumentGroup 的資料模型，`ContentView` 直接將 `document.text` 綁定至 `TextEditor`；獨立的 `MarkdownViewModel (@Observable)` 只持有 UI 切換狀態 (`showPreview`, `renderedHTML`)，預覽 HTML 僅在切換至預覽時由 `HTMLBuilder` lazy 生成。`MarkdownWebView (NSViewRepresentable)` 包裝 `WKWebView`，於 `didFinish` 時同步系統深色模式。

**Tech Stack:** Swift 6 (Strict Concurrency)、SwiftUI、AppKit (NSViewRepresentable)、WKWebView、marked.js 11.x、highlight.js 11.x、Swift Package Manager

---

## 目錄結構（完成後）

```
md-viewer/
├── Package.swift
├── Makefile
├── Info.plist
├── Sources/
│   └── MDViewer/
│       ├── MDViewerApp.swift
│       ├── MarkdownDocument.swift
│       ├── MarkdownViewModel.swift
│       ├── ContentView.swift
│       ├── MarkdownWebView.swift
│       ├── HTMLBuilder.swift
│       └── Resources/
│           ├── template.html
│           ├── marked.min.js       ← make deps 下載
│           ├── highlight.min.js    ← make deps 下載
│           └── highlight.min.css   ← make deps 下載
└── docs/
    └── superpowers/
        ├── specs/
        │   └── 2026-06-04-markdown-editor-design.md
        └── plans/
            └── 2026-06-04-markdown-editor.md
```

---

## Task 1: Package.swift + 目錄結構

**Files:**
- Create: `Package.swift`
- Create: `Sources/MDViewer/Resources/.gitkeep`

- [ ] **Step 1: 建立目錄結構**

```bash
cd /Users/nickycho/Dev/claude-code/md-viewer
mkdir -p Sources/MDViewer/Resources
touch Sources/MDViewer/Resources/.gitkeep
```

- [ ] **Step 2: 建立 Package.swift**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MDViewer",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MDViewer",
            path: "Sources/MDViewer",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
```

儲存至 `Package.swift`。

- [ ] **Step 3: 確認 Package.swift 語法正確**

```bash
swift package dump-package
```

預期輸出：含 `"name": "MDViewer"` 的 JSON，無 error。

- [ ] **Step 4: Commit**

```bash
git init
git add Package.swift Sources/MDViewer/Resources/.gitkeep docs/
git commit -m "feat: project scaffold with Package.swift"
```

---

## Task 2: Info.plist

**Files:**
- Create: `Info.plist`

- [ ] **Step 1: 建立 Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>MDViewer</string>
    <key>CFBundleDisplayName</key>
    <string>MDViewer</string>
    <key>CFBundleIdentifier</key>
    <string>com.nickycho.mdviewer</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>MDViewer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Markdown Document</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>md</string>
                <string>markdown</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>net.daringfireball.markdown</string>
                <string>public.plain-text</string>
            </array>
        </dict>
    </array>
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>net.daringfireball.markdown</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.plain-text</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>md</string>
                    <string>markdown</string>
                </array>
            </dict>
            <key>UTTypeDescription</key>
            <string>Markdown Document</string>
        </dict>
    </array>
</dict>
</plist>
```

- [ ] **Step 2: Commit**

```bash
git add Info.plist
git commit -m "feat: add Info.plist with markdown UTType declaration"
```

---

## Task 3: Makefile

**Files:**
- Create: `Makefile`

- [ ] **Step 1: 建立 Makefile**

```makefile
MARKED_VER  = 11.5.0
HLJS_VER    = 11.10.0

APP_NAME     = MDViewer
BUNDLE_NAME  = $(APP_NAME).app
BUILD_DIR    = .build/release
BINARY       = $(BUILD_DIR)/$(APP_NAME)
SPM_BUNDLE   = $(BUILD_DIR)/$(APP_NAME)_$(APP_NAME).bundle
RESOURCES    = Sources/$(APP_NAME)/Resources

.PHONY: deps build bundle open run clean update-deps

deps:
	@mkdir -p $(RESOURCES)
	@echo "Downloading marked.js $(MARKED_VER)..."
	@curl -fsSL "https://cdn.jsdelivr.net/npm/marked@$(MARKED_VER)/marked.min.js" \
		-o "$(RESOURCES)/marked.min.js"
	@echo "Downloading highlight.js $(HLJS_VER)..."
	@curl -fsSL "https://cdn.jsdelivr.net/npm/highlight.js@$(HLJS_VER)/build/highlight.min.js" \
		-o "$(RESOURCES)/highlight.min.js"
	@curl -fsSL "https://cdn.jsdelivr.net/npm/highlight.js@$(HLJS_VER)/styles/github-dark.min.css" \
		-o "$(RESOURCES)/highlight.min.css"
	@echo "Done."

build: $(RESOURCES)/marked.min.js
	swift build -c release

bundle: build
	@rm -rf $(BUNDLE_NAME)
	@mkdir -p $(BUNDLE_NAME)/Contents/MacOS
	@mkdir -p $(BUNDLE_NAME)/Contents/Resources
	@cp $(BINARY) $(BUNDLE_NAME)/Contents/MacOS/$(APP_NAME)
	@if [ -d "$(SPM_BUNDLE)" ]; then \
		cp -r "$(SPM_BUNDLE)" "$(BUNDLE_NAME)/Contents/Resources/"; \
	fi
	@cp Info.plist $(BUNDLE_NAME)/Contents/Info.plist
	@echo "Bundled: $(BUNDLE_NAME)"

open: bundle
	open $(BUNDLE_NAME)

run:
	swift run

clean:
	rm -rf .build $(BUNDLE_NAME)

update-deps:
	@rm -f $(RESOURCES)/marked.min.js \
		$(RESOURCES)/highlight.min.js \
		$(RESOURCES)/highlight.min.css
	@$(MAKE) deps
```

- [ ] **Step 2: 驗證 make deps 可執行**

```bash
make deps
```

預期：`Sources/MDViewer/Resources/` 下出現 `marked.min.js`、`highlight.min.js`、`highlight.min.css`，各大於 50KB。

- [ ] **Step 3: Commit**

```bash
git add Makefile Sources/MDViewer/Resources/
git commit -m "feat: add Makefile and download JS dependencies"
```

---

## Task 4: template.html

**Files:**
- Create: `Sources/MDViewer/Resources/template.html`

- [ ] **Step 1: 建立 template.html**

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="highlight.min.css">
<style>
  * { box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
    font-size: 16px;
    line-height: 1.7;
    max-width: 860px;
    margin: 0 auto;
    padding: 32px 40px;
    color: #1d1d1f;
    background: #ffffff;
    word-wrap: break-word;
  }
  body.dark {
    color: #f5f5f7;
    background: #1c1c1e;
  }
  h1, h2, h3, h4, h5, h6 {
    font-weight: 600;
    line-height: 1.3;
    margin-top: 1.5em;
    margin-bottom: 0.5em;
  }
  h1 { font-size: 2em; }
  h2 { font-size: 1.5em; border-bottom: 1px solid #e0e0e0; padding-bottom: 0.3em; }
  body.dark h2 { border-bottom-color: #3a3a3c; }
  a { color: #0071e3; text-decoration: none; }
  a:hover { text-decoration: underline; }
  body.dark a { color: #2997ff; }
  code {
    font-family: 'SF Mono', Menlo, 'Courier New', monospace;
    font-size: 0.875em;
    background: #f5f5f7;
    padding: 0.2em 0.4em;
    border-radius: 4px;
  }
  body.dark code { background: #2c2c2e; }
  pre {
    background: #f5f5f7;
    padding: 16px;
    border-radius: 8px;
    overflow-x: auto;
    margin: 1em 0;
  }
  body.dark pre { background: #2c2c2e; }
  pre code { background: none; padding: 0; font-size: 0.875em; }
  blockquote {
    border-left: 4px solid #d0d0d0;
    margin: 1em 0;
    padding: 0.5em 1em;
    color: #666;
  }
  body.dark blockquote { border-left-color: #48484a; color: #aeaeb2; }
  table { border-collapse: collapse; width: 100%; margin: 1em 0; }
  th, td { border: 1px solid #d0d0d0; padding: 8px 12px; text-align: left; }
  body.dark th, body.dark td { border-color: #48484a; }
  th { background: #f5f5f7; font-weight: 600; }
  body.dark th { background: #2c2c2e; }
  img { max-width: 100%; height: auto; }
  hr { border: none; border-top: 1px solid #e0e0e0; margin: 2em 0; }
  body.dark hr { border-top-color: #3a3a3c; }
</style>
</head>
<body>
<div id="content"></div>
<script src="marked.min.js"></script>
<script src="highlight.min.js"></script>
<script>
  marked.use({ gfm: true, breaks: false });

  const md = `{{MARKDOWN_CONTENT}}`;
  document.getElementById('content').innerHTML = marked.parse(md);

  document.querySelectorAll('pre code').forEach(function(el) {
    hljs.highlightElement(el);
  });

  function setDarkMode(isDark) {
    document.body.classList.toggle('dark', isDark);
  }
</script>
</body>
</html>
```

- [ ] **Step 2: Commit**

```bash
git add Sources/MDViewer/Resources/template.html
git commit -m "feat: add HTML template with marked.js and highlight.js integration"
```

---

## Task 5: MarkdownDocument

**Files:**
- Create: `Sources/MDViewer/MarkdownDocument.swift`

- [ ] **Step 1: 建立 MarkdownDocument.swift**

```swift
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let markdownText = UTType(exportedAs: "net.daringfireball.markdown")
}

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.markdownText, .plainText] }
    static var writableContentTypes: [UTType] { [.markdownText] }

    var text: String

    init(text: String = "# Untitled\n\n") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
```

- [ ] **Step 2: 確認可以編譯**

```bash
swift build 2>&1 | head -20
```

預期：只有 warning（因為其他檔案尚未建立），無 error on MarkdownDocument.swift。

- [ ] **Step 3: Commit**

```bash
git add Sources/MDViewer/MarkdownDocument.swift
git commit -m "feat: add MarkdownDocument FileDocument implementation"
```

---

## Task 6: HTMLBuilder

**Files:**
- Create: `Sources/MDViewer/HTMLBuilder.swift`

- [ ] **Step 1: 建立 HTMLBuilder.swift**

```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add Sources/MDViewer/HTMLBuilder.swift
git commit -m "feat: add HTMLBuilder for injecting markdown into HTML template"
```

---

## Task 7: MarkdownViewModel

**Files:**
- Create: `Sources/MDViewer/MarkdownViewModel.swift`

- [ ] **Step 1: 建立 MarkdownViewModel.swift**

```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add Sources/MDViewer/MarkdownViewModel.swift
git commit -m "feat: add MarkdownViewModel with lazy preview rendering"
```

---

## Task 8: MarkdownWebView

**Files:**
- Create: `Sources/MDViewer/MarkdownWebView.swift`

- [ ] **Step 1: 建立 MarkdownWebView.swift**

```swift
import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedHTML != html else { return }
        context.coordinator.loadedHTML = html
        let baseURL = Bundle.module.resourceURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        var loadedHTML: String = ""

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let isDark = NSApp.effectiveAppearance
                .bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            webView.evaluateJavaScript("setDarkMode(\(isDark))")
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
```

- [ ] **Step 2: Commit**

```bash
git add Sources/MDViewer/MarkdownWebView.swift
git commit -m "feat: add MarkdownWebView NSViewRepresentable with dark mode sync"
```

---

## Task 9: ContentView

**Files:**
- Create: `Sources/MDViewer/ContentView.swift`

- [ ] **Step 1: 建立 ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var viewModel = MarkdownViewModel()

    var body: some View {
        Group {
            if viewModel.showPreview {
                MarkdownWebView(html: viewModel.renderedHTML)
            } else {
                TextEditor(text: $document.text)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.togglePreview(with: document.text)
                } label: {
                    Label(
                        viewModel.showPreview ? "編輯" : "預覽",
                        systemImage: viewModel.showPreview ? "pencil" : "eye"
                    )
                }
                .help(viewModel.showPreview ? "切換回編輯模式" : "切換到預覽模式")
            }
        }
        .navigationTitle("")
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/MDViewer/ContentView.swift
git commit -m "feat: add ContentView with editor/preview toggle toolbar"
```

---

## Task 10: MDViewerApp（App 進入點）

**Files:**
- Create: `Sources/MDViewer/MDViewerApp.swift`

- [ ] **Step 1: 建立 MDViewerApp.swift**

```swift
import SwiftUI

@main
struct MDViewerApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { MarkdownDocument() }) { file in
            ContentView(document: file.$document)
        }
        .defaultSize(width: 960, height: 680)
    }
}
```

- [ ] **Step 2: 確認專案可完整編譯**

```bash
swift build -c release 2>&1 | tail -5
```

預期：`Build complete!`，無 error。

- [ ] **Step 3: Commit**

```bash
git add Sources/MDViewer/MDViewerApp.swift
git commit -m "feat: add MDViewerApp entry point with DocumentGroup"
```

---

## Task 11: 打包並手動驗證

**Files:** 無新增

- [ ] **Step 1: 打包成 .app**

```bash
make bundle
```

預期：輸出 `Bundled: MDViewer.app`，目錄結構：
```
MDViewer.app/
├── Contents/
│   ├── MacOS/MDViewer
│   ├── Resources/
│   │   └── MDViewer_MDViewer.bundle/
│   └── Info.plist
```

- [ ] **Step 2: 開啟 app**

```bash
make open
```

預期：app 視窗開啟，顯示空白 `TextEditor`，工具列有「預覽」按鈕。

- [ ] **Step 3: 手動驗證清單**

依序測試下列功能：

1. **新建文件**：File > New（Cmd+N）→ 新視窗開啟，內含預設 `# Untitled\n\n` 文字
2. **編輯**：在 TextEditor 輸入 markdown 文字（如 `## Hello\n\n**Bold text**`）
3. **切換預覽**：點擊工具列「預覽」→ 渲染出格式化 HTML，標題與粗體正確顯示
4. **切換回編輯**：點擊「編輯」→ 回到 TextEditor，文字未遺失
5. **儲存**：Cmd+S → 標題列「已編輯」標記消失
6. **開啟現有檔案**：File > Open（Cmd+O）→ 選一個 `.md` 檔案，正確載入內容
7. **程式碼區塊**：輸入 ` ```swift\nlet x = 1\n``` ` 並切換預覽 → 語法高亮正確
8. **深色模式**：切換系統深色模式 → 預覽背景/文字顏色對應切換

- [ ] **Step 4: 若有問題，查看 Console.app 或執行 debug build**

```bash
make run
```

Debug 模式下錯誤訊息會直接輸出到 terminal。

- [ ] **Step 5: 最終 Commit**

```bash
git add .
git commit -m "feat: complete MVP markdown editor with edit/preview toggle"
```

---

## 常用指令速查

```bash
make deps         # 下載 JS 函式庫
make build        # Release 編譯
make bundle       # 編譯並打包成 MDViewer.app
make open         # 打包並直接開啟
make run          # Debug 模式（swift run，輸出至 terminal）
make clean        # 清除 .build/ 與 MDViewer.app
make update-deps  # 強制重新下載所有 JS 函式庫
```
