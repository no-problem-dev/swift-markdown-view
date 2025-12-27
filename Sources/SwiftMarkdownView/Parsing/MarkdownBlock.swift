import Foundation

/// A block-level element in a Markdown document.
///
/// Blocks are the top-level structural elements such as paragraphs,
/// headings, code blocks, and lists.
public enum MarkdownBlock: Sendable, Equatable {

    /// A paragraph containing inline content.
    case paragraph([MarkdownInline])

    /// A heading with a level (1-6) and inline content.
    case heading(level: Int, content: [MarkdownInline])

    /// A fenced or indented code block.
    case codeBlock(language: String?, code: String)

    /// A block quote containing nested blocks.
    case blockquote([MarkdownBlock])

    /// An unordered (bulleted) list.
    case unorderedList([ListItem])

    /// An ordered (numbered) list.
    case orderedList(start: Int, items: [ListItem])

    /// A thematic break (horizontal rule).
    case thematicBreak

    /// A table (GFM extension).
    case table(TableData)

    /// A Mermaid diagram block.
    ///
    /// Mermaid diagrams are fenced code blocks with `mermaid` as the language.
    /// They are rendered using Mermaid.js for visualization.
    case mermaid(String)
}

// MARK: - Table Types

/// Represents a complete table structure.
public struct TableData: Sendable, Equatable {

    /// The header row of the table.
    public let headerRow: TableRow

    /// The body rows of the table.
    public let bodyRows: [TableRow]

    /// The alignment for each column.
    public let columnAlignments: [TableAlignment]

    public init(
        headerRow: TableRow,
        bodyRows: [TableRow],
        columnAlignments: [TableAlignment]
    ) {
        self.headerRow = headerRow
        self.bodyRows = bodyRows
        self.columnAlignments = columnAlignments
    }
}

/// Represents a single row in a table.
public struct TableRow: Sendable, Equatable {

    /// The cells in this row.
    public let cells: [[MarkdownInline]]

    public init(cells: [[MarkdownInline]]) {
        self.cells = cells
    }
}

/// Column alignment options for tables.
public enum TableAlignment: Sendable, Equatable {
    case left
    case center
    case right
    case none
}

/// An item in a list, which can contain nested blocks.
public struct ListItem: Sendable, Equatable {

    /// The blocks contained in this list item.
    public let blocks: [MarkdownBlock]

    /// For task lists: whether the checkbox is checked.
    /// `nil` means this is not a task list item.
    public let isChecked: Bool?

    public init(blocks: [MarkdownBlock], isChecked: Bool? = nil) {
        self.blocks = blocks
        self.isChecked = isChecked
    }
}
