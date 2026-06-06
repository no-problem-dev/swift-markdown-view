import Foundation

/// Scans raw Markdown source for math delimiters.
///
/// Recognizes the delimiter styles emitted by major LLMs:
/// - `$$...$$` and `\[...\]` — display math (multiline allowed)
/// - `\(...\)` — inline math
/// - `$...$` — inline math, guarded by Pandoc rules to avoid
///   currency false positives
///
/// Markdown code constructs (fenced code blocks and inline code spans)
/// are skipped. The delimiter specification is shared with LaTeXCore's
/// `MathSegmenter` (swift-latex-view); this minimal port keeps the core
/// module dependency-free.
enum MathScanner {

    enum Part: Equatable {
        /// Source text, preserved exactly.
        case text(String)
        /// A math region with delimiters stripped.
        case math(latex: String, isDisplay: Bool)
    }

    static func parts(in source: String) -> [Part] {
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

    mutating func run() -> [MathScanner.Part] {
        while i < chars.count {
            switch chars[i] {
            case "\\": scanBackslash()
            case "`": scanBacktick()
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
            skipFencedBlock(minimumLength: runLength)
        } else {
            skipCodeSpan(length: runLength)
        }
    }

    private mutating func skipFencedBlock(minimumLength: Int) {
        while i < chars.count {
            guard let lineStart = indexAfterNextNewline() else {
                i = chars.count
                return
            }
            var j = lineStart
            while j < chars.count && (chars[j] == " " || chars[j] == "\t") { j += 1 }
            var closeLength = 0
            while j < chars.count && chars[j] == "`" {
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
