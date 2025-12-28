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

    /// An aside (callout/admonition) containing nested blocks.
    ///
    /// Asides are interpreted from blockquotes with optional kind tags:
    /// - `> Note: This is a note` → `.aside(kind: .note, content: ...)`
    /// - `> Warning: Be careful` → `.aside(kind: .warning, content: ...)`
    /// - `> Regular quote` → `.aside(kind: .note, content: ...)` (default)
    case aside(kind: AsideKind, content: [MarkdownBlock])

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

// MARK: - Aside Types

/// The kind of aside (callout/admonition).
///
/// Asides are interpreted from blockquotes with a kind tag at the beginning.
/// For example, `> Note: This is important` creates a `.note` aside.
///
/// The kinds are based on swift-markdown's `Aside.Kind` and include
/// common documentation callout types.
public enum AsideKind: Sendable, Equatable, Hashable {
    // Common callouts
    case note
    case tip
    case important
    case warning
    case experiment

    // Additional callouts
    case attention
    case author
    case authors
    case bug
    case complexity
    case copyright
    case date
    case invariant
    case mutatingVariant
    case nonMutatingVariant
    case postcondition
    case precondition
    case remark
    case requires
    case since
    case todo
    case version
    case `throws`
    case seeAlso

    /// A custom aside kind for user-defined callouts.
    case custom(String)

    /// Human-readable display name for the aside kind.
    public var displayName: String {
        switch self {
        case .note: return "Note"
        case .tip: return "Tip"
        case .important: return "Important"
        case .warning: return "Warning"
        case .experiment: return "Experiment"
        case .attention: return "Attention"
        case .author: return "Author"
        case .authors: return "Authors"
        case .bug: return "Bug"
        case .complexity: return "Complexity"
        case .copyright: return "Copyright"
        case .date: return "Date"
        case .invariant: return "Invariant"
        case .mutatingVariant: return "Mutating Variant"
        case .nonMutatingVariant: return "Non-Mutating Variant"
        case .postcondition: return "Postcondition"
        case .precondition: return "Precondition"
        case .remark: return "Remark"
        case .requires: return "Requires"
        case .since: return "Since"
        case .todo: return "To Do"
        case .version: return "Version"
        case .throws: return "Throws"
        case .seeAlso: return "See Also"
        case .custom(let name): return name
        }
    }

    /// Creates an aside kind from a raw string value.
    ///
    /// The matching is case-insensitive.
    ///
    /// - Parameter rawValue: The string tag from the blockquote.
    public init(rawValue: String) {
        switch rawValue.lowercased() {
        case "note": self = .note
        case "tip": self = .tip
        case "important": self = .important
        case "warning": self = .warning
        case "experiment": self = .experiment
        case "attention": self = .attention
        case "author": self = .author
        case "authors": self = .authors
        case "bug": self = .bug
        case "complexity": self = .complexity
        case "copyright": self = .copyright
        case "date": self = .date
        case "invariant": self = .invariant
        case "mutatingvariant": self = .mutatingVariant
        case "nonmutatingvariant": self = .nonMutatingVariant
        case "postcondition": self = .postcondition
        case "precondition": self = .precondition
        case "remark": self = .remark
        case "requires": self = .requires
        case "since": self = .since
        case "todo": self = .todo
        case "version": self = .version
        case "throws": self = .throws
        case "seealso": self = .seeAlso
        default: self = .custom(rawValue)
        }
    }
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
