import SwiftUI
import DesignSystem

/// A view for displaying Swift code snippets with syntax highlighting.
///
/// Includes a copy button for easy clipboard access.
public struct CodeSnippetView: View {

    /// The code to display.
    public let code: String

    /// The programming language for syntax highlighting.
    public let language: String

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    @State private var copied = false

    /// Creates a new code snippet view.
    ///
    /// - Parameters:
    ///   - code: The code to display.
    ///   - language: The programming language. Defaults to "swift".
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
            .headingStyle(ColoredHeadingStyle())
        """,
        language: "swift"
    )
    .padding()
    .theme(ThemeProvider())
}
