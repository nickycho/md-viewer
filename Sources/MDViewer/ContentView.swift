import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var viewModel: MarkdownViewModel

    init(document: Binding<MarkdownDocument>) {
        self._document = document
        self._viewModel = State(
            initialValue: MarkdownViewModel(initialMarkdown: document.wrappedValue.text)
        )
    }

    var body: some View {
        Group {
            if viewModel.showPreview {
                MarkdownWebView(html: viewModel.renderedHTML, fontSize: viewModel.fontSize)
            } else {
                TextEditor(text: $document.text)
                    .font(.system(size: viewModel.fontSize, design: .monospaced))
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
            ToolbarItem(placement: .primaryAction) {
                Button { viewModel.decreaseFontSize() } label: {
                    Image(systemName: "textformat.size.smaller")
                }
                .help("縮小字型 (⌘-)")
                .keyboardShortcut("-", modifiers: .command)
                .disabled(viewModel.fontSize <= 10)
            }
            ToolbarItem(placement: .primaryAction) {
                Button { viewModel.increaseFontSize() } label: {
                    Image(systemName: "textformat.size.larger")
                }
                .help("增大字型 (⌘=)")
                .keyboardShortcut("=", modifiers: .command)
                .disabled(viewModel.fontSize >= 32)
            }
        }
        .navigationTitle("")
    }
}
