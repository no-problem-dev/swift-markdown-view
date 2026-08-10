import Foundation

/// Pairs up inline Markdown delimiters into the spans live preview needs.
///
/// Produces an ``InlineSpan`` per match. Covers code spans (`` ` ``), strong (`**`, `__`), emphasis (`*`, `_`) and strikethrough (`~~`).
/// Matching is scoped to a single line, because CommonMark emphasis never spans a newline, and two
/// runs only pair when their lengths agree: `**a**` matches, `**a*` does not. Open runs are kept on
/// one stack and matched by delimiter character *and* run length, which resolves simple nesting such
/// as `**a *b* c**`; when a run closes, any inner opens still waiting are discarded. Code spans win,
/// and their interiors are excluded from the emphasis scan.
///
/// A full CommonMark emphasis resolver — flanking rules, mixed-width runs like `***` — is
/// deliberately out of scope. This is the practical subset that covers the dominant cases, and the
/// conceal/reveal machinery does not depend on how precise the matcher is, so the matcher can be
/// strengthened later without touching the rendering path.
package enum InlineSpanParser {

    private enum C {
        static let newline: UInt16 = 0x0A
        static let backtick: UInt16 = 0x60
        static let star: UInt16 = 0x2A
        static let underscore: UInt16 = 0x5F
        static let tilde: UInt16 = 0x7E
        static let backslash: UInt16 = 0x5C
    }

    package static func parse(_ text: String) -> [InlineSpan] {
        let u = Array(text.utf16)
        var spans: [InlineSpan] = []
        let n = u.count

        var lineStart = 0
        while lineStart <= n {
            var lineEnd = lineStart
            while lineEnd < n && u[lineEnd] != C.newline { lineEnd += 1 }
            parseLine(u, lineStart, lineEnd, into: &spans)
            if lineEnd == n { break }
            lineStart = lineEnd + 1
        }
        return spans.sorted { $0.fullRange.lowerBound < $1.fullRange.lowerBound }
    }

    // MARK: - Per line

    private static func parseLine(_ u: [UInt16], _ start: Int, _ end: Int, into spans: inout [InlineSpan]) {
        guard start < end else { return }

        // Pass A: code spans (take precedence; record covered ranges).
        var codeRanges: [Range<Int>] = []
        var i = start
        while i < end {
            // Backslash escape: `\`` does not open a code span (CommonMark 6.1).
            if u[i] == C.backslash {
                i += 2
                continue
            }
            if u[i] == C.backtick {
                let openEnd = runEnd(u, i, end, of: C.backtick)
                let len = openEnd - i
                if let closeStart = findBacktickRun(u, from: openEnd, end: end, length: len) {
                    let closeEnd = closeStart + len
                    spans.append(InlineSpan(
                        kind: .code,
                        fullRange: TextSpan(lowerBound: i, upperBound: closeEnd),
                        contentRange: TextSpan(lowerBound: openEnd, upperBound: closeStart),
                        markerRanges: [
                            TextSpan(lowerBound: i, upperBound: openEnd),
                            TextSpan(lowerBound: closeStart, upperBound: closeEnd),
                        ]
                    ))
                    codeRanges.append(i..<closeEnd)
                    i = closeEnd
                    continue
                }
                i = openEnd
            } else {
                i += 1
            }
        }

        // Pass B: emphasis / strong / strikethrough outside code spans.
        struct OpenRun { let char: UInt16; let length: Int; let start: Int }
        var stack: [OpenRun] = []

        i = start
        while i < end {
            let c = u[i]
            // An escaped delimiter is just the character. Emphasising `\*not em\*` would disagree
            // with the preview side (swift-markdown), which draws it literally.
            // Inside a code span a backslash escapes nothing (CommonMark 6.1).
            if c == C.backslash, !inAnyRange(i, codeRanges) {
                i += 2
                continue
            }
            guard c == C.star || c == C.underscore || c == C.tilde, !inAnyRange(i, codeRanges) else {
                i += 1
                continue
            }
            let rEnd = runEnd(u, i, end, of: c)
            let length = rEnd - i

            // Intraword underscores are literal (snake_case).
            if c == C.underscore && isIntraword(u, i, rEnd, end) {
                i = rEnd
                continue
            }
            guard let kind = kindFor(char: c, length: length) else {
                i = rEnd
                continue
            }

            if let openIndex = stack.lastIndex(where: { $0.char == c && $0.length == length }) {
                let open = stack[openIndex]
                stack.removeSubrange(openIndex...)  // discard any unmatched inner opens
                let contentLower = open.start + open.length
                let contentUpper = i
                if contentUpper > contentLower {
                    spans.append(InlineSpan(
                        kind: kind,
                        fullRange: TextSpan(lowerBound: open.start, upperBound: rEnd),
                        contentRange: TextSpan(lowerBound: contentLower, upperBound: contentUpper),
                        markerRanges: [
                            TextSpan(lowerBound: open.start, upperBound: contentLower),
                            TextSpan(lowerBound: i, upperBound: rEnd),
                        ]
                    ))
                }
            } else {
                stack.append(OpenRun(char: c, length: length, start: i))
            }
            i = rEnd
        }
    }

    // MARK: - Helpers

    private static func kindFor(char: UInt16, length: Int) -> InlineSpan.Kind? {
        switch char {
        case C.tilde:
            return length >= 2 ? .strikethrough : nil
        case C.star, C.underscore:
            return length >= 2 ? .strong : .emphasis
        default:
            return nil
        }
    }

    private static func runEnd(_ u: [UInt16], _ start: Int, _ end: Int, of unit: UInt16) -> Int {
        var i = start
        while i < end && u[i] == unit { i += 1 }
        return i
    }

    private static func findBacktickRun(_ u: [UInt16], from: Int, end: Int, length: Int) -> Int? {
        var i = from
        while i < end {
            if u[i] == C.backtick {
                let e = runEnd(u, i, end, of: C.backtick)
                if e - i == length { return i }
                i = e
            } else {
                i += 1
            }
        }
        return nil
    }

    private static func inAnyRange(_ index: Int, _ ranges: [Range<Int>]) -> Bool {
        for r in ranges where r.contains(index) { return true }
        return false
    }

    private static func isAlphanumeric(_ unit: UInt16) -> Bool {
        (unit >= 0x30 && unit <= 0x39)
            || (unit >= 0x41 && unit <= 0x5A)
            || (unit >= 0x61 && unit <= 0x7A)
            || unit > 0x7F
    }

    private static func isIntraword(_ u: [UInt16], _ runStart: Int, _ runEnd: Int, _ end: Int) -> Bool {
        let before = runStart - 1
        let after = runEnd
        let hasWordBefore = before >= 0 && isAlphanumeric(u[before])
        let hasWordAfter = after < end && isAlphanumeric(u[after])
        return hasWordBefore && hasWordAfter
    }
}
