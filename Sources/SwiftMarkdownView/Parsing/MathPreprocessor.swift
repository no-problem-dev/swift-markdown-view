import Foundation

/// Extracts math regions before swift-markdown parsing and restores them
/// into AST nodes afterwards.
///
/// Math must be extracted *before* Markdown parsing: `\(...\)` delimiters
/// are destroyed by backslash-escape processing, and `$a_b$` subscripts
/// are eaten by emphasis parsing. Each math region is replaced by a
/// placeholder token (Private Use Area characters that survive cmark as
/// plain text); display math is isolated into its own paragraph.
enum MathPreprocessor {

    struct Capture: Equatable {
        let latex: String
        let isDisplay: Bool
    }

    struct Extraction {
        let processed: String
        let captures: [Capture]
    }

    private static let tokenStart: Character = "\u{E000}"
    private static let tokenEnd: Character = "\u{E001}"

    // MARK: - Extract

    static func extract(from source: String) -> Extraction {
        let parts = MathScanner.parts(in: source)
        guard parts.contains(where: { if case .math = $0 { true } else { false } }) else {
            return Extraction(processed: source, captures: [])
        }

        var processed = ""
        var captures: [Capture] = []
        for part in parts {
            switch part {
            case .text(let text):
                processed += text
            case .math(let latex, let isDisplay):
                let token = "\(tokenStart)\(captures.count)\(tokenEnd)"
                captures.append(Capture(latex: latex, isDisplay: isDisplay))
                // Display math becomes its own block; blank lines force a
                // standalone paragraph in the Markdown structure.
                processed += isDisplay ? "\n\n\(token)\n\n" : token
            }
        }
        return Extraction(processed: processed, captures: captures)
    }

    // MARK: - Restore

    static func restore(_ blocks: [MarkdownBlock], captures: [Capture]) -> [MarkdownBlock] {
        guard !captures.isEmpty else { return blocks }
        return blocks.flatMap { restoreBlock($0, captures: captures) }
    }

    private static func restoreBlock(_ block: MarkdownBlock, captures: [Capture]) -> [MarkdownBlock] {
        switch block {
        case .paragraph(let inlines):
            // A paragraph holding a single display-math token becomes a math block.
            if let capture = soleDisplayCapture(of: inlines, captures: captures) {
                return [.math(capture.latex)]
            }
            return [.paragraph(restoreInlines(inlines, captures: captures))]

        case .heading(let level, let content):
            return [.heading(level: level, content: restoreInlines(content, captures: captures))]

        case .aside(let kind, let content):
            return [.aside(kind: kind, content: restore(content, captures: captures))]

        case .unorderedList(let items):
            return [.unorderedList(items.map { restoreListItem($0, captures: captures) })]

        case .orderedList(let start, let items):
            return [.orderedList(start: start, items: items.map { restoreListItem($0, captures: captures) })]

        case .table(let data):
            return [.table(restoreTable(data, captures: captures))]

        case .codeBlock, .thematicBreak, .mermaid, .math:
            return [block]
        }
    }

    private static func restoreListItem(_ item: ListItem, captures: [Capture]) -> ListItem {
        ListItem(
            blocks: restore(item.blocks, captures: captures),
            isChecked: item.isChecked
        )
    }

    private static func restoreTable(_ data: TableData, captures: [Capture]) -> TableData {
        func restoreRow(_ row: TableRow) -> TableRow {
            TableRow(cells: row.cells.map { restoreInlines($0, captures: captures) })
        }
        return TableData(
            headerRow: restoreRow(data.headerRow),
            bodyRows: data.bodyRows.map(restoreRow),
            columnAlignments: data.columnAlignments
        )
    }

    private static func restoreInlines(_ inlines: [MarkdownInline], captures: [Capture]) -> [MarkdownInline] {
        inlines.flatMap { inline -> [MarkdownInline] in
            switch inline {
            case .text(let text):
                return splitText(text, captures: captures)

            case .emphasis(let children):
                return [.emphasis(restoreInlines(children, captures: captures))]

            case .strong(let children):
                return [.strong(restoreInlines(children, captures: captures))]

            case .link(let destination, let title, let content):
                return [.link(destination: destination, title: title, content: restoreInlines(content, captures: captures))]

            case .strikethrough(let children):
                return [.strikethrough(restoreInlines(children, captures: captures))]

            case .code, .image, .softBreak, .hardBreak, .inlineMath:
                return [inline]
            }
        }
    }

    /// Splits a text run at placeholder tokens into text and math inlines.
    private static func splitText(_ text: String, captures: [Capture]) -> [MarkdownInline] {
        guard text.contains(tokenStart) else { return [.text(text)] }

        var result: [MarkdownInline] = []
        var pending = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if character == tokenStart,
               let endIndex = text[index...].firstIndex(of: tokenEnd),
               let captureIndex = Int(text[text.index(after: index)..<endIndex]),
               captures.indices.contains(captureIndex) {
                if !pending.isEmpty {
                    result.append(.text(pending))
                    pending = ""
                }
                result.append(.inlineMath(captures[captureIndex].latex))
                index = text.index(after: endIndex)
            } else {
                pending.append(character)
                index = text.index(after: index)
            }
        }
        if !pending.isEmpty {
            result.append(.text(pending))
        }
        return result
    }

    /// Returns the capture if the inlines consist of exactly one
    /// display-math placeholder (ignoring whitespace).
    private static func soleDisplayCapture(of inlines: [MarkdownInline], captures: [Capture]) -> Capture? {
        var token: String?
        for inline in inlines {
            switch inline {
            case .text(let text):
                let trimmedText = text.trimmingCharacters(in: .whitespaces)
                if trimmedText.isEmpty { continue }
                guard token == nil else { return nil }
                token = trimmedText
            case .softBreak, .hardBreak:
                continue
            default:
                return nil
            }
        }
        guard
            let token,
            token.first == tokenStart, token.last == tokenEnd,
            let captureIndex = Int(token.dropFirst().dropLast()),
            captures.indices.contains(captureIndex),
            captures[captureIndex].isDisplay
        else {
            return nil
        }
        return captures[captureIndex]
    }
}
