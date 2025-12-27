import Foundation

/// An inline element within a Markdown block.
///
/// Inline elements are the content within paragraphs and other blocks,
/// such as text, emphasis, links, and inline code.
public enum MarkdownInline: Sendable, Equatable {

    /// Plain text content.
    case text(String)

    /// Emphasized (italic) content.
    case emphasis([MarkdownInline])

    /// Strongly emphasized (bold) content.
    case strong([MarkdownInline])

    /// Inline code span.
    case code(String)

    /// A hyperlink.
    case link(destination: String, title: String?, content: [MarkdownInline])

    /// An image.
    case image(source: String, alt: String, title: String?)

    /// A soft line break (rendered as space or newline depending on context).
    case softBreak

    /// A hard line break (explicit line break).
    case hardBreak

    /// Strikethrough text (GFM extension).
    case strikethrough([MarkdownInline])
}
