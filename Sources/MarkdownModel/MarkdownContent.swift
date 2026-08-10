import Foundation

/// A parsed Markdown document, held as a collection of blocks.
///
/// Parsing happens once, when the value is created, so a single value can be reused
/// across as many renders as you like.
///
/// ```swift
/// let content = MarkdownContent(parsing: "# Hello **World**")
/// MarkdownView(content)
/// ```
public struct MarkdownContent: Sendable, Equatable {

    public let blocks: [MarkdownBlock]

    /// Creates a document by parsing a Markdown string.
    ///
    /// - Parameter source: The Markdown text to parse.
    public init(parsing source: String) {
        self.blocks = MarkdownParser.parse(source)
    }

    /// Creates a document from blocks you already have.
    ///
    /// Use it to reshape a parse before rendering: to demote every heading by one level,
    /// to swap out particular blocks, or to concatenate several documents.
    ///
    /// ```swift
    /// let parsed = MarkdownContent(parsing: source)
    /// let withoutImages = MarkdownContent(blocks: parsed.blocks.filter { block in
    ///     if case .paragraph(let inlines) = block, inlines.count == 1,
    ///        case .image = inlines[0] { return false }
    ///     return true
    /// })
    /// MarkdownView(withoutImages)
    /// ```
    ///
    /// - Parameter blocks: The block-level elements of the document.
    public init(blocks: [MarkdownBlock]) {
        self.blocks = blocks
    }
}
