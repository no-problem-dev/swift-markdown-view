import Foundation

/// ソース側ハイライト用の軽量シングルパス Markdown トークナイザ。
///
/// CommonMark パーサでは意図的になく、レンダリング構造の解析は `SwiftMarkdownView` のパーサの役割。
/// このスキャナはソースエディタが着色する構文マーカー（`#`・`*`・コードスパン・フェンス・リスト箇条書き・リンクなど）の
/// 位置を特定するだけでよい（Phase 1 の実用的アプローチ）。
///
/// ソースの UTF-16 コードユニット上で動作する。Markdown のデリミタはすべて ASCII（1 コードユニット）のため、
/// 出力範囲は `NSAttributedString` に直接マッピングできる正確な UTF-16 オフセット。
/// 非 ASCII コンテンツ（絵文字・CJK）は不透明なテキストとして扱う。
public enum MarkdownTokenizer {

    // ASCII code units we test against.
    private enum C {
        static let newline: UInt16 = 0x0A
        static let carriageReturn: UInt16 = 0x0D
        static let space: UInt16 = 0x20
        static let tab: UInt16 = 0x09
        static let hash: UInt16 = 0x23      // #
        static let backtick: UInt16 = 0x60  // `
        static let tilde: UInt16 = 0x7E     // ~
        static let star: UInt16 = 0x2A      // *
        static let underscore: UInt16 = 0x5F // _
        static let gt: UInt16 = 0x3E        // >
        static let dash: UInt16 = 0x2D      // -
        static let plus: UInt16 = 0x2B      // +
        static let bang: UInt16 = 0x21      // !
        static let lbracket: UInt16 = 0x5B  // [
        static let rbracket: UInt16 = 0x5D  // ]
        static let lparen: UInt16 = 0x28    // (
        static let rparen: UInt16 = 0x29    // )
        static let dot: UInt16 = 0x2E       // .
        static let backslash: UInt16 = 0x5C // \
        static let zero: UInt16 = 0x30
        static let nine: UInt16 = 0x39
    }

    /// フェンスコードが占める範囲を昇順・非重複にまとめる。
    ///
    /// フェンスの開閉を状態として追えるのはトークナイザだけなので、ブロック文脈を必要とする
    /// 層（ライブプレビューのインライン装飾・入力ルール）はここから受け取る。
    /// インラインコードは含めない。
    package static func fencedCodeRanges(_ tokens: [MarkdownToken]) -> [TextSpan] {
        var merged: [TextSpan] = []
        for token in tokens where token.kind == .codeFence || token.kind == .codeBlock {
            // トークンは行末の改行を含まないので、連続する行の間には必ず 1 文字の隙間ができる。
            // 橋渡ししないと、行末にキャレットがあるときフェンスの外と判定される。
            if let last = merged.last, token.range.lowerBound <= last.upperBound + 1 {
                merged[merged.count - 1] = TextSpan(
                    lowerBound: last.lowerBound,
                    upperBound: Swift.max(last.upperBound, token.range.upperBound)
                )
            } else {
                merged.append(token.range)
            }
        }
        return merged
    }

    /// `offset` がフェンスコードの内側にあるか。
    /// 指定オフセットがフェンスコードの内側かどうか。
    ///
    /// 独自の ``InputRule`` を書くときに要る — コードブロックの中では
    /// オートフォーマットを効かせたくないため（同梱の `ListContinuationRule` が実例）。
    /// トークン列そのものを扱う `tokenize` / `fencedCodeRanges` はハイライタ内部の
    /// 都合なのでパッケージ内に閉じている。
    public static func isInsideFencedCode(_ text: String, offset: Int) -> Bool {
        let ranges = fencedCodeRanges(tokenize(text))
        var low = 0
        var high = ranges.count - 1
        while low <= high {
            let mid = (low + high) / 2
            if offset >= ranges[mid].upperBound {
                low = mid + 1
            } else if offset < ranges[mid].lowerBound {
                high = mid - 1
            } else {
                return true
            }
        }
        return false
    }

    private static func isDigit(_ u: UInt16) -> Bool { u >= C.zero && u <= C.nine }

    private static func firstIndex(of unit: UInt16, _ u: [UInt16], _ start: Int, _ end: Int) -> Int? {
        var i = start
        while i < end {
            if u[i] == unit { return i }
            i += 1
        }
        return nil
    }

    private static func isAlphanumeric(_ u: UInt16) -> Bool {
        isDigit(u)
            || (u >= 0x41 && u <= 0x5A) // A-Z
            || (u >= 0x61 && u <= 0x7A) // a-z
            || u > 0x7F                 // treat non-ASCII as "word" to avoid intraword false positives
    }

