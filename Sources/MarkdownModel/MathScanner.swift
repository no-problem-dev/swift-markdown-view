import Foundation

/// Scans raw Markdown source for math delimiters.
///
/// It recognises the delimiter styles the major LLMs emit:
/// - `$$...$$` and `\[...\]` — display math, which may span lines
/// - `\(...\)` — inline math
/// - `$...$` — inline math, under the Pandoc rule that keeps currency from matching
///
/// Code is passed straight through and never read as math. All four of CommonMark's code
/// constructs are handled: backtick fences (```` ``` ````), tilde fences (`~~~`), indented code
/// blocks of four spaces or more, and inline code spans (`` ` ``).
///
/// Missing any one of them would replace the contents of a code block with math and show
/// something other than what the author wrote, which is why recognising all four belongs here.
/// The delimiter rules match `MathSegmenter` in swift-latex-view; they are restated here so this
/// module needs no dependency on that package.
package enum MathScanner {

    public enum Part: Equatable, Sendable {
        /// Source text, kept exactly as it was.
        case text(String)
        /// A math region with its delimiters removed.
        ///
        /// `raw` is the original source fragment, delimiters included. The scan has no syntax
        /// tree, so it picks up positions that cannot hold math in document terms, such as a
        /// link destination. At those positions the caller has to write `raw` back rather than
        /// `latex`, since `latex` alone cannot tell `$x$` from `\(x\)` and the URL would come
        /// out different.
        case math(latex: String, isDisplay: Bool, raw: String)
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
    /// Whether an indented code block is still open.
    ///
    /// A blank line does not close one (CommonMark 4.4), so a line-by-line scan has to carry
    /// this as state.
    var inIndentedCode = false
    /// Closers of `\]` / `\)` already searched for and found to occur nowhere in the source.
    var exhaustedBackslashClosers: Set<Character> = []

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
        parts.append(.math(latex: latex, isDisplay: isDisplay, raw: String(chars[start..<end])))
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
        // Don't rescan for a closer already known to be absent. The loop below always runs to
        // the end of the source, so a closer that failed once cannot be found from any later
        // start either. Without remembering that, a run of `\(` makes the scan O(n^2).
        guard !exhaustedBackslashClosers.contains(closer) else {
            i += 2
            return
        }

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
        exhaustedBackslashClosers.insert(closer)
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
            // Display math may span lines but not block boundaries. Without stopping here,
            // `He paid $$ for it.` would swallow a code block that follows it whole as math.
            // (The inline form stops at `\n` and at `` ` ``.)
            if chars[j] == "\n", isBlockBoundary(afterNewlineAt: j) {
                break
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
        // Closing a bracket the math never opened is evidence of crossing Markdown structure,
        // so stop there. This scanner runs over raw source before parsing, so a structural
        // character like the `)` in `[a](url$x)` can end up inside the math. Swallowing it
        // dissolves the whole link into a placeholder, and restore cannot rebuild the structure.
        // (Pandoc consumes the link first, so it never hits this.) Balanced brackets such as
        // `$f(x)$` are legitimate math, so depth is what tells the two apart.
        var parenDepth = 0
        var bracketDepth = 0
        while j < chars.count {
            let c = chars[j]
            if c == "\n" { break }
            // Don't look past the start of a code span for a closing delimiter. In a sentence
            // like `The fee is $5, see ` + "`$HOME`", the `$` inside the code span would be
            // mistaken for the closer and the span swallowed as math.
            if c == "`" { break }
            if c == "\\" {
                j += 2
                continue
            }
            if c == "(" {
                parenDepth += 1
            } else if c == "[" {
                bracketDepth += 1
            } else if c == ")" {
                if parenDepth == 0 { break }
                parenDepth -= 1
            } else if c == "]" {
                if bracketDepth == 0 { break }
                bracketDepth -= 1
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

    /// Whether the line after the given newline is a block boundary that ends display math.
    ///
    /// A blank line ends the paragraph and a fence line opens a code block. Neither can sit
    /// inside math, so the search for a closing delimiter stops there.
    private func isBlockBoundary(afterNewlineAt newline: Int) -> Bool {
        var k = newline + 1
        var indent = 0
        while k < chars.count, chars[k] == " " || chars[k] == "\t" {
            indent += chars[k] == "\t" ? 4 : 1
            k += 1
        }
        // Blank line (another newline, or the end of the document).
        if k >= chars.count || chars[k] == "\n" { return true }
        // Start of an indented code block.
        if indent >= 4 { return true }
        // Start of a fence (``` or ~~~).
        guard chars[k] == "`" || chars[k] == "~" else { return false }
        let fence = chars[k]
        var run = 0
        while k < chars.count, chars[k] == fence {
            run += 1
            k += 1
        }
        return run >= 3
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

    /// Skips a tilde fence (`~~~`).
    ///
    /// Unlike backticks, tildes have no code span form: a run shorter than three is
    /// strikethrough (`~~text~~`), so anything that is not a fence is passed through.
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

    // MARK: Indented code blocks (four spaces or more, CommonMark 4.4)

    /// Whether the index sits exactly at a line start: right after a newline, or at index 0.
    ///
    /// The strict counterpart to `isAtLineStart(_:)`, which allows leading whitespace. It runs
    /// at the top of the scan loop, where the line check has to fire exactly once per line.
    private func isAtLineStart(exactly index: Int) -> Bool {
        index == 0 || chars[index - 1] == "\n"
    }

    /// Updates whether an indented code block is open, called at the start of a line.
    ///
    /// Two CommonMark rules are honoured here:
    /// - A blank line does not end indented code; blank lines in the middle still leave one block
    /// - Indented code cannot interrupt a paragraph, so after a paragraph line, four spaces or
    ///   more is a continuation of that paragraph rather than code
    private mutating func updateIndentedCodeState(at index: Int) {
        if lineIsBlank(at: index) { return }
        guard indentWidth(at: index) >= 4 else {
            inIndentedCode = false
            return
        }
        if inIndentedCode { return }
        inIndentedCode = previousLineIsBlankOrAbsent(before: index)
    }

    /// Measures the indent at the start of a line, counting a tab as four columns.
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
        // Walk back to the start of the previous line.
        start -= 1
        while start >= 0 && chars[start] != "\n" { start -= 1 }
        return lineIsBlank(at: start + 1)
    }

    /// Skips to just past the newline that ends the current line.
    ///
    /// `textStart` is left where it was, so the skipped text is still emitted as source text.
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
