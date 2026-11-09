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


enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case chinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"

    var id: String { rawValue }

    var resolved: AppLanguage {
        guard self == .system else { return self }
        for identifier in Locale.preferredLanguages {
            let languageCode = identifier
                .replacingOccurrences(of: "_", with: "-")
                .split(separator: "-")
                .first?
                .lowercased()
            switch languageCode {
            case "en": return .english
            case "zh": return .chinese
            case "ja": return .japanese
            case "ko": return .korean
            default: continue
            }
        }
        return .english
    }

    var locale: Locale {
        switch resolved {
        case .system, .english:
            Locale(identifier: "en")
        case .chinese:
            Locale(identifier: "zh-Hant-TW")
        case .japanese:
            Locale(identifier: "ja")
        case .korean:
            Locale(identifier: "ko")
        }
    }

    func text(_ key: AppText) -> String {
        key.value(in: resolved)
    }

    func displayName(in activeLanguage: AppLanguage) -> String {
        switch self {
        case .system:
            activeLanguage.text(.followSystem)
        case .english:
            "English"
        case .chinese:
            "繁體中文"
        case .japanese:
            "日本語"
        case .korean:
            "한국어"
        }
    }
}

enum AppText: String {
    case followSystem
    case language
    case openFile
    case openFileHelp
    case refreshRecentFiles
    case sidebarSettings
    case recentFiles
    case maxRecentFilesFormat
    case recentFilesLimitNote
    case searchRecentFiles
    case clearSearch
    case noRecentFiles
    case noMatchingFiles
    case openFileHint
    case hideSidebar
    case showSidebar
    case save
    case saveAs
    case newDocument
    case openMenu
    case openPrompt
    case savePrompt
    case fileOperationFailed
    case ok
    case edit
    case preview
    case switchToEdit
    case switchToPreview
    case decreaseFontSize
    case increaseFontSize
    case saveShortcut
    case untitledDocument
    case untitledFileName
    case unsavedChangesTitle
    case unsavedChangesMessage
    case discard
    case cancel
    case unknownTime
    case unknownSize

    func value(in language: AppLanguage) -> String {
        Self.translations[self]?[language.resolved]
            ?? Self.translations[self]?[.english]
            ?? rawValue
    }