    /// Markdown ソースを重複しないハイライトトークン列にトークナイズする。
    package static func tokenize(_ source: String) -> [MarkdownToken] {
        let units = Array(source.utf16)
        var tokens: [MarkdownToken] = []
        var fence: (char: UInt16, length: Int)? = nil
        var inIndentedCode = false
        // 文書の先頭は「直前が空行」と同じ扱い。インデントコードは段落を中断できない
        // （CommonMark 4.4）ので、開始できるかどうかは直前行が空かで決まる。
        var previousLineWasBlank = true

        var lineStart = 0
        let n = units.count
        while lineStart <= n {
            var lineEnd = lineStart
            while lineEnd < n && units[lineEnd] != C.newline { lineEnd += 1 }
            // CRLF の \r は行の内容ではない。含めたままスキャンすると、行末まで伸びる
            // トークン（見出し本文・コードブロック等）が 1 コードユニット余計に色づく。
            var contentEnd = lineEnd
            if contentEnd > lineStart && units[contentEnd - 1] == C.carriageReturn {
                contentEnd -= 1
            }
            scanLine(
                units, lineStart, contentEnd,
                fence: &fence,
                inIndentedCode: &inIndentedCode,
                previousLineWasBlank: previousLineWasBlank,
                into: &tokens
            )
            previousLineWasBlank = skipLeadingWhitespace(units, lineStart, contentEnd) == contentEnd
            if lineEnd == n { break }
            lineStart = lineEnd + 1
        }
        return tokens
    }

    /// 行頭のインデント幅。タブは 4 に展開する（CommonMark のタブストップ）。
    private static func indentWidth(_ u: [UInt16], _ start: Int, _ end: Int) -> Int {
        var width = 0
        var i = start
        while i < end, u[i] == C.space || u[i] == C.tab {
            width += u[i] == C.tab ? 4 : 1
            i += 1
        }
        return width
    }

    // MARK: - Line scanning

    private static func scanLine(
        _ u: [UInt16],
        _ start: Int,
        _ end: Int,
        fence: inout (char: UInt16, length: Int)?,
        inIndentedCode: inout Bool,
        previousLineWasBlank: Bool,
        into tokens: inout [MarkdownToken]
    ) {
        guard start < end else { return }

        // Inside a fenced code block: everything is code until the closing fence.
        if let active = fence {
            // 閉じフェンスもインデントを許す。開きフェンス（下の contentStart 経由）と
            // 揃えていないと、リスト項目の中など字下げされた閉じフェンスを認識できず、
            // 以降のドキュメント全体がコードとして着色され続ける。
            let fenceStart = skipLeadingWhitespace(u, start, end)
            if let fenceRun = leadingFenceRun(u, fenceStart, end), fenceRun.char == active.char, fenceRun.length >= active.length, onlyWhitespaceAfter(u, fenceRun.endIndex, end) {
                tokens.append(MarkdownToken(range: TextSpan(lowerBound: start, upperBound: end), kind: .codeFence))
                fence = nil
            } else {
                tokens.append(MarkdownToken(range: TextSpan(lowerBound: start, upperBound: end), kind: .codeBlock))
            }
            return
        }

        let contentStart = skipLeadingWhitespace(u, start, end)
        let indent = indentWidth(u, start, end)
        let isBlank = contentStart == end

        // インデントコードブロック。プレビュー側（swift-markdown）はこれをコードとして描くので、
        // ここで拾わないと同じ行が左では見出し・右ではコードになる。
        // 空行は状態を変えない（CommonMark 4.4）。
        if !isBlank {
            if indent >= 4 {
                if inIndentedCode || previousLineWasBlank {
                    inIndentedCode = true
                    tokens.append(MarkdownToken(range: TextSpan(lowerBound: start, upperBound: end), kind: .codeBlock))
                    return
                }
            } else {
                inIndentedCode = false
            }
        } else if inIndentedCode {
            return
        }

        // Opening code fence.
        // 開きフェンスのインデントは 3 まで（CommonMark 4.5）。上限を設けないと、
        // 段落の継続行にある字下げされた ``` でフェンスが開き、以降の文書全体が
        // コードとして着色され続ける。閉じフェンス側の無制限は意図的なので触らない。
        if indent <= 3, let fenceRun = leadingFenceRun(u, contentStart, end) {
            tokens.append(MarkdownToken(range: TextSpan(lowerBound: start, upperBound: end), kind: .codeFence))
            fence = (fenceRun.char, fenceRun.length)
            return
        }

        // Thematic break (--- *** ___).
        if isThematicBreak(u, contentStart, end) {
            tokens.append(MarkdownToken(range: TextSpan(lowerBound: start, upperBound: end), kind: .thematicBreak))
            return
        }

        // ATX heading.
        if let markerEnd = atxHeading(u, contentStart, end) {
            tokens.append(MarkdownToken(range: TextSpan(lowerBound: contentStart, upperBound: markerEnd), kind: .headingMarker))
            let textStart = skipLeadingWhitespace(u, markerEnd, end)
            if textStart < end {
                tokens.append(MarkdownToken(range: TextSpan(lowerBound: textStart, upperBound: end), kind: .heading))
            }
            return
        }

        var cursor = contentStart

        // Blockquote markers (possibly nested: `> > `).
        if cursor < end && u[cursor] == C.gt {
            var q = cursor
            while q < end && (u[q] == C.gt || u[q] == C.space) { q += 1 }
            tokens.append(MarkdownToken(range: TextSpan(lowerBound: cursor, upperBound: q), kind: .blockquote))
            cursor = q
        }

        // List marker.
        if let markerEnd = listMarker(u, cursor, end) {
            tokens.append(MarkdownToken(range: TextSpan(lowerBound: cursor, upperBound: markerEnd), kind: .listMarker))
            cursor = skipLeadingWhitespace(u, markerEnd, end)
            // Task checkbox immediately after the bullet.
            if let task = taskCheckbox(u, cursor, end) {
                tokens.append(MarkdownToken(range: TextSpan(lowerBound: cursor, upperBound: task), kind: .taskMarker))
                cursor = task
            }
        }

        scanInline(u, cursor, end, into: &tokens)
    }

