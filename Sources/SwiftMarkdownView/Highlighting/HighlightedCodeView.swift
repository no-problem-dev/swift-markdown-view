import SwiftUI

/// A SwiftUI view that renders source code with syntax highlighting applied asynchronously.
///
/// Highlighting runs through the ``SyntaxHighlighter`` injected into the environment. While the
/// work is in flight, and again if it fails, the code is shown as unstyled text, so the view
/// never goes blank.
///
/// Example:
/// ```swift
/// HighlightedCodeView(code: swiftCode, language: "swift")
/// ```
///
/// With a custom highlighter:
/// ```swift
/// HighlightedCodeView(code: swiftCode, language: "swift")
///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter())
/// ```
public struct HighlightedCodeView: View {

    public let code: String

    /// The language whose syntax rules apply, or `nil` to let the highlighter detect it.
    public let language: String?

    @Environment(\.syntaxHighlighter) private var highlighter
    @Environment(\.markdownPalette) private var palette

    @State private var state: HighlightState = .idle

    /// Creates a view that highlights the given code.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight.
    ///   - language: The programming language, such as `"swift"` or `"python"`.
    public init(code: String, language: String?) {
        self.code = code
        self.language = language
    }

    public var body: some View {
        content
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .task(id: TaskIdentifier(code: code, language: language)) {
                await performHighlighting()
            }
    }

    // MARK: - Private

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            // Show plain text during loading for smooth transition
            Text(code)
                .foregroundStyle(palette.text)

        case .success(let attributed):
            Text(attributed)

        case .failure:
            // Fallback to plain text on error
            Text(code)
                .foregroundStyle(palette.text)
        }
    }

    private func performHighlighting() async {
        state = .loading

        do {
            let result = try await highlighter.highlight(code, language: language)
            state = .success(result)
        } catch {
            state = .failure(error)
        }
    }
}

// MARK: - Task Identifier

extension HighlightedCodeView {
    /// Identifies the highlighting task so that a new code or language value restarts it.
    private struct TaskIdentifier: Hashable {
        let code: String
        let language: String?
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Swift Code") {
    HighlightedCodeView(
        code: """
        func greet(_ name: String) -> String {
            return "Hello, \\(name)!"
        }

        let message = greet("World")
        print(message)
        """,
        language: "swift"
    )
    .padding()
}

#Preview("Python Code") {
    HighlightedCodeView(
        code: """
        def greet(name: str) -> str:
            return f"Hello, {name}!"

        message = greet("World")
        print(message)
        """,
        language: "python"
    )
    .padding()
}
#endif
