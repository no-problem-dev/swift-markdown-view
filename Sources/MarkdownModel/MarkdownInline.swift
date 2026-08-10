import Foundation

/// An inline element inside a Markdown block.
///
/// The content that sits within a paragraph or any other block: text, emphasis, links,
/// inline code, and so on.
public enum MarkdownInline: Sendable, Equatable {

    case text(String)

    /// Emphasized content, drawn in italic.
    case emphasis([MarkdownInline])

    /// Strongly emphasized content, drawn in bold.
    case strong([MarkdownInline])

    /// An inline code span, as opposed to a code block.
    case code(String)

    case link(destination: String, title: String?, content: [MarkdownInline])

    case image(source: String, alt: String, title: String?)

    /// A soft line break, drawn as a space or a newline depending on context.
    case softBreak

    /// An explicit line break.
    case hardBreak

    /// Struck-through text, from the GitHub Flavored Markdown extension.
    case strikethrough([MarkdownInline])

    /// Inline math holding LaTeX source, with the delimiters stripped.
    ///
    /// Produced by `$...$` (under the Pandoc rule) and by `\(...\)`. Rendering is left to the math renderer in the environment.
    case inlineMath(String)
}
