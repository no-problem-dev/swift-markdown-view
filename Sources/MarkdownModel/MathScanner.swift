import Foundation

/// 生の Markdown ソースから数式デリミターをスキャンする。
///
/// 主要な LLM が出力するデリミタースタイルを認識する:
/// - `$$...$$` と `\[...\]` — ディスプレイ数式（複数行対応）
/// - `\(...\)` — インライン数式
/// - `$...$` — インライン数式。通貨の誤検知を防ぐ Pandoc ルールを適用
///
/// コード領域は数式として解釈せず、そのまま素通しする。対象は CommonMark のコード構文 4 種:
/// バッククォートフェンス（```` ``` ````）・チルダフェンス（`~~~`）・4 スペース以上の
/// インデントコードブロック・インラインコードスパン（`` ` ``）。
///
/// ここを取りこぼすとコードブロックの中身が数式に置換されて表示が原文と食い違うため、
/// 4 種すべてを認識する責務がこのスキャナにある。デリミター仕様は LaTeXCore の
/// `MathSegmenter`（swift-latex-view）と共通であり、このポートでコアモジュールの依存をゼロに保つ。
public enum MathScanner {

    public enum Part: Equatable, Sendable {
        /// ソーステキスト。そのまま保持する。
        case text(String)
        /// デリミターを除去した数式領域。
        case math(latex: String, isDisplay: Bool)
    }

    public static func parts(in source: String) -> [Part] {
        var scanner = Scanner(chars: Array(source))
        return scanner.run()
    }
}

// MARK: - Scanner

private struct Scanner {
    let chars: [Character]
    var i = 0
    var textStart = 0
    var parts: [MathScanner.Part] = []
    /// インデントコードブロックの継続中か。空行では解除されない（CommonMark 4.4）ため、
    /// 行単位のスキャンでは状態として持つ必要がある。
    var inIndentedCode = false

    mutating func run() -> [MathScanner.Part] {
        while i < chars.count {
            if isAtLineStart(exactly: i) {
                updateIndentedCodeState(at: i)
                if inIndentedCode {
                    skipLine()
                    continue
                }
            }
            switch chars[i] {
            case "\\": scanBackslash()
            case "`": scanBacktick()
            case "~": scanTilde()
            case "$": scanDollar()
            default: i += 1
            }
        }
        flushText(upTo: chars.count)
        return parts
    }

    // MARK: Emission

    private mutating func flushText(upTo end: Int) {
        guard end > textStart else { return }
        parts.append(.text(String(chars[textStart..<end])))
        textStart = end
    }

    private mutating func emitMath(_ latex: String, isDisplay: Bool, from start: Int, to end: Int) {
        flushText(upTo: start)
        parts.append(.math(latex: latex, isDisplay: isDisplay))
        textStart = end
        i = end
    }

    // MARK: Backslash: \[...\], \(...\), and escapes

    private mutating func scanBackslash() {
        guard i + 1 < chars.count else {
            i += 1
            return
        }
        switch chars[i + 1] {
        case "[":
            matchBackslashDelimited(closer: "]", isDisplay: true)
        case "(":
            matchBackslashDelimited(closer: ")", isDisplay: false)
        default:
            i += 2
        }
    }

    private mutating func matchBackslashDelimited(closer: Character, isDisplay: Bool) {
        let start = i
        let contentStart = i + 2
        var j = contentStart
        while j + 1 < chars.count {
            if chars[j] == "\\" {
                if chars[j + 1] == closer {
                    let latex = trimmed(contentStart..<j)
                    if latex.isEmpty {
                        i = j + 2
                    } else {
                        emitMath(latex, isDisplay: isDisplay, from: start, to: j + 2)
                    }
                    return
                }
                j += 2
            } else {
                j += 1
            }
        }
        i = start + 2
    }

    // MARK: Dollar: $$...$$ and $...$

    private mutating func scanDollar() {
        if i + 1 < chars.count && chars[i + 1] == "$" {
            matchDoubleDollar()
        } else {
            matchSingleDollar()
        }
    }

    private mutating func matchDoubleDollar() {
        let start = i
        let contentStart = i + 2
        var j = contentStart
        while j + 1 < chars.count {
            if chars[j] == "\\" {
                j += 2
                continue
            }
            if chars[j] == "$" && chars[j + 1] == "$" {
                let latex = trimmed(contentStart..<j)
                if latex.isEmpty {
                    i = j + 2
                } else {
                    emitMath(latex, isDisplay: true, from: start, to: j + 2)
                }
                return
            }
            j += 1
        }
        i = start + 2
    }

    private mutating func matchSingleDollar() {
        let start = i
        let contentStart = i + 1
        guard contentStart < chars.count, !chars[contentStart].isWhitespace else {
            i += 1
            return
        }
        var j = contentStart
        while j < chars.count {
            let c = chars[j]
            if c == "\n" { break }
            // コードスパンの開始を跨いで閉じデリミターを探さない。跨ぐと
            // `The fee is $5, see ` + "`$HOME`" のような文で、コードスパン内の `$` を
            // 閉じデリミターと誤認してコードスパンごと数式に飲み込んでしまう。
            if c == "`" { break }
            if c == "\\" {
                j += 2
                continue
            }
            if c == "$" {
                // Pandoc rule: content may not contain an unescaped `$`,
                // so the first one found either closes the math or fails it.
                let validClose = !chars[j - 1].isWhitespace && !isDigit(at: j + 1)
                if validClose && j > contentStart {
                    emitMath(String(chars[contentStart..<j]), isDisplay: false, from: start, to: j + 1)
                    return
                }
                break
            }
            j += 1
        }
        i = start + 1
    }

