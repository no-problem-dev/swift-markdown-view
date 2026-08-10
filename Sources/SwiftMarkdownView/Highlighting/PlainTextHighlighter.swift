import SwiftUI

/// A highlighter that applies no coloring at all.
///
/// This is the default highlighter: it hands the code back as plain text. Use it when you want
/// code blocks styled minimally, when syntax highlighting is unnecessary, or when highlighting
/// should be something the app opts into.
///
/// To turn highlighting on, inject a different highlighter:
///
/// ```swift
/// import SwiftMarkdownViewHighlightJS
///
/// MarkdownView(source)
///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter())
///
/// // Or highlight adaptively, following the light and dark appearance
/// MarkdownView(source)
///     .adaptiveSyntaxHighlighting()   // requires import SwiftMarkdownViewHighlightJS
/// ```
public struct PlainTextHighlighter: SyntaxHighlighter, Sendable {

    public init() {}

    /// Returns the code unchanged, with no attributes applied.
    ///
    /// - Parameters:
    ///   - code: The source code.
    ///   - language: Ignored by this highlighter.
    public func highlight(_ code: String, language: String?) async throws -> AttributedString {
        AttributedString(code)
    }
}
