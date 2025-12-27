import SwiftUI
import DesignSystem

/// A SwiftUI view that renders syntax-highlighted code asynchronously.
///
/// This view uses the injected `SyntaxHighlighter` from the environment
/// to highlight code and display the result. It handles loading and
/// error states gracefully.
///
/// Example:
/// ```swift
/// HighlightedCodeView(code: swiftCode, language: "swift")
/// ```
///
/// To use a custom highlighter:
/// ```swift
/// HighlightedCodeView(code: swiftCode, language: "swift")
///     .syntaxHighlighter(HighlightJSSyntaxHighlighter())
/// ```
public struct HighlightedCodeView: View {

    /// The source code to highlight.
    public let code: String

    /// The programming language for syntax rules.
    public let language: String?

    @Environment(\.syntaxHighlighter) private var highlighter
    @Environment(\.colorPalette) private var colorPalette

    @State private var state: HighlightState = .idle

    /// Creates a highlighted code view.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight.
    ///   - language: The programming language (e.g., "swift", "python").
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
                .foregroundStyle(colorPalette.onSurface)

        case .success(let attributed):
            Text(attributed)

        case .failure:
            // Fallback to plain text on error
            Text(code)
                .foregroundStyle(colorPalette.onSurface)
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
    /// Hashable identifier for task invalidation.
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
