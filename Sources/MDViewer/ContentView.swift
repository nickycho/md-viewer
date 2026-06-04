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
