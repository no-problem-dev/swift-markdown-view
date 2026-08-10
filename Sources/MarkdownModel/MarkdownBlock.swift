import Foundation

/// A block-level element of a Markdown document.
///
/// Paragraphs, headings, code blocks, lists, and the other pieces that make up the
/// top-level structure of a document.
public enum MarkdownBlock: Sendable, Equatable {

    case paragraph([MarkdownInline])

    /// A heading, whose level runs from 1 through 6.
    case heading(level: Int, content: [MarkdownInline])

    /// A code block, written either as a fence or as an indented block.
    case codeBlock(language: String?, code: String)

    /// A callout, also known as an admonition, holding nested blocks.
    ///
    /// A block quote becomes an aside, with an optional kind tag on its first line:
    /// - `> Note: This is a note` → `.aside(kind: .note, content: ...)`
    /// - `> Warning: Be careful` → `.aside(kind: .warning, content: ...)`
    /// - `> Regular quote` → `.aside(kind: .note, content: ...)` (the default)
    case aside(kind: AsideKind, content: [MarkdownBlock])

    case unorderedList([ListItem])

    /// A numbered list, whose first item takes the given start number.
    case orderedList(start: Int, items: [ListItem])

    /// A thematic break, drawn as a horizontal rule.
    case thematicBreak

    /// A table, from the GitHub Flavored Markdown extension.
    case table(TableData)

    /// A Mermaid diagram.
    ///
    /// Produced by a fenced code block whose language is `mermaid`, and drawn with Mermaid.js.
    case mermaid(String)

    /// A display math block holding LaTeX source, with the delimiters stripped.
    ///
    /// Produced by `$$...$$`, `\[...\]`, or a fenced `math` code block. Rendering is left to the math renderer in the environment.
    case math(String)
}

// MARK: - Aside Types

/// The kind of a callout.
///
/// The kind comes from a tag at the start of the block quote. For example,
/// `> Note: This is important` becomes a `.note` aside.
///
/// The cases follow swift-markdown's `Aside.Kind` and cover the callout kinds
/// documentation commonly uses.
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

    /// A tag that matches none of the known kinds.
    ///
    /// The associated value is the tag text exactly as it was written in the source.
    case custom(String)

    /// A human-readable label for the kind.
    ///
    /// A custom kind gives back its tag text unchanged.
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

    /// Creates a kind from the tag text of a block quote.
    ///
    /// Matching ignores case. Text that matches no known kind becomes a custom kind.
    ///
    /// - Parameter rawValue: The tag text taken from the block quote.
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

/// The header row, body rows, and column alignments that make up a table.
public struct TableData: Sendable, Equatable {

    public let headerRow: TableRow

    public let bodyRows: [TableRow]

    /// The alignment of each column, in column order.
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

public struct TableRow: Sendable, Equatable {

    /// The cells of the row, each one holding its own inline content.
    public let cells: [[MarkdownInline]]

    public init(cells: [[MarkdownInline]]) {
        self.cells = cells
    }
}

public enum TableAlignment: Sendable, Equatable {
    case left
    case center
    case right
    case none
}

/// A list item, which holds nested blocks rather than plain text.
public struct ListItem: Sendable, Equatable {

    public let blocks: [MarkdownBlock]

    /// The checkbox state of a task list item, or `nil` when the item has no checkbox.
    public let isChecked: Bool?

    public init(blocks: [MarkdownBlock], isChecked: Bool? = nil) {
        self.blocks = blocks
        self.isChecked = isChecked
    }
}
