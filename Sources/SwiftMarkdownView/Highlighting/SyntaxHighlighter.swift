import SwiftUI

/// A type that can highlight source code asynchronously.
///
/// Implementations of this protocol take source code and produce
/// an `AttributedString` with syntax highlighting applied.
///
/// Example:
/// ```swift
/// let highlighter = RegexSyntaxHighlighter()
/// let highlighted = try await highlighter.highlight(code, language: "swift")
/// ```
public protocol SyntaxHighlighter: Sendable {
    /// Highlights the given source code.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight.
    ///   - language: The programming language (e.g., "swift", "python").
    ///               If nil, the highlighter may attempt auto-detection.
    /// - Returns: An `AttributedString` with syntax highlighting applied.
    /// - Throws: An error if highlighting fails.
    func highlight(_ code: String, language: String?) async throws -> AttributedString
}

// MARK: - Environment Key

/// Environment key for injecting a custom syntax highlighter.
private struct SyntaxHighlighterKey: EnvironmentKey {
    static let defaultValue: any SyntaxHighlighter = RegexSyntaxHighlighter()
}

extension EnvironmentValues {
    /// The syntax highlighter used for code highlighting.
    ///
    /// Use this to inject a custom highlighter into the view hierarchy:
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .syntaxHighlighter(CustomHighlighter())
    /// ```
    public var syntaxHighlighter: any SyntaxHighlighter {
        get { self[SyntaxHighlighterKey.self] }
        set { self[SyntaxHighlighterKey.self] = newValue }
    }
}

// MARK: - View Modifier

extension View {
    /// Sets a custom syntax highlighter for code highlighting.
    ///
    /// - Parameter highlighter: The highlighter to use.
    /// - Returns: A view with the custom highlighter applied.
    ///
    /// Example:
    /// ```swift
    /// MarkdownView(source)
    ///     .syntaxHighlighter(HighlightJSSyntaxHighlighter())
    /// ```
    public func syntaxHighlighter(_ highlighter: some SyntaxHighlighter) -> some View {
        environment(\.syntaxHighlighter, highlighter)
    }
}