    private static let translations: [AppText: [AppLanguage: String]] = [
        .followSystem: [
            .english: "Follow System",
            .chinese: "跟隨系統",
            .japanese: "システム設定に従う",
            .korean: "시스템 언어 따르기"
        ],
        .language: [
            .english: "Language",
            .chinese: "語言",
            .japanese: "言語",
            .korean: "언어"
        ],
        .openFile: [
            .english: "Open File…",
            .chinese: "開啟檔案…",
            .japanese: "ファイルを開く…",
            .korean: "파일 열기…"
        ],
        .openFileHelp: [
            .english: "Open file",
            .chinese: "開啟檔案",
            .japanese: "ファイルを開く",
            .korean: "파일 열기"
        ],
        .refreshRecentFiles: [
            .english: "Refresh recent files",
            .chinese: "重新整理最近檔案",
            .japanese: "最近使ったファイルを更新",
            .korean: "최근 파일 새로 고침"
        ],
        .sidebarSettings: [
            .english: "Sidebar settings",
            .chinese: "側邊欄設定",
            .japanese: "サイドバー設定",
            .korean: "사이드바 설정"
        ],
        .recentFiles: [
            .english: "Recent Files",
            .chinese: "最近檔案",
            .japanese: "最近使ったファイル",
            .korean: "최근 파일"
        ],
        .maxRecentFilesFormat: [
            .english: "Show up to %d files",
            .chinese: "最多顯示 %d 個檔案",
            .japanese: "最大%d件を表示",
            .korean: "최대 %d개 표시"
        ],
        .recentFilesLimitNote: [
            .english: "This only affects the recent files list in the sidebar.",
            .chinese: "此設定只影響側邊欄的最近檔案清單。",
            .japanese: "この設定はサイドバーの最近使ったファイル一覧にのみ適用されます。",
            .korean: "이 설정은 사이드바의 최근 파일 목록에만 적용됩니다."
        ],
        .searchRecentFiles: [
            .english: "Search recent files",
            .chinese: "搜尋最近檔案",
            .japanese: "最近使ったファイルを検索",
            .korean: "최근 파일 검색"
        ],
        .clearSearch: [
            .english: "Clear search",
            .chinese: "清除搜尋",
            .japanese: "検索をクリア",
            .korean: "검색 지우기"
        ],
        .noRecentFiles: [
            .english: "No recent files",
            .chinese: "尚無最近檔案",
            .japanese: "最近使ったファイルはありません",
            .korean: "최근 파일이 없습니다"
        ],
        .noMatchingFiles: [
            .english: "No matching files",
            .chinese: "找不到符合的檔案",
            .japanese: "一致するファイルがありません",
            .korean: "일치하는 파일이 없습니다"
        ],
        .openFileHint: [
            .english: "Opened files will appear here.",
            .chinese: "開啟檔案後會列在這裡。",
            .japanese: "ファイルを開くとここに表示されます。",
            .korean: "파일을 열면 여기에 표시됩니다."
        ],
        .hideSidebar: [
            .english: "Hide sidebar",
            .chinese: "隱藏側邊欄",
            .japanese: "サイドバーを隠す",
            .korean: "사이드바 숨기기"
        ],
        .showSidebar: [
            .english: "Show sidebar",
            .chinese: "顯示側邊欄",
            .japanese: "サイドバーを表示",
            .korean: "사이드바 표시"
        ],
        .save: [
            .english: "Save",
            .chinese: "儲存",
            .japanese: "保存",
            .korean: "저장"
        ],
        .saveAs: [
            .english: "Save As…",
            .chinese: "另存新檔…",
            .japanese: "別名で保存…",
            .korean: "다른 이름으로 저장…"
        ],
        .newDocument: [
            .english: "New Document",
            .chinese: "新增文件",
            .japanese: "新規書類",
            .korean: "새 문서"
        ],
        .openMenu: [
            .english: "Open…",
            .chinese: "開啟…",
            .japanese: "開く…",
            .korean: "열기…"
        ],
        .openPrompt: [
            .english: "Open",
            .chinese: "開啟",
            .japanese: "開く",
            .korean: "열기"
        ],
        .savePrompt: [
            .english: "Save",
            .chinese: "儲存",
            .japanese: "保存",
            .korean: "저장"
        ],
        .fileOperationFailed: [
            .english: "File operation failed",
            .chinese: "檔案操作失敗",
            .japanese: "ファイル操作に失敗しました",
            .korean: "파일 작업 실패"
        ],
        .ok: [
            .english: "OK",
            .chinese: "好",
            .japanese: "OK",
            .korean: "확인"
        ],
        .edit: [
            .english: "Edit",
            .chinese: "編輯",
            .japanese: "編集",
            .korean: "편집"
        ],
        .preview: [
            .english: "Preview",
            .chinese: "預覽",
            .japanese: "プレビュー",
            .korean: "미리보기"
        ],
        .switchToEdit: [
            .english: "Switch to edit mode",
            .chinese: "切換至編輯模式",
            .japanese: "編集モードに切り替え",
            .korean: "편집 모드로 전환"
        ],
        .switchToPreview: [
            .english: "Switch to preview mode",
            .chinese: "切換至預覽模式",
            .japanese: "プレビューモードに切り替え",
            .korean: "미리보기 모드로 전환"
        ],
        .decreaseFontSize: [
            .english: "Decrease font size (⌘-)",
            .chinese: "縮小字型 (⌘-)",
            .japanese: "文字サイズを小さく (⌘-)",
            .korean: "글자 크기 줄이기 (⌘-)"
        ],
        .increaseFontSize: [
            .english: "Increase font size (⌘=)",
            .chinese: "放大字型 (⌘=)",
            .japanese: "文字サイズを大きく (⌘=)",
            .korean: "글자 크기 늘리기 (⌘=)"
        ],
        .saveShortcut: [
            .english: "Save (⌘S)",
            .chinese: "儲存 (⌘S)",
            .japanese: "保存 (⌘S)",
            .korean: "저장 (⌘S)"
        ],
        .untitledDocument: [
            .english: "Untitled",
            .chinese: "未命名",
            .japanese: "名称未設定",
            .korean: "제목 없음"
        ],
        .untitledFileName: [
            .english: "Untitled.md",
            .chinese: "未命名.md",
            .japanese: "名称未設定.md",
            .korean: "제목 없음.md"
        ],
        .unsavedChangesTitle: [
            .english: "Unsaved Changes",
            .chinese: "尚有未儲存的變更",
            .japanese: "未保存の変更があります",
            .korean: "저장하지 않은 변경 사항"
        ],
        .unsavedChangesMessage: [
            .english: "Would you like to save your changes before switching documents?",
            .chinese: "切換文件前要先儲存目前的內容嗎？",
            .japanese: "書類を切り替える前に変更を保存しますか？",
            .korean: "문서를 전환하기 전에 변경 사항을 저장할까요?"
        ],
        .discard: [
            .english: "Discard",
            .chinese: "不儲存",
            .japanese: "保存しない",
            .korean: "저장 안 함"
        ],
        .cancel: [
            .english: "Cancel",
            .chinese: "取消",
            .japanese: "キャンセル",
            .korean: "취소"
        ],
        .unknownTime: [
            .english: "Unknown time",
            .chinese: "時間未知",
            .japanese: "時刻不明",
            .korean: "시간 알 수 없음"
        ],
        .unknownSize: [
            .english: "Unknown size",
            .chinese: "大小未知",
            .japanese: "サイズ不明",
            .korean: "크기 알 수 없음"
        ]
    ]
}
