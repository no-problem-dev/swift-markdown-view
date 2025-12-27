import Foundation
import Markdown

/// Internal parser that converts swift-markdown AST to our domain types.
///
/// This parser uses Apple's swift-markdown library to parse Markdown strings
/// and converts the resulting AST into our `MarkdownBlock` and `MarkdownInline` types.
enum MarkdownParser {

    /// Parses a Markdown string into an array of blocks.
    ///
    /// - Parameter source: The Markdown string to parse.
    /// - Returns: An array of `MarkdownBlock` representing the parsed content.
    static func parse(_ source: String) -> [MarkdownBlock] {
        let document = Document(parsing: source)
        return document.children.compactMap { convertBlock($0) }
    }

    // MARK: - Block Conversion

    private static func convertBlock(_ markup: any Markup) -> MarkdownBlock? {
        switch markup {
        case let paragraph as Markdown.Paragraph:
            let inlines = paragraph.children.compactMap { convertInline($0) }
            // Skip empty paragraphs (whitespace-only)
            if inlines.isEmpty || inlines.allSatisfy({ isWhitespaceOnly($0) }) {
                return nil
            }
            return .paragraph(inlines)

        case let heading as Markdown.Heading:
            let inlines = heading.children.compactMap { convertInline($0) }
            return .heading(level: heading.level, content: inlines)

        case let codeBlock as Markdown.CodeBlock:
            // Check if this is a Mermaid diagram
            if codeBlock.language?.lowercased() == "mermaid" {
                return .mermaid(codeBlock.code)
            }
            return .codeBlock(language: codeBlock.language, code: codeBlock.code)

        case let blockQuote as Markdown.BlockQuote:
            return convertBlockQuoteToAside(blockQuote)

        case let unorderedList as Markdown.UnorderedList:
            let items = unorderedList.children.compactMap { convertListItem($0) }
            return .unorderedList(items)

        case let orderedList as Markdown.OrderedList:
            let items = orderedList.children.compactMap { convertListItem($0) }
            return .orderedList(start: Int(orderedList.startIndex), items: items)

        case is Markdown.ThematicBreak:
            return .thematicBreak

        case let table as Markdown.Table:
            return convertTable(table)

        default:
            // Unsupported block types are skipped
            return nil
        }
    }

    // MARK: - Table Conversion

    private static func convertTable(_ table: Markdown.Table) -> MarkdownBlock? {
        // Extract column alignments
        let alignments = table.columnAlignments.map { convertAlignment($0) }

        // Extract header row - Table.Head contains cells directly (it IS the header row)
        let headerCells = table.head.children.compactMap { child -> [MarkdownInline]? in
            guard let cell = child as? Markdown.Table.Cell else { return nil }
            return cell.children.compactMap { convertInline($0) }
        }
        let headerRow = TableRow(cells: headerCells)

        // Extract body rows - Table.Body contains Table.Row elements
        let bodyRows = table.body.children.compactMap { child -> TableRow? in
            guard let row = child as? Markdown.Table.Row else { return nil }
            return convertTableRow(row)
        }

        return .table(TableData(
            headerRow: headerRow,
            bodyRows: bodyRows,
            columnAlignments: alignments
        ))
    }

    private static func convertTableRow(_ row: Markdown.Table.Row) -> TableRow {
        let cells = row.children.compactMap { child -> [MarkdownInline]? in
            guard let cell = child as? Markdown.Table.Cell else { return nil }
            return cell.children.compactMap { convertInline($0) }
        }
        return TableRow(cells: cells)
    }

    private static func convertAlignment(_ alignment: Markdown.Table.ColumnAlignment?) -> TableAlignment {
        switch alignment {
        case .left:
            return .left
        case .center:
            return .center
        case .right:
            return .right
        case nil:
            return .none
        }
    }

    private static func convertListItem(_ markup: any Markup) -> ListItem? {
        guard let listItem = markup as? Markdown.ListItem else { return nil }

        let blocks = listItem.children.compactMap { convertBlock($0) }
        let isChecked: Bool? = listItem.checkbox.map { $0 == .checked }

        return ListItem(blocks: blocks, isChecked: isChecked)
    }

    // MARK: - Inline Conversion

    private static func convertInline(_ markup: any Markup) -> MarkdownInline? {
        switch markup {
        case let text as Markdown.Text:
            return .text(text.string)

        case let emphasis as Markdown.Emphasis:
            let children = emphasis.children.compactMap { convertInline($0) }
            return .emphasis(children)

        case let strong as Markdown.Strong:
            let children = strong.children.compactMap { convertInline($0) }
            return .strong(children)

        case let inlineCode as Markdown.InlineCode:
            return .code(inlineCode.code)

        case let link as Markdown.Link:
            let children = link.children.compactMap { convertInline($0) }
            return .link(
                destination: link.destination ?? "",
                title: link.title,
                content: children
            )

        case let image as Markdown.Image:
            return .image(
                source: image.source ?? "",
                alt: image.plainText,
                title: image.title
            )

        case is Markdown.SoftBreak:
            return .softBreak

        case is Markdown.LineBreak:
            return .hardBreak

        case let strikethrough as Markdown.Strikethrough:
            let children = strikethrough.children.compactMap { convertInline($0) }
            return .strikethrough(children)

        default:
            // Unsupported inline types are skipped
            return nil
        }
    }

    // MARK: - Aside Conversion

    /// Converts a BlockQuote to an Aside using swift-markdown's Aside interpretation.
    ///
    /// This uses swift-markdown's `Aside` struct to detect aside tags like
    /// `> Note:`, `> Warning:`, etc. and extract the kind and content.
    ///
    /// - Parameter blockQuote: The blockquote to convert.
    /// - Returns: An aside block with the detected kind and content.
    private static func convertBlockQuoteToAside(_ blockQuote: Markdown.BlockQuote) -> MarkdownBlock {
        // Use swift-markdown's Aside to interpret the blockquote
        let aside = Aside(blockQuote)

        // Convert the Aside.Kind to our AsideKind
        let asideKind = AsideKind(rawValue: aside.kind.rawValue)

        // Convert the content blocks
        let contentBlocks = aside.content.compactMap { blockMarkup -> MarkdownBlock? in
            convertBlock(blockMarkup)
        }

        return .aside(kind: asideKind, content: contentBlocks)
    }

    // MARK: - Helpers

    private static func isWhitespaceOnly(_ inline: MarkdownInline) -> Bool {
        switch inline {
        case .text(let text):
            return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .softBreak, .hardBreak:
            return true
        default:
            return false
        }
    }
}
