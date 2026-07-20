import Foundation

/// swift-markdown パーシング前に数式領域を抽出し、パース後に AST ノードとして復元する。
///
/// `\(...\)` デリミターはバックスラッシュエスケープ処理で破壊され、`$a_b$` の添字は強調パーシングで消費されるため、Markdown パーシング前に数式を抽出する必要がある。各数式領域はプレースホルダートークン（cmark でもプレーンテキストとして残る私用領域文字）に置き換える。ディスプレイ数式は独立した段落に分離する。
enum MathPreprocessor {

    struct Capture: Equatable {
        let latex: String
        let isDisplay: Bool
        /// デリミターを含む元のソース断片。数式になり得ない位置（リンク宛先など）に
        /// トークンが落ちた場合に、原文をそのまま書き戻すために使う。
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
                processed += text
            case .math(let latex, let isDisplay, let raw):
                let token = "\(tokenStart)\(captures.count)\(tokenEnd)"
                captures.append(Capture(latex: latex, isDisplay: isDisplay, raw: raw))
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

    /// 数式になり得ない位置に落ちたトークンを、デリミター込みの原文へ書き戻す。
    ///
    /// スキャナは構文木を持たないため、リンク宛先や画像ソースの中の `$...$` も一律に
    /// 数式として拾う。そこを復元しないと、表示されているリンクと実際に開く先が食い違う。
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

    /// テキストランをプレースホルダートークンで分割し、テキストと数式インラインに変換する。
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

    /// インラインがディスプレイ数式プレースホルダー1つだけから成る（空白を除く）場合、そのキャプチャを返す。
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