    // MARK: - Inline scanning

    private static func scanInline(_ u: [UInt16], _ start: Int, _ end: Int, into tokens: inout [MarkdownToken]) {
        var i = start
        while i < end {
            let c = u[i]
            switch c {
            case C.backslash:
                // エスケープされた文字はデリミターにならない（CommonMark 6.1）。
                // 拾うと `\*not em\*` の `*` が強調マーカーとして着色され、
                // プレビュー側がリテラルとして描くのと食い違う。
                i += 2

            case C.backtick:
                if let span = codeSpan(u, i, end) {
                    tokens.append(MarkdownToken(range: TextSpan(lowerBound: i, upperBound: span), kind: .inlineCode))
                    i = span
                } else {
                    // Unmatched: skip the whole backtick run.
                    i = runEnd(u, i, end, of: C.backtick)
                }

            case C.bang, C.lbracket:
                if let link = linkOrImage(u, i, end) {
                    tokens.append(MarkdownToken(range: TextSpan(lowerBound: link.textStart, upperBound: link.textEnd), kind: .linkText))
                    tokens.append(MarkdownToken(range: TextSpan(lowerBound: link.urlStart, upperBound: link.urlEnd), kind: .linkURL))
                    i = link.urlEnd
                } else if let close = firstIndex(of: C.rbracket, u, i, end) {
                    // この `]` は i 以降のどの `[` から見ても「最初の `]`」なので、
                    // その手前から始めても同じ理由で失敗する。1 文字ずつ進めると
                    // 閉じない `[` が多い行で行長に対して二次に膨らむ。
                    i = close + 1
                } else {
                    // 行内に `]` が無い。以降どこから始めてもリンクにはならない。
                    i = end
                }

            case C.star, C.underscore:
                let runEndIndex = runEnd(u, i, end, of: c)
                let length = runEndIndex - i
                if c == C.underscore && isIntraword(u, i, runEndIndex, end) {
                    i = runEndIndex
                    continue
                }
                tokens.append(MarkdownToken(
                    range: TextSpan(lowerBound: i, upperBound: runEndIndex),
                    kind: length >= 2 ? .strong : .emphasis
                ))
                i = runEndIndex

            case C.tilde:
                let runEndIndex = runEnd(u, i, end, of: C.tilde)
                if runEndIndex - i >= 2 {
                    tokens.append(MarkdownToken(range: TextSpan(lowerBound: i, upperBound: runEndIndex), kind: .strikethrough))
                }
                i = runEndIndex

            default:
                i += 1
            }
        }
    }

    // MARK: - Matchers

    private static func skipLeadingWhitespace(_ u: [UInt16], _ start: Int, _ end: Int) -> Int {
        var i = start
        while i < end && (u[i] == C.space || u[i] == C.tab) { i += 1 }
        return i
    }

    private static func onlyWhitespaceAfter(_ u: [UInt16], _ start: Int, _ end: Int) -> Bool {
        skipLeadingWhitespace(u, start, end) == end
    }

    private static func runEnd(_ u: [UInt16], _ start: Int, _ end: Int, of unit: UInt16) -> Int {
        var i = start
        while i < end && u[i] == unit { i += 1 }
        return i
    }

    /// `start` から始まる 3 個以上のバッククォートまたはチルダのラン。
    private static func leadingFenceRun(_ u: [UInt16], _ start: Int, _ end: Int) -> (char: UInt16, length: Int, endIndex: Int)? {
        guard start < end, u[start] == C.backtick || u[start] == C.tilde else { return nil }
        let c = u[start]
        let e = runEnd(u, start, end, of: c)
        let len = e - start
        return len >= 3 ? (c, len, e) : nil
    }