    // MARK: Code constructs (skipped verbatim)

    private mutating func scanBacktick() {
        let runStart = i
        var runLength = 0
        while i < chars.count && chars[i] == "`" {
            runLength += 1
            i += 1
        }
        if runLength >= 3 && isAtLineStart(runStart) {
            skipFencedBlock(fence: "`", minimumLength: runLength)
        } else {
            skipCodeSpan(length: runLength)
        }
    }

    /// チルダフェンス（`~~~`）を読み飛ばす。バッククォートと違いチルダにコードスパンは無く、
    /// 3 本未満の連続は打ち消し線（`~~text~~`）なので、フェンスに該当しない場合は素通しする。
    private mutating func scanTilde() {
        let runStart = i
        var runLength = 0
        while i < chars.count && chars[i] == "~" {
            runLength += 1
            i += 1
        }
        if runLength >= 3 && isAtLineStart(runStart) {
            skipFencedBlock(fence: "~", minimumLength: runLength)
        }
    }

    private mutating func skipFencedBlock(fence: Character, minimumLength: Int) {
        while i < chars.count {
            guard let lineStart = indexAfterNextNewline() else {
                i = chars.count
                return
            }
            var j = lineStart
            while j < chars.count && (chars[j] == " " || chars[j] == "\t") { j += 1 }
            var closeLength = 0
            while j < chars.count && chars[j] == fence {
                closeLength += 1
                j += 1
            }
            i = j
            if closeLength >= minimumLength {
                return
            }
        }
    }

    private mutating func skipCodeSpan(length: Int) {
        var j = i
        while j < chars.count {
            if chars[j] == "`" {
                var closeLength = 0
                while j < chars.count && chars[j] == "`" {
                    closeLength += 1
                    j += 1
                }
                if closeLength == length {
                    i = j
                    return
                }
            } else {
                j += 1
            }
        }
    }

    // MARK: Helpers

    private func trimmed(_ range: Range<Int>) -> String {
        let upper = min(range.upperBound, chars.count)
        guard range.lowerBound < upper else { return "" }
        return String(chars[range.lowerBound..<upper])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isDigit(at index: Int) -> Bool {
        guard index < chars.count else { return false }
        return ("0"..."9").contains(chars[index])
    }

    // MARK: Indented code blocks（4 スペース以上・CommonMark 4.4）

    /// 行頭ちょうどか（直前が改行、または文書先頭）。`isAtLineStart(_:)` が
    /// 先行する空白を許すのに対し、こちらは行の判定を 1 度だけ行うための厳密版。
    private func isAtLineStart(exactly index: Int) -> Bool {
        index == 0 || chars[index - 1] == "\n"
    }

    /// 行頭で、インデントコードブロックの継続状態を更新する。
    ///
    /// CommonMark の規則を 2 点反映している:
    /// - 空行はインデントコードを終了させない（間に空行を挟んでも 1 つのコードブロック）
    /// - インデントコードは段落を中断できない。直前が段落なら、4 スペース以上でも
    ///   段落の継続行であってコードではない
    private mutating func updateIndentedCodeState(at index: Int) {
        if lineIsBlank(at: index) { return }
        guard indentWidth(at: index) >= 4 else {
            inIndentedCode = false
            return
        }
        if inIndentedCode { return }
        inIndentedCode = previousLineIsBlankOrAbsent(before: index)
    }

    /// タブ幅 4 として行頭のインデント幅を測る。
    private func indentWidth(at index: Int) -> Int {
        var width = 0
        var j = index
        while j < chars.count {
            switch chars[j] {
            case " ": width += 1
            case "\t": width += 4
            default: return width
            }
            j += 1
        }
        return width
    }

    private func lineIsBlank(at index: Int) -> Bool {
        var j = index
        while j < chars.count && chars[j] != "\n" {
            if !chars[j].isWhitespace { return false }
            j += 1
        }
        return true
    }

    private func previousLineIsBlankOrAbsent(before index: Int) -> Bool {
        guard index > 0 else { return true }
        var start = index - 1
        guard chars[start] == "\n" else { return true }
        // 直前の行の開始位置まで戻る。
        start -= 1
        while start >= 0 && chars[start] != "\n" { start -= 1 }
        return lineIsBlank(at: start + 1)
    }

    /// 現在行を改行の直後まで読み飛ばす。`textStart` は動かさないので本文は保全される。
    private mutating func skipLine() {
        while i < chars.count && chars[i] != "\n" { i += 1 }
        if i < chars.count { i += 1 }
    }

    private func isAtLineStart(_ index: Int) -> Bool {
        var j = index - 1
        while j >= 0 {
            switch chars[j] {
            case " ", "\t": j -= 1
            case "\n": return true
            default: return false
            }
        }
        return true
    }

    private mutating func indexAfterNextNewline() -> Int? {
        while i < chars.count {
            if chars[i] == "\n" {
                i += 1
                return i
            }
            i += 1
        }
        return nil
    }
}
