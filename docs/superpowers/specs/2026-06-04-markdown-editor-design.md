# Markdown Viewer/Editor macOS App — Design Spec

**日期：** 2026-06-04  
**平台：** macOS 14+  
**語言：** Swift 6（Swift Strict Concurrency）  
**UI 框架：** SwiftUI + AppKit（NSViewRepresentable）

---

## 目標

開發一個原生 macOS Markdown 編輯器，支援切換「編輯模式」與「預覽模式」，使用 DocumentGroup 整合 macOS 標準檔案管理體驗。

---

## 架構

```
MarkdownDocument (FileDocument)
  └─ ContentView
       ├─ MarkdownViewModel (@Observable)
       │    ├─ markdownText: String        ← 雙向綁定 TextEditor
       │    ├─ showPreview: Bool           ← 切換狀態
       │    └─ renderedHTML: String        ← 由 markdownText 衍生（lazy）
       └─ 條件渲染
            ├─ [編輯模式] TextEditor(text: $viewModel.markdownText)
            └─ [預覽模式] MarkdownWebView (NSViewRepresentable → WKWebView)
```

---

## 元件拆分

| 檔案 | 職責 |
|------|------|
| `MarkdownViewerApp.swift` | App 進入點，宣告 `DocumentGroup`，限定 `.md` / `.markdown` 副檔名 |
| `MarkdownDocument.swift` | `FileDocument`，實作 `init(configuration:)` 讀取與 `fileWrapper(configuration:)` 寫入 |
| `MarkdownViewModel.swift` | `@Observable`，持有 `markdownText`、`showPreview`、`renderedHTML` |
| `ContentView.swift` | 主視窗 UI，根據 `showPreview` 切換 TextEditor / MarkdownWebView；工具列切換按鈕 |
| `MarkdownWebView.swift` | `NSViewRepresentable`，包裝 `WKWebView`；`WKNavigationDelegate` 於 `didFinish` 同步深色模式 |
| `HTMLBuilder.swift` | 讀取 `template.html`，將 markdown 注入 `{{MARKDOWN_CONTENT}}` 佔位符 |
| `Resources/template.html` | HTML 模板，本地載入 marked.js、highlight.js；`setDarkMode(bool)` JS API |

---

## 資料流

### 編輯流程
```
使用者輸入文字
  → TextEditor 更新 markdownText（雙向綁定）
  → DocumentGroup 偵測變更 → 標題列顯示「已編輯」
  → Cmd+S 觸發存檔
```

### 切換預覽
```
使用者點擊「預覽」按鈕
  → showPreview = true
  → HTMLBuilder.build(markdownText) → renderedHTML
  → WKWebView.loadHTMLString(renderedHTML)
切回編輯：showPreview = false（WebView 保留在記憶體，不銷毀）
```

### 深色模式同步
```
WKNavigationDelegate.didFinish
  → evaluateJavaScript("setDarkMode(isDark)")
  → template.html 切換 CSS class
```

### 檔案開啟
```
DocumentGroup 攔截 .md / .markdown 檔案
  → MarkdownDocument.init(configuration:) 讀取內容
  → 注入 ContentView → MarkdownViewModel 初始化
```

---

## 關鍵約束

- 目標平台：macOS 14+，Swift 6，Swift Strict Concurrency
- 只處理 `.md` / `.markdown` 副檔名
- JS 資源（marked.js、highlight.js）打包進 Bundle，不依賴網路
- HTML 渲染為 lazy：切換至預覽模式時才觸發，不在背景持續渲染

---

## 錯誤處理

| 情境 | 處理方式 |
|------|----------|
| 檔案讀取失敗 | DocumentGroup 原生錯誤對話框，無需額外實作 |
| HTML 渲染失敗 | WKWebView 顯示空白，不 crash |
| markdownText 為空時切換預覽 | 顯示空白預覽頁，正常行為 |

---

## MVP 範圍外（刻意不做）

- 編輯區語法高亮
- 自動存檔（autosave）
- 搜尋取代
- 大綱側邊欄（TOC）
- 匯出 HTML / PDF
