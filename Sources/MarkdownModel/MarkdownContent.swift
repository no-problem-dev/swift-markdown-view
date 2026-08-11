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

    /// Whether the document holds any math, display or inline, at any depth.
    ///
    /// A math renderer turns each formula into a bitmap with its color already baked in, so a
    /// document that has math is one whose drawing does not follow a change of appearance on its
    /// own. Renderers use this to decide whether an appearance change has to be acted on at all.
    public var containsMath: Bool {
        blocks.contains(where: Self.containsMath)
    }

    private static func containsMath(_ block: MarkdownBlock) -> Bool {
        switch block {
        case .math:
            return true
        case .paragraph(let inlines), .heading(_, let inlines):
            return inlines.contains(where: containsMath)
        case .aside(_, let content):
            return content.contains(where: containsMath)
        case .unorderedList(let items):
            return items.contains { $0.blocks.contains(where: containsMath) }
        case .orderedList(_, let items):
            return items.contains { $0.blocks.contains(where: containsMath) }
        case .table(let data):
            return ([data.headerRow] + data.bodyRows).contains { row in
                row.cells.contains { $0.contains(where: containsMath) }
            }
        case .codeBlock, .thematicBreak, .mermaid:
            return false
        }
    }

    private static func containsMath(_ inline: MarkdownInline) -> Bool {
        switch inline {
        case .inlineMath:
            return true
        case .emphasis(let children), .strong(let children), .strikethrough(let children):
            return children.contains(where: containsMath)
        case .link(_, _, let content):
            return content.contains(where: containsMath)
        case .text, .code, .image, .hardBreak, .softBreak:
            return false
        }
    }
}
