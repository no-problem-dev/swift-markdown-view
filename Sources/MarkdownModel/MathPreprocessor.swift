import Foundation

/// Lifts math regions out before swift-markdown parses, and puts them back as AST nodes after.
///
/// Math has to come out first: backslash-escape handling destroys the `\(...\)` delimiters, and
/// emphasis parsing consumes the subscript in `$a_b$`. Each region is replaced by a placeholder
/// token built from private-use characters, which cmark leaves alone as plain text.
///
/// Splitting display math into a block of its own is the job of the **restore** side. Inserting
/// blank lines during extraction would terminate whatever list item or quote encloses the math.
/// Restore works from the AST, so it can split the inside of a paragraph and nothing else.
enum MathPreprocessor {

    struct Capture: Equatable {
        let latex: String
        let isDisplay: Bool
        /// The original source fragment, delimiters included.
        ///
        /// Written back verbatim when a token lands somewhere that cannot hold math, such as a
        /// link destination.
        let raw: String
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
                // Drop token characters that came from the source. Left in, restore would read
                // them as math placeholders, letting untrusted input (LLM output, user posts)
                // conjure extra math. U+E000/U+E001 are private-use and carry no Markdown
                // meaning, so removing them is harmless.
                processed += sanitized(text)
            case .math(let latex, let isDisplay, let raw):
                let token = "\(tokenStart)\(captures.count)\(tokenEnd)"
                captures.append(Capture(latex: latex, isDisplay: isDisplay, raw: raw))
                // Display math gets a bare token here too. Inserting blank lines to split it
                // into a block would terminate not just the paragraph but the enclosing list
                // item, quote, or table (`- item $$a$$ more` broke the list). Restore does the
                // splitting, where the structure is known.
                processed += token
            }
        }
        return Extraction(processed: processed, captures: captures)
    }

    private static func sanitized(_ text: String) -> String {
        guard text.contains(tokenStart) || text.contains(tokenEnd) else { return text }
        return text.filter { $0 != tokenStart && $0 != tokenEnd }
    }

    // MARK: - Restore

    static func restore(_ blocks: [MarkdownBlock], captures: [Capture]) -> [MarkdownBlock] {
        guard !captures.isEmpty else { return blocks }
        return blocks.flatMap { restoreBlock($0, captures: captures) }
    }

    private static func restoreBlock(_ block: MarkdownBlock, captures: [Capture]) -> [MarkdownBlock] {
        switch block {
        case .paragraph(let inlines):
            return splitParagraph(inlines, captures: captures)

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

    /// Splits a paragraph at each display math token, lifting the math into a block of its own.
    ///
    /// The split runs on the AST. Inserting blank lines during extraction would instead
    /// terminate the enclosing list item or quote and break the structure. Splitting only the
    /// inside of the paragraph keeps math that sits in a list item inside that item.
    private static func splitParagraph(_ inlines: [MarkdownInline], captures: [Capture]) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var pending: [MarkdownInline] = []

        func flushParagraph() {
            let restored = restoreInlines(pending, captures: captures)
            pending = []
            let hasContent = restored.contains { inline in
                if case .text(let text) = inline { return !text.allSatisfy(\.isWhitespace) }
                return true
            }
            if hasContent {
                blocks.append(.paragraph(restored))
            }
        }

        for inline in inlines {
            guard case .text(let text) = inline, text.contains(tokenStart) else {
                pending.append(inline)
                continue
            }
            for piece in splitOnDisplayTokens(text, captures: captures) {
                switch piece {
                case .text(let run):
                    pending.append(.text(run))
                case .display(let latex):
                    flushParagraph()
                    blocks.append(.math(latex))
                }
            }
        }
        flushParagraph()
        return blocks
    }

    private enum ParagraphPiece {
        case text(String)
        case display(String)
    }

    /// Cuts a text run at each display math token.
    ///
    /// Inline math tokens are left in place for ``restoreInlines`` to deal with.
    private static func splitOnDisplayTokens(_ text: String, captures: [Capture]) -> [ParagraphPiece] {
        var pieces: [ParagraphPiece] = []
        var pending = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if character == tokenStart,
               let endIndex = text[index...].firstIndex(of: tokenEnd),
               let captureIndex = Int(text[text.index(after: index)..<endIndex]),
               captures.indices.contains(captureIndex),
               captures[captureIndex].isDisplay {
                if !pending.isEmpty {
                    pieces.append(.text(pending))
                    pending = ""
                }
                pieces.append(.display(captures[captureIndex].latex))
                index = text.index(after: endIndex)
            } else {
                pending.append(character)
                index = text.index(after: index)
            }
        }
        if !pending.isEmpty {
            pieces.append(.text(pending))
        }
        return pieces
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
                return [.link(
                    destination: restoreRawText(destination, captures: captures),
                    title: title.map { restoreRawText($0, captures: captures) },
                    content: restoreInlines(content, captures: captures)
                )]

            case .image(let source, let alt, let title):
                return [.image(
                    source: restoreRawText(source, captures: captures),
                    alt: restoreRawText(alt, captures: captures),
                    title: title.map { restoreRawText($0, captures: captures) }
                )]

            case .strikethrough(let children):
                return [.strikethrough(restoreInlines(children, captures: captures))]

            case .code, .softBreak, .hardBreak, .inlineMath:
                return [inline]
            }
        }
    }

    /// Restores tokens that landed where math cannot go, delimiters and all.
    ///
    /// The scanner has no syntax tree, so it picks up `$...$` inside a link destination or an
    /// image source just as readily as anywhere else. Without this, the link on screen and the
    /// link that actually opens would differ.
    private static func restoreRawText(_ text: String, captures: [Capture]) -> String {
        guard text.contains(tokenStart) else { return text }

        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if character == tokenStart,
               let endIndex = text[index...].firstIndex(of: tokenEnd),
               let captureIndex = Int(text[text.index(after: index)..<endIndex]),
               captures.indices.contains(captureIndex) {
                result += captures[captureIndex].raw
                index = text.index(after: endIndex)
            } else {
                result.append(character)
                index = text.index(after: index)
            }
        }
        return result
    }

    /// Splits a text run at its placeholder tokens, yielding text and inline math elements.
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
}
