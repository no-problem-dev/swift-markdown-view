import SwiftUI

/// A plain text highlighter that applies no syntax highlighting.
///
/// This is the default highlighter. It simply returns the code as plain text
/// without any color formatting. Use this when:
/// - You want minimal styling for code blocks
/// - Syntax highlighting is not needed
/// - You prefer to let users opt-in to highlighting
///
/// To enable syntax highlighting, inject a custom highlighter:
///
/// ```swift
/// import SwiftMarkdownViewHighlightJS
///
/// MarkdownView(source)
///     .syntaxHighlighter(HighlightJSSyntaxHighlighter())
///
/// // Or use adaptive highlighting for automatic light/dark support
/// MarkdownView(source)
///     .adaptiveSyntaxHighlighting()
/// ```
public struct PlainTextHighlighter: SyntaxHighlighter, Sendable {

    /// Creates a plain text highlighter.
    public init() {}

    public func highlight(_ code: String, language: String?) async throws -> AttributedString {
        AttributedString(code)
    }
}
