import SwiftUI

/// A type that can highlight source code asynchronously.
///
/// An implementation takes source code and produces an `AttributedString` carrying the syntax
/// colors.
///
/// The default implementation, ``PlainTextHighlighter``, adds no color. For real highlighting,
/// use the `SwiftMarkdownViewHighlightJS` module:
///
/// ```swift
/// import SwiftMarkdownViewHighlightJS
///
/// MarkdownView(source)
///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter())
///
/// // Or highlight adaptively
/// MarkdownView(source)
///     .adaptiveSyntaxHighlighting()   // requires import SwiftMarkdownViewHighlightJS
/// ```
public protocol SyntaxHighlighter: Sendable {
    /// Highlights the given source code.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight.
    ///   - language: The programming language, such as `"swift"` or `"python"`. When it is `nil`,
    ///               a highlighter may try to detect the language itself.
    func highlight(_ code: String, language: String?) async throws -> AttributedString
}

// MARK: - Environment Key

private struct SyntaxHighlighterKey: EnvironmentKey {
    static let defaultValue: any SyntaxHighlighter = PlainTextHighlighter()
}

extension EnvironmentValues {
    /// The highlighter used for code blocks.
    ///
    /// Inject a custom highlighter into the view hierarchy with:
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownSyntaxHighlighter(CustomHighlighter())
    /// ```
    public var syntaxHighlighter: any SyntaxHighlighter {
        get { self[SyntaxHighlighterKey.self] }
        set { self[SyntaxHighlighterKey.self] = newValue }
    }
}

// MARK: - View Modifier

extension View {
    /// Sets the highlighter used for code blocks in this view hierarchy.
    ///
    /// Without it, ``PlainTextHighlighter`` renders code with no color. Use this modifier to turn
    /// highlighting on:
    ///
    /// ```swift
    /// import SwiftMarkdownViewHighlightJS
    ///
    /// MarkdownView(source)
    ///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter())
    /// ```
    ///
    /// - Parameter highlighter: The highlighter to use.
    public func markdownSyntaxHighlighter(_ highlighter: some SyntaxHighlighter) -> some View {
        environment(\.syntaxHighlighter, highlighter)
    }

}
