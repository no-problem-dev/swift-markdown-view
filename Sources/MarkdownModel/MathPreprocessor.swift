import Foundation

/// swift-markdown パーシング前に数式領域を抽出し、パース後に AST ノードとして復元する。
///
/// `\(...\)` デリミターはバックスラッシュエスケープ処理で破壊され、`$a_b$` の添字は強調パーシングで消費されるため、Markdown パーシング前に数式を抽出する必要がある。各数式領域はプレースホルダートークン（cmark でもプレーンテキストとして残る私用領域文字）に置き換える。
///
/// ディスプレイ数式を独立したブロックへ切り出すのは**復元側**の仕事。抽出時に空行を挿すと、
/// その数式を包んでいるリスト項目や引用ごと打ち切ってしまう。復元側は AST を見ているので、
/// 段落の内側だけを分けられる。
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
                // ソース由来のトークン文字を落とす。残すと復元時に数式プレースホルダーとして
                // 解釈され、外部入力（LLM 出力・ユーザー投稿）で数式が増殖する。
                // U+E000/U+E001 は私用領域で Markdown 上の意味を持たないため、除去して差し支えない。
                processed += sanitized(text)
            case .math(let latex, let isDisplay, let raw):
                let token = "\(tokenStart)\(captures.count)\(tokenEnd)"
                captures.append(Capture(latex: latex, isDisplay: isDisplay, raw: raw))
                // ディスプレイ数式もここでは素のトークンとして埋める。
                // 空行を挿してブロックに切り出すと、段落だけでなくリスト項目・引用・
                // テーブルまで打ち切ってしまう（`- item $$a$$ more` でリストが壊れた）。
                // ブロックへの切り出しは、構造が分かっている復元側で行う。
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

    /// 段落をディスプレイ数式の位置で分割し、数式を独立したブロックとして切り出す。
    ///
    /// 切り出しは AST 上で行う。抽出時に空行を挿す方式だと、その段落を包んでいる
    /// リスト項目や引用ごと打ち切ってしまい、構造が壊れる。ここでは段落の内側だけを
    /// 分けるので、リスト項目の中の数式はその項目の中に残る。
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

    /// テキストランをディスプレイ数式トークンの位置で切り分ける。
    /// インライン数式のトークンはそのまま残し、``restoreInlines`` に任せる。
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
}