    private static func isThematicBreak(_ u: [UInt16], _ start: Int, _ end: Int) -> Bool {
        guard start < end else { return false }
        let c = u[start]
        guard c == C.dash || c == C.star || c == C.underscore else { return false }
        var count = 0
        var i = start
        while i < end {
            let ch = u[i]
            if ch == c { count += 1 }
            else if ch == C.space || ch == C.tab { /* allowed */ }
            else { return false }
            i += 1
        }
        return count >= 3
    }

    /// ATX 見出しの `#` マーカーランの終端インデックスを返す。該当しない場合は `nil`。
    private static func atxHeading(_ u: [UInt16], _ start: Int, _ end: Int) -> Int? {
        guard start < end, u[start] == C.hash else { return nil }
        let e = runEnd(u, start, end, of: C.hash)
        let len = e - start
        guard len >= 1 && len <= 6 else { return nil }
        // Must be followed by a space or end of line.
        guard e == end || u[e] == C.space || u[e] == C.tab else { return nil }
        return e
    }

    /// リストマーカー（`.`/`)`/箇条書き文字の直後）の終端インデックスを返す。該当しない場合は `nil`。
    private static func listMarker(_ u: [UInt16], _ start: Int, _ end: Int) -> Int? {
        guard start < end else { return nil }
        let c = u[start]
        // Bullet list: - + * followed by a space.
        if c == C.dash || c == C.plus || c == C.star {
            let next = start + 1
            if next <= end && (next == end || u[next] == C.space) {
                return next
            }
            return nil
        }
        // Ordered list: digits then . or ) then space.
        if isDigit(c) {
            var i = start
            while i < end && isDigit(u[i]) { i += 1 }
            guard i < end, u[i] == C.dot || u[i] == C.rparen else { return nil }
            let markerEnd = i + 1
            guard markerEnd == end || u[markerEnd] == C.space else { return nil }
            return markerEnd
        }
        return nil
    }

    private static func taskCheckbox(_ u: [UInt16], _ start: Int, _ end: Int) -> Int? {
        // [ ] or [x] / [X]
        guard start + 3 <= end else { return nil }
        guard u[start] == C.lbracket, u[start + 2] == C.rbracket else { return nil }
        let mid = u[start + 1]
        guard mid == C.space || mid == 0x78 || mid == 0x58 else { return nil } // ' ', x, X
        return start + 3
    }

    /// `start` から始まるバッククォートコードスパンにマッチする。終端インデックスを返す。
    private static func codeSpan(_ u: [UInt16], _ start: Int, _ end: Int) -> Int? {
        let openEnd = runEnd(u, start, end, of: C.backtick)
        let fenceLen = openEnd - start
        var i = openEnd
        while i < end {
            if u[i] == C.backtick {
                let closeEnd = runEnd(u, i, end, of: C.backtick)
                if closeEnd - i == fenceLen {
                    return closeEnd
                }
                i = closeEnd
            } else {
                i += 1
            }
        }
        return nil
    }

    private struct LinkMatch {
        var textStart: Int
        var textEnd: Int
        var urlStart: Int
        var urlEnd: Int
    }

    /// `start` から始まる `[text](url)` または `![alt](url)` にマッチする。
    private static func linkOrImage(_ u: [UInt16], _ start: Int, _ end: Int) -> LinkMatch? {
        var i = start
        let textStart = i
        if u[i] == C.bang { i += 1 }
        guard i < end, u[i] == C.lbracket else { return nil }
        // Find matching ] (no nesting).
        var j = i + 1
        while j < end && u[j] != C.rbracket { j += 1 }
        guard j < end else { return nil }
        let textEnd = j + 1            // include ]
        // Must be immediately followed by (.
        guard textEnd < end, u[textEnd] == C.lparen else { return nil }
        var k = textEnd + 1
        while k < end && u[k] != C.rparen { k += 1 }
        guard k < end else { return nil }
        let urlEnd = k + 1             // include )
        return LinkMatch(textStart: textStart, textEnd: textEnd, urlStart: textEnd, urlEnd: urlEnd)
    }

    /// `_` ランの両側に単語文字があるかどうか（`snake_case` のように emphasis とみなさない場合）。
    private static func isIntraword(_ u: [UInt16], _ runStart: Int, _ runEnd: Int, _ end: Int) -> Bool {
        let before = runStart - 1
        let after = runEnd
        let hasWordBefore = before >= 0 && isAlphanumeric(u[before])
        let hasWordAfter = after < end && isAlphanumeric(u[after])
        return hasWordBefore && hasWordAfter
    }
}
