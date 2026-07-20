import SwiftMarkdownView
import SwiftUI
import DesignSystem

/// シンタックスハイライト付きでコードスニペットを表示する View。
///
/// クリップボードへのコピーボタンを内蔵する。
public struct CodeSnippetView: View {

    /// 表示するコード。
    public let code: String

    /// シンタックスハイライトに使用するプログラミング言語名。
    public let language: String

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    @State private var copied = false

    /// コードスニペット View を作成する。
    ///
    /// - Parameters:
    ///   - code: 表示するコード。
    ///   - language: プログラミング言語名。デフォルトは "swift"。
    public init(code: String, language: String = "swift") {
        self.code = code
        self.language = language
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language label and copy button
            HStack {
                Text(language)
                    .typography(.labelSmall)
                    .foregroundStyle(colorPalette.onSurfaceVariant)

                Spacer()

                Button {
                    copyToClipboard()
                } label: {
                    Label(
                        copied ? "コピー済み" : "コピー",
                        systemImage: copied ? "checkmark" : "doc.on.doc"
                    )
                    .typography(.labelSmall)
                }
                .buttonStyle(.plain)
                .foregroundStyle(copied ? colorPalette.primary : colorPalette.onSurfaceVariant)
            }
            .padding(.horizontal, spacing.md)
            .padding(.vertical, spacing.sm)
            .background(colorPalette.surfaceVariant.opacity(0.7))

            // Code content with syntax highlighting
            ScrollView(.horizontal, showsIndicators: false) {
                HighlightedCodeView(code: code, language: language)
            }
            .padding(spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorPalette.surfaceVariant)
        }
        .clipShape(RoundedRectangle(cornerRadius: radius.md))
    }

    private func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = code
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        #endif

        withAnimation {
            copied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copied = false
            }
        }
    }
}

#Preview {
    CodeSnippetView(
        code: """
        MarkdownView("# Hello World")
            .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter())
        """,
        language: "swift"
    )
    .padding()
    .theme(ThemeProvider())
}
