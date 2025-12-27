import Foundation

/// A parsed Markdown document represented as a collection of blocks.
///
/// `MarkdownContent` is a value type that holds the parsed structure of a Markdown string.
/// It can be created once and reused for multiple renderings.
///
/// ```swift
/// let content = MarkdownContent(parsing: "# Hello **World**")
/// MarkdownView(content)
/// ```
public struct MarkdownContent: Sendable, Equatable {

    /// The block-level elements in this Markdown content.
    public let blocks: [MarkdownBlock]

    /// Creates a new MarkdownContent by parsing the given string.
    ///
    /// - Parameter source: The Markdown string to parse.
    public init(parsing source: String) {
        self.blocks = MarkdownParser.parse(source)
    }

    /// Creates a new MarkdownContent with the given blocks.
    ///
    /// - Parameter blocks: The block-level elements.
    internal init(blocks: [MarkdownBlock]) {
        self.blocks = blocks
    }
}
